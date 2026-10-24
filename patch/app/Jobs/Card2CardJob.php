<?php
namespace App\Jobs;

use App\Http\Models\Queue;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Card-to-card payments: the part that runs every minute (bin/c2c.php).
 *
 * The customer's half (app/Patch/Card2Card.php) records a transfer and answers
 * at once; this job does everything that must not hold that request open:
 *
 *   1. keeps a pending order from being cancelled by the panel's own two-minute
 *      job (`gateway_expire` is moved ahead while the transfer waits),
 *   2. sends the administrator the Telegram message with the two approve/reject
 *      buttons - immediately if it fitted in the request, otherwise here,
 *   3. tells the customer the outcome on Telegram, by e-mail and with a notice
 *      in the panel (c2c_notice, read by user/layout/c2cbanner.tpl),
 *   4. removes the buttons from a decided Telegram message,
 *   5. rejects requests nobody looked at after `c2c_reject_hours`.
 *
 * Every send is recorded on the request row before it goes out, so a failure
 * can never send the same message twice.
 */
class Card2CardJob
{
	/** rows handled per run - the job runs every minute */
	const BATCH = 25;

	const GB = 1073741824;

	/** one process only has to make the tables once */
	private static $ready = false;

	private $settings = [];

	// ------------------------------------------------------------- lifecycle

	public function dispatch()
	{
		$this->ensureTables();

		$held = $this->holdOpen();
		$callbacks = $this->pollBot();
		$admins = $this->notifyAdmins();
		$users = $this->notifyUsers();
		$closed = $this->closeButtons();
		$expired = $this->expireStale();

		return [
			'held'    => $held,
			'callbacks' => $callbacks,
			'admins'  => $admins,
			'users'   => $users,
			'closed'  => $closed,
			'expired' => $expired,
			'left'    => (int) DB::table('c2c_request')->where('status', 0)->count(),
		];
	}

	private function setting($name)
	{
		if (!array_key_exists($name, $this->settings)) {
			$this->settings[$name] = DB::table('settings')->where('name', $name)->value('value');
		}

		return $this->settings[$name];
	}

	private function putSetting($name, $value)
	{
		$this->settings[$name] = $value;

		$exists = DB::table('settings')->where('name', $name)->exists();
		if ($exists) {
			DB::table('settings')->where('name', $name)->update(['value' => $value]);
		} else {
			DB::table('settings')->insert(['name' => $name, 'value' => $value]);
		}
	}

	private function hours($name, $fallback)
	{
		$value = $this->setting($name);

		if ($value === null || $value === '') {
			return $fallback;
		}

		$hours = (int) $value;

		return $hours < 0 ? 0 : min($hours, 8760);
	}

	/**
	 * The migration creates these; the fallback keeps an install that missed it
	 * working instead of failing once a minute.
	 */
	private function ensureTables()
	{
		if (self::$ready) {
			return;
		}

		DB::statement(
			"CREATE TABLE IF NOT EXISTS `c2c_card` (
			  `id` int(11) NOT NULL AUTO_INCREMENT,
			  `number` varchar(32) NOT NULL DEFAULT '',
			  `holder` varchar(120) NOT NULL DEFAULT '',
			  `bank` varchar(120) NOT NULL DEFAULT '',
			  `limit_amount` bigint(20) NOT NULL DEFAULT 0,
			  `limit_count` int(11) NOT NULL DEFAULT 0,
			  `limit_period` varchar(10) NOT NULL DEFAULT 'day',
			  `enabled` tinyint(1) NOT NULL DEFAULT 1,
			  `sort` int(11) NOT NULL DEFAULT 0,
			  `note` varchar(255) NOT NULL DEFAULT '',
			  `created` bigint(20) NOT NULL DEFAULT 0,
			  `updated` bigint(20) NOT NULL DEFAULT 0,
			  PRIMARY KEY (`id`),
			  KEY `enabled_sort` (`enabled`, `sort`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

		DB::statement(
			"CREATE TABLE IF NOT EXISTS `c2c_request` (
			  `id` bigint(20) NOT NULL AUTO_INCREMENT,
			  `orderid` bigint(20) NOT NULL,
			  `userid` int(11) NOT NULL,
			  `cardid` int(11) NOT NULL DEFAULT 0,
			  `amount` decimal(14,2) NOT NULL DEFAULT '0.00',
			  `plan_name` varchar(190) NOT NULL DEFAULT '',
			  `plan_cycle` varchar(20) NOT NULL DEFAULT '',
			  `plan_days` int(11) NOT NULL DEFAULT 0,
			  `last4` char(4) NOT NULL DEFAULT '',
			  `payer` varchar(120) NOT NULL DEFAULT '',
			  `paid_at` varchar(80) NOT NULL DEFAULT '',
			  `ref` varchar(80) NOT NULL DEFAULT '',
			  `status` tinyint(4) NOT NULL DEFAULT 0,
			  `note` varchar(255) NOT NULL DEFAULT '',
			  `token` char(64) NOT NULL DEFAULT '',
			  `token_expire` bigint(20) NOT NULL DEFAULT 0,
			  `created` bigint(20) NOT NULL DEFAULT 0,
			  `updated` bigint(20) NOT NULL DEFAULT 0,
			  `decided_at` bigint(20) NOT NULL DEFAULT 0,
			  `decided_by` varchar(40) NOT NULL DEFAULT '',
			  `tg_sent` tinyint(1) NOT NULL DEFAULT 0,
			  `tg_chat` varchar(64) NOT NULL DEFAULT '',
			  `tg_message` bigint(20) NOT NULL DEFAULT 0,
			  `tg_closed` tinyint(1) NOT NULL DEFAULT 0,
			  `user_sent` tinyint(1) NOT NULL DEFAULT 0,
			  PRIMARY KEY (`id`),
			  UNIQUE KEY `orderid` (`orderid`),
			  KEY `status_created` (`status`, `created`),
			  KEY `userid` (`userid`),
			  KEY `cardid` (`cardid`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

		DB::statement(
			"CREATE TABLE IF NOT EXISTS `c2c_notice` (
			  `id` bigint(20) NOT NULL AUTO_INCREMENT,
			  `userid` int(11) NOT NULL,
			  `kind` varchar(16) NOT NULL DEFAULT 'approved',
			  `ref` varchar(64) NOT NULL,
			  `orderid` bigint(20) NOT NULL DEFAULT 0,
			  `order_no` varchar(64) NOT NULL DEFAULT '',
			  `name` varchar(190) NOT NULL DEFAULT '',
			  `amount` decimal(14,2) NOT NULL DEFAULT '0.00',
			  `reason` varchar(255) NOT NULL DEFAULT '',
			  `seen` tinyint(1) NOT NULL DEFAULT 0,
			  `created` bigint(20) NOT NULL DEFAULT 0,
			  PRIMARY KEY (`id`),
			  UNIQUE KEY `ref` (`ref`),
			  KEY `user_seen` (`userid`, `seen`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

		self::$ready = true;
	}

	// ------------------------------------------------------------ hold open

	/**
	 * A card transfer is slower than a gateway redirect. The panel's UserJob
	 * cancels unpaid orders after `gateway_expire`, so every waiting request
	 * keeps its order open. A -1 (already timed out) comes back to 0, because
	 * the customer may still be completing the transfer.
	 */
	private function holdOpen()
	{
		$hold = $this->hours('c2c_hold_hours', 48);
		if ($hold < 1) {
			$hold = 48;
		}

		$until = time() + $hold * 3600;

		$affected = DB::update(
			'UPDATE orders o
			   JOIN c2c_request r ON r.orderid = o.id
			    SET o.gateway_expire = ?,
			        o.status = IF(o.status = -1, 0, o.status)
			  WHERE r.status = 0 AND o.status IN (0, -1)',
			[$until]);

		return (int) $affected;
	}

	// ------------------------------------------------------- admin messages

	private function adminChats()
	{
		$raw = trim((string) $this->setting('c2c_telegram_chat'));

		if ($raw === '') {
			$raw = trim((string) $this->setting('telegramchatid'));
		}

		if ($raw === '') {
			return [];
		}

		return array_values(array_filter(preg_split('~[\s,]+~', $raw, -1, PREG_SPLIT_NO_EMPTY) ?: []));
	}

	private function support()
	{
		$value = trim((string) $this->setting('c2c_support'));

		if ($value === '') {
			$value = '@digitsellshop';
		}

		if ($value[0] !== '@' && !preg_match('~^(https?://|t\.me/)~i', $value)) {
			$value = '@' . ltrim($value, '@');
		}

		return $value;
	}

	private function siteUrl()
	{
		$site = trim((string) $this->setting('c2c_site_url'));
		if ($site !== '') {
			return rtrim($site, '/');
		}

		foreach (['appName', 'baseUrl'] as $name) {
			$value = trim((string) $this->setting($name));

			if ($value === '') {
				continue;
			}

			if (preg_match('~^https?://~i', $value)) {
				return rtrim($value, '/');
			}

			if (strpos($value, '.') !== false && !preg_match('~\s~', $value)) {
				return 'https://' . rtrim($value, '/');
			}
		}

		$host = (string) ($_SERVER['HTTP_HOST'] ?? '');

		return $host === '' ? '' : 'https://' . $host;
	}

	private function decideUrl($row, $act)
	{
		return $this->siteUrl() . '/xmplus-patch.php?do=c2c.decide'
			. '&id=' . (int) $row->id
			. '&act=' . urlencode($act)
			. '&t=' . urlencode((string) $row->token);
	}

	private function cardNumber($number)
	{
		$digits = preg_replace('~\D+~', '', (string) $number);

		return $digits === '' ? '' : implode(' ', str_split($digits, 4));
	}

	private function adminText($row, $order, $card)
	{
		$lines = [
			'💳 درخواست تایید کارت به کارت',
			'🧾 سفارش: ' . (string) ($order ? $order->order_id : ('#' . (int) $row->orderid)),
			'👤 کاربر: ' . (string) ($order ? $order->username : '') . ' (#' . (int) $row->userid . ')',
			'📦 بسته: ' . (string) $row->plan_name
				. ((int) $row->plan_days > 0 ? ' · ' . (int) $row->plan_days . ' روز' : ''),
			'💰 مبلغ: ' . number_format(round((float) $row->amount)) . ' ریال',
		];

		if ($card) {
			$lines[] = '🏦 کارت: ' . trim((string) $card->bank . ' · ' . (string) $card->holder)
				. ' · ' . $this->cardNumber($card->number);
		}

		$lines[] = '🔢 چهار رقم آخر: ' . (string) $row->last4;

		if ((string) $row->payer !== '') {
			$lines[] = '✍️ پرداخت‌کننده: ' . (string) $row->payer;
		}

		if ((string) $row->paid_at !== '') {
			$lines[] = '🕒 زمان واریز: ' . (string) $row->paid_at;
		}

		if ((string) $row->ref !== '') {
			$lines[] = '🔖 پیگیری: ' . (string) $row->ref;
		}

		$lines[] = '📥 ثبت در سایت: ' . date('Y-m-d H:i', (int) $row->created);
		$lines[] = '🆔 درخواست: #' . (int) $row->id;
		$lines[] = '';
		$lines[] = 'با دکمه‌های زیر تایید یا رد کنید؛ تایید، بسته را خودکار اعمال می‌کند.';

		return implode("\n", $lines);
	}

	private function notifyAdmins()
	{
		// the dedicated bot carries the callback buttons; without it the panel
		// bot sends URL buttons
		$panelToken = trim((string) $this->setting('telegramtoken'));
		$botToken = trim((string) $this->setting('c2c_bot_token'));
		$token = $botToken !== '' ? $botToken : $panelToken;

		if ($token === '') {
			return 0;
		}

		$useCallbacks = $botToken !== '' && trim((string) $this->setting('c2c_bot_secret')) !== '';

		$chats = $this->adminChats();
		if ($chats === []) {
			return 0;
		}

		$rows = DB::table('c2c_request')
			->where('status', 0)
			->where('tg_sent', 0)
			->orderBy('id')
			->limit(self::BATCH)
			->get();

		$sent = 0;

		foreach ($rows as $row) {
			$order = DB::table('orders')->where('id', (int) $row->orderid)
				->first(['order_id', 'username']);
			$card = DB::table('c2c_card')->where('id', (int) $row->cardid)->first();

			$text = $this->adminText($row, $order, $card);
			$keyboard = null;

			if ($useCallbacks) {
				$keyboard = json_encode([
					'inline_keyboard' => [[
						['text' => '✅ تایید', 'callback_data' => $this->callbackData($row->id, 'approve')],
						['text' => '❌ رد', 'callback_data' => $this->callbackData($row->id, 'reject')],
					]],
				], JSON_UNESCAPED_UNICODE);
			} elseif (preg_match('~^https?://~i', $this->siteUrl())) {
				// URL buttons only work with an absolute address; without one the
				// message still arrives and the panel can approve it
				$keyboard = json_encode([
					'inline_keyboard' => [[
						['text' => '✅ تایید', 'url' => $this->decideUrl($row, 'approve')],
						['text' => '❌ رد', 'url' => $this->decideUrl($row, 'reject')],
					]],
				], JSON_UNESCAPED_UNICODE);
			}

			$firstChat = '';
			$firstMessage = 0;

			foreach ($chats as $chat) {
				$params = [
					'chat_id' => $chat,
					'text'    => $text,
				];

				if ($keyboard !== null) {
					$params['reply_markup'] = $keyboard;
				}

				$answer = $this->api($token, 'sendMessage', $params);

				if (is_array($answer) && !empty($answer['ok'])) {
					if ($firstChat === '') {
						$firstChat = $chat;
						$firstMessage = (int) ($answer['result']['message_id'] ?? 0);
					}
				}
			}

			if ($firstChat === '') {
				continue;
			}

			DB::table('c2c_request')->where('id', (int) $row->id)->update([
				'tg_sent'    => 1,
				'tg_chat'    => $firstChat,
				'tg_message' => $firstMessage,
			]);

			$sent++;
		}

		return $sent;
	}

	// ----------------------------------------------------- customer messages

	private function notifyUsers()
	{
		$token = trim((string) $this->setting('telegramtoken'));

		// "if they are a member": a user with a telegram_id has started the
		// bot, and both the approval and the rejection (with the admin's
		// reason) go there. The panel's own Telegram master switch is not
		// required for these account notices.
		$telegramOn = $token !== '';

		$rows = DB::table('c2c_request')
			->whereIn('status', [1, 2])
			->where('user_sent', 0)
			->orderBy('id')
			->limit(self::BATCH)
			->get();

		$sent = 0;

		foreach ($rows as $row) {
			$order = DB::table('orders')->where('id', (int) $row->orderid)
				->first(['order_id']);
			$user = DB::table('user')->where('id', (int) $row->userid)
				->first(['id', 'username', 'email', 'telegram_id']);

			$orderNo = $order ? (string) $order->order_id : ('#' . (int) $row->orderid);
			$approved = (int) $row->status === 1;

			$support = $this->support();

			if ($approved) {
				$title = '✅ پرداخت کارت به کارت تایید شد';
				$text = "پرداخت کارت به کارت شما برای سفارش {$orderNo} تایید شد.\n"
					. 'مبلغ: ' . number_format(round((float) $row->amount)) . " ریال\n"
					. ((string) $row->plan_name !== '' ? 'بسته: ' . (string) $row->plan_name . "\n" : '')
					. 'بسته به‌صورت خودکار روی حساب شما اعمال شد.'
					. ($support !== '' ? "\n\nپشتیبانی: " . $support : '');
			} else {
				$title = '❌ پرداخت کارت به کارت تایید نشد';
				$text = "پرداخت کارت به کارت شما برای سفارش {$orderNo} تایید نشد.\n"
					. 'مبلغ: ' . number_format(round((float) $row->amount)) . " ریال\n"
					. ((string) $row->note !== '' ? 'دلیل: ' . (string) $row->note . "\n" : '')
					. 'اگر مبلغ را واریز کرده‌اید، با پشتیبانی تماس بگیرید.'
					. ($support !== '' ? "\nپشتیبانی: " . $support : '');
			}

			// the panel notice: the endpoint usually writes it already, this is
			// the safety net for an approval made while the web user could not
			try {
				$stamp = (int) $row->decided_at > 0 ? (int) $row->decided_at : time();

				DB::table('c2c_notice')->insertOrIgnore([
					'userid'   => (int) $row->userid,
					'kind'     => $approved ? 'approved' : 'rejected',
					'ref'      => 'c2c:' . (int) $row->id . ':' . ($approved ? 'a' : 'r') . ':' . $stamp,
					'orderid'  => (int) $row->orderid,
					'order_no' => $orderNo,
					'name'     => (string) $row->plan_name,
					'amount'   => (float) $row->amount,
					'reason'   => $approved ? '' : (string) $row->note,
					'seen'     => 0,
					'created'  => time(),
				]);
			} catch (\Throwable $error) {
			}

			if ($user) {
				if ($telegramOn && (int) $user->telegram_id > 0) {
					$this->api($token, 'sendMessage', [
						'chat_id' => $user->telegram_id,
						'text'    => $title . "\n\n" . $text,
					]);
				}

				$this->mail($user, $approved ? 'پرداخت کارت به کارت تایید شد' : 'پرداخت کارت به کارت تایید نشد', $text);
			}

			DB::table('c2c_request')->where('id', (int) $row->id)->update(['user_sent' => 1]);
			$sent++;
		}

		return $sent;
	}

	// ------------------------------------------------------ close the buttons

	private function closeButtons()
	{
		// the message may have been sent by the dedicated bot
		$bot = trim((string) $this->setting('c2c_bot_token'));
		$token = $bot !== '' ? $bot : trim((string) $this->setting('telegramtoken'));

		if ($token === '') {
			return 0;
		}

		$rows = DB::table('c2c_request')
			->whereIn('status', [1, 2])
			->where('tg_closed', 0)
			->where('tg_message', '>', 0)
			->orderBy('id')
			->limit(self::BATCH)
			->get();

		$closed = 0;

		foreach ($rows as $row) {
			$this->api($token, 'editMessageReplyMarkup', [
				'chat_id'      => (string) $row->tg_chat,
				'message_id'   => (int) $row->tg_message,
				'reply_markup' => json_encode(['inline_keyboard' => []]),
			]);

			DB::table('c2c_request')->where('id', (int) $row->id)->update(['tg_closed' => 1]);
			$closed++;
		}

		return $closed;
	}

	// ----------------------------------------------------- the bot's updates

	/**
	 * Polling is the default way the dedicated bot receives taps. Telegram is
	 * reachable from here (messages go out), but it cannot reach this host
	 * through the CDN, so a webhook is optional and off unless asked for.
	 */
	private function pollBot()
	{
		$token = trim((string) $this->setting('c2c_bot_token'));
		$secret = trim((string) $this->setting('c2c_bot_secret'));

		if ($token === '' || $secret === '') {
			return 0;
		}

		if ((string) $this->setting('c2c_bot_mode') === 'webhook') {
			return 0;
		}

		// getUpdates refuses to run while a webhook is set; clear it once
		if ((string) $this->setting('c2c_bot_webhook_cleared') !== '1') {
			$deleted = $this->api($token, 'deleteWebhook', []);

			if (is_array($deleted) && !empty($deleted['ok'])) {
				$this->putSetting('c2c_bot_webhook_cleared', '1');
			} else {
				return 0;
			}
		}

		$offset = (int) $this->setting('c2c_bot_offset');

		$updates = $this->api($token, 'getUpdates', [
			'offset'          => $offset,
			'timeout'         => 0,
			'allowed_updates' => json_encode(['callback_query']),
		]);

		if (!is_array($updates) || empty($updates['ok']) || !is_array($updates['result'] ?? null)) {
			return 0;
		}

		$handled = 0;

		foreach ($updates['result'] as $update) {
			$offset = max($offset, (int) ($update['update_id'] ?? 0) + 1);

			if (isset($update['callback_query']) && is_array($update['callback_query'])) {
				$this->handleCallback($token, $update['callback_query']);
				$handled++;
			}
		}

		$this->putSetting('c2c_bot_offset', (string) $offset);

		return $handled;
	}

	private function parseCallback($data, &$id, &$act)
	{
		$secret = trim((string) $this->setting('c2c_bot_secret'));
		$id = 0;
		$act = '';

		$parts = explode('|', (string) $data);
		if (count($parts) !== 4 || $parts[0] !== 'c2c') {
			return false;
		}

		$act = $parts[1] === 'a' ? 'approve' : ($parts[1] === 'r' ? 'reject' : '');
		if ($act === '' || $secret === '') {
			return false;
		}

		$id = (int) $parts[2];
		$expected = substr(hash_hmac('sha256', $act . '|' . $id, $secret), 0, 20);

		return $id > 0 && hash_equals($expected, (string) $parts[3]);
	}

	/**
	 * The decision itself is made by the same endpoint the URL button uses
	 * (c2c.decide, authorised by the request's own token), so polling and the
	 * webhook cannot drift apart in how they grant an order.
	 */
	private function triggerDecision($request, $act)
	{
		$url = $this->siteUrl() . '/xmplus-patch.php?do=c2c.decide'
			. '&id=' . (int) $request->id
			. '&act=' . urlencode($act)
			. '&t=' . urlencode((string) $request->token);

		$ch = curl_init($url);
		curl_setopt_array($ch, [
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_CONNECTTIMEOUT => 5,
			CURLOPT_TIMEOUT        => 20,
			CURLOPT_FOLLOWLOCATION => true,
			CURLOPT_USERAGENT      => 'xmplus-patch-c2c/1.0',
		]);

		$body = curl_exec($ch);
		$status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
		curl_close($ch);

		return $status === 200 && is_string($body);
	}

	private function handleCallback($token, array $callback)
	{
		$callbackId = (string) ($callback['id'] ?? '');
		$data = (string) ($callback['data'] ?? '');
		$chatId = (string) ($callback['message']['chat']['id'] ?? '');
		$messageId = (int) ($callback['message']['message_id'] ?? 0);
		$messageText = (string) ($callback['message']['text'] ?? '');

		$id = 0;
		$act = '';
		$answer = '';
		$chats = array_map('strval', $this->adminChats());

		if (!$this->parseCallback($data, $id, $act)) {
			$answer = 'دکمه نامعتبر است';
		} elseif (!in_array($chatId, $chats, true)) {
			$answer = 'اجازه ندارید';
		} else {
			$request = DB::table('c2c_request')->where('id', $id)->first();

			try {
				if ($request === null) {
					$answer = 'درخواست پیدا نشد';
				} elseif ((int) $request->status !== 0) {
					$answer = (int) $request->status === 1 ? 'قبلاً تایید شده است' : 'قبلاً رد شده است';
				} else {
					$this->triggerDecision($request, $act);

					$fresh = DB::table('c2c_request')->where('id', $id)->first();

					if ($fresh === null) {
						$answer = 'درخواست پیدا نشد';
					} elseif ((int) $fresh->status === 1) {
						$answer = '✅ تایید شد';
					} elseif ((int) $fresh->status === 2) {
						$answer = '❌ رد شد';
					} else {
						$answer = 'انجام نشد';
					}
				}
			} catch (\Throwable $error) {
				$answer = 'انجام نشد';
			}
		}

		if ($callbackId !== '') {
			$this->api($token, 'answerCallbackQuery', [
				'callback_query_id' => $callbackId,
				'text'              => $answer,
			]);
		}

		// visible feedback in the chat, and no second tap
		if ($messageId > 0 && $chatId !== '') {
			$markup = json_encode(['inline_keyboard' => []]);

			if ($messageText !== '') {
				$this->api($token, 'editMessageText', [
					'chat_id'      => $chatId,
					'message_id'   => $messageId,
					'text'         => $messageText . "\n\n" . $answer,
					'reply_markup' => $markup,
				]);
			} else {
				$this->api($token, 'editMessageReplyMarkup', [
					'chat_id'      => $chatId,
					'message_id'   => $messageId,
					'reply_markup' => $markup,
				]);
			}
		}
	}

	// --------------------------------------------------------- auto-reject

	private function expireStale()
	{
		$hours = $this->hours('c2c_reject_hours', 72);
		if ($hours < 1) {
			return 0;
		}

		$rows = DB::table('c2c_request')
			->where('status', 0)
			->where('updated', '<', time() - $hours * 3600)
			->orderBy('id')
			->limit(self::BATCH)
			->get();

		$expired = 0;

		foreach ($rows as $row) {
			$stamp = time();

			// claim it first: another run or an admin may have decided already
			$claim = DB::table('c2c_request')
				->where('id', (int) $row->id)
				->where('status', 0)
				->update([
					'status'     => 2,
					'note'       => 'مهلت بررسی به پایان رسید',
					'decided_at' => $stamp,
					'decided_by' => 'auto',
					'tg_closed'  => 0,
					'user_sent'  => 0,
				]);

			if ($claim < 1) {
				continue;
			}

			$order = DB::table('orders')->where('id', (int) $row->orderid)->first(['id', 'order_id', 'status']);

			try {
				DB::table('c2c_notice')->insertOrIgnore([
					'userid'   => (int) $row->userid,
					'kind'     => 'rejected',
					'ref'      => 'c2c:' . (int) $row->id . ':r:' . $stamp,
					'orderid'  => (int) $row->orderid,
					'order_no' => $order ? (string) $order->order_id : '',
					'name'     => (string) $row->plan_name,
					'amount'   => (float) $row->amount,
					'reason'   => 'مهلت بررسی به پایان رسید',
					'seen'     => 0,
					'created'  => time(),
				]);
			} catch (\Throwable $error) {
			}

			if ($order && (int) $order->status === 0) {
				DB::table('orders')->where('id', (int) $order->id)->update(['gateway_expire' => time()]);
			}

			$expired++;
		}

		return $expired;
	}

	// ------------------------------------------------------------- messaging

	private function callbackSig($id, $act)
	{
		$secret = trim((string) $this->setting('c2c_bot_secret'));

		if ($secret === '') {
			return '';
		}

		return substr(hash_hmac('sha256', $act . '|' . (int) $id, $secret), 0, 20);
	}

	private function callbackData($id, $act)
	{
		return 'c2c|' . ($act === 'approve' ? 'a' : 'r') . '|' . (int) $id . '|' . $this->callbackSig($id, $act);
	}

	private function api($token, $method, array $params)
	{
		$ch = curl_init('https://api.telegram.org/bot' . $token . '/' . $method);
		curl_setopt_array($ch, [
			CURLOPT_POST           => true,
			CURLOPT_POSTFIELDS     => http_build_query($params),
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_CONNECTTIMEOUT => 5,
			CURLOPT_TIMEOUT        => 10,
		]);

		$body = curl_exec($ch);
		curl_close($ch);

		return $body === false ? null : json_decode($body, true);
	}

	private function mail($user, $subject, $text)
	{
		if ($this->setting('maildriver') != 1 || !filter_var((string) $user->email, FILTER_VALIDATE_EMAIL)) {
			return;
		}

		$template = trim((string) $this->setting('promo_mail_template'));

		try {
			Queue::insert([
				'to_email'   => $user->email,
				'subject'    => $this->setting('appName') . ' - ' . $subject,
				'telegramid' => 0,
				'template'   => $template !== '' ? $template : 'promo.tpl',
				'array'      => json_encode([
					'username' => $user->username,
					'title'    => $subject,
					'lines'    => array_values(array_filter(explode("\n", $text), 'strlen')),
				], JSON_UNESCAPED_UNICODE),
				'time'       => time(),
			]);
		} catch (\Throwable $error) {
			echo date('Y-m-d H:i:s') . ' mail not queued for user ' . $user->id . ': '
				. $error->getMessage() . PHP_EOL;
		}
	}
}
