<?php
namespace App\Jobs;
use Illuminate\Database\Capsule\Manager as DB;
use App\Http\Models\Queue;

final class TicketJob
{
    private function setting($name)
    {
        return DB::table('settings')->where('name', $name)->value('value');
    }

    public function dispatch()
    {
        // A separate lock prevents overlapping sends even when run manually.
        $lock = fopen(BASE_PATH . '/storage/cron/tickets-notify.lock', 'c');
        if (!$lock || !flock($lock, LOCK_EX | LOCK_NB)) return;
        try {
            \App\Tickets\Lifecycle::closeDue();
            $rows = DB::table('ticket_close_notice')->where(function ($q) {
                $q->where('mail_sent', 0)->orWhere('telegram_sent', 0);
            })->orderBy('ticketid')->limit(100)->get();
            foreach ($rows as $notice) {
                $user = DB::table('user')->where('id', $notice->userid)->first();
                if (!$user) {
                    DB::table('ticket_close_notice')->where('ticketid', $notice->ticketid)->update(['mail_sent' => 1, 'telegram_sent' => 1]);
                    continue;
                }
                if ($this->setting('maildriver') != 1 || !filter_var($user->email, FILTER_VALIDATE_EMAIL))
                    DB::table('ticket_close_notice')->where('ticketid', $notice->ticketid)->update(['mail_sent' => 1]);
                if ($this->setting('telegram') != 1 || empty($user->telegram_id) || trim((string) $this->setting('telegramtoken')) === '')
                    DB::table('ticket_close_notice')->where('ticketid', $notice->ticketid)->update(['telegram_sent' => 1]);
                $text = 'تیکت شماره ' . $notice->ticketid . ' پس از ۴۸ ساعت بدون پیام جدید، خودکار بسته شد.';
                if (!$notice->mail_sent && $this->setting('maildriver') == 1 && filter_var($user->email, FILTER_VALIDATE_EMAIL)) {
                    DB::connection()->transaction(function () use ($notice, $user, $text) {
                        Queue::insert(['to_email' => $user->email, 'subject' => 'تیکت بسته شد', 'telegramid' => 0,
                            'template' => 'promo.tpl', 'array' => json_encode(['username' => $user->username,
                                'title' => 'تیکت بسته شد', 'lines' => [$text]], JSON_UNESCAPED_UNICODE), 'time' => time()]);
                        DB::table('ticket_close_notice')->where('ticketid', $notice->ticketid)->update(['mail_sent' => 1]);
                    });
                }
                if (!$notice->telegram_sent && $this->setting('telegram') == 1 && !empty($user->telegram_id)) {
                    $token = trim((string) $this->setting('telegramtoken'));
                    if ($token === '') continue;
                    $ch = curl_init('https://api.telegram.org/bot' . $token . '/sendMessage');
                    curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_POSTFIELDS => http_build_query([
                        'chat_id' => $user->telegram_id, 'text' => $text]), CURLOPT_RETURNTRANSFER => true,
                        CURLOPT_CONNECTTIMEOUT => 5, CURLOPT_TIMEOUT => 10]);
                    $result = json_decode((string) curl_exec($ch), true);
                    curl_close($ch);
                    if (!empty($result['ok'])) DB::table('ticket_close_notice')->where('ticketid', $notice->ticketid)->update(['telegram_sent' => 1]);
                }
            }
        } finally { flock($lock, LOCK_UN); fclose($lock); }
    }
}
