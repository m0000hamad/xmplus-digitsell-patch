<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/**
 * Tells the customer on Telegram that a gift card they redeemed was applied,
 * and the admin chat that it was used.
 *
 * Redeeming goes through the encoded /portal/redeem, which has no hook, but it
 * writes every use to `giftcard_logs`. This job runs every minute and reports
 * the rows it has not reported yet.
 *
 * A watermark, the setting `giftcard_notify_last_id`, marks the last row
 * reported. The first run sets it to the newest existing row without sending
 * anything, so cards redeemed before this job existed are never announced.
 * The watermark is moved past a row BEFORE its messages go out: a failed send
 * loses one message, it never sends two.
 *
 * Settings rows (`settings.name`):
 *   giftcard_notify           0 switches the job off (missing = on)
 *   giftcard_notify_last_id   the watermark, written by this job
 *   tgjoin_admin_chats        admin chat ids, shared with TgJoinJob (default:
 *                             the panel's `telegramchatid`)
 */
class GiftCardNotifyJob
{
	/** rows handled per run - the job runs every minute */
	const BATCH = 30;

	public function dispatch()
	{
		if ($this->setting('giftcard_notify') === '0') {
			return 0;
		}

		$token = trim((string) $this->setting('telegramtoken'));
		if ($token === '' || $this->setting('telegram') != 1) {
			return 0;
		}

		$last = $this->setting('giftcard_notify_last_id');
		if ($last === null) {
			$this->putSetting('giftcard_notify_last_id', (string) (int) DB::table('giftcard_logs')->max('id'));
			echo date('Y-m-d H:i:s') . " seeded at the newest existing row" . PHP_EOL;
			return 0;
		}

		$rows = DB::table('giftcard_logs')
			->where('id', '>', (int) $last)
			->orderBy('id')
			->limit(self::BATCH)
			->get();

		$sent = 0;
		foreach ($rows as $row) {
			$this->putSetting('giftcard_notify_last_id', (string) $row->id);

			$user = DB::table('user')->where('id', (int) $row->userid)
				->first(['id', 'username', 'telegram_id', 'telegram_name', 'money']);
			if (!$user) {
				continue;
			}

			$card = DB::table('giftcards')->where('id', (int) $row->card_id)->first(['credit']);
			$credit = $card ? $this->money($card->credit) : '';
			$balance = $this->money($user->money);

			if ((string) $user->telegram_id !== '' && (int) $user->telegram_id !== 0) {
				$text = "🎁 کارت هدیه‌ات با موفقیت ثبت شد!\n\n"
					. ($credit !== '' ? "💰 مبلغ {$credit} به کیف پولت اضافه شد.\n" : "💰 کیف پولت شارژ شد.\n")
					. "👛 موجودی فعلی کیف پول: {$balance}\n\n"
					. "می‌توانی همین حالا با این موجودی اشتراک بخری یا تمدید کنی.";
				$this->api($token, 'sendMessage', ['chat_id' => $user->telegram_id, 'text' => $text]);
				$sent++;
			}

			$this->tellAdmins($token, $user, $row, $credit, $balance);

			echo date('Y-m-d H:i:s') . sprintf(" log %d user %d card %d reported", $row->id, $user->id, $row->card_id) . PHP_EOL;
			usleep(50000);
		}

		return $sent;
	}

	/*
	 * "12,500,000 ریال" in the panel's default currency.
	 */
	private function money($amount)
	{
		static $currency = false;
		if ($currency === false) {
			$currency = DB::table('currency')->where('currency', (string) $this->setting('default_currency'))->first();
		}

		$decimals = $currency ? (int) $currency->decimals : 0;
		$text = number_format((float) $amount, $decimals);

		return $currency
			? trim($currency->symbol_left . ' ' . $text . ' ' . $currency->symbol_right)
			: $text;
	}

	private function tellAdmins($token, $user, $row, $credit, $balance)
	{
		$chats = trim((string) $this->setting('tgjoin_admin_chats'));
		if ($chats === '') {
			$chats = trim((string) $this->setting('telegramchatid'));
		}
		if ($chats === '') {
			return;
		}

		$who = "👤 {$user->username} (#{$user->id})";
		if ((string) $user->telegram_name !== '') {
			$who .= " · @{$user->telegram_name}";
		}

		$text = "🎟 کارت هدیه ثبت شد\n{$who}\n"
			. "🏷 {$row->remarks} · کد {$row->code}\n"
			. ($credit !== '' ? "💰 مبلغ: {$credit}\n" : '')
			. "👛 موجودی کیف پول: {$balance}";

		foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
			$this->api($token, 'sendMessage', ['chat_id' => $chat, 'text' => $text]);
		}
	}

	private function setting($name)
	{
		return DB::table('settings')->where('name', $name)->value('value');
	}

	private function putSetting($name, $value)
	{
		if (DB::table('settings')->where('name', $name)->exists()) {
			DB::table('settings')->where('name', $name)->update(['value' => $value]);
		} else {
			DB::table('settings')->insert(['name' => $name, 'value' => $value]);
		}
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
}
