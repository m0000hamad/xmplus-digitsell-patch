<?php
namespace App\Tickets;

use Illuminate\Database\Capsule\Manager as DB;

final class Lifecycle
{
    const TTL = 172800;
    const CLOSED = 'این تیکت بسته شده است. برای ادامه، تیکت جدید باز کنید.';

    public static function expired($root, int $latest, ?int $now = null): bool
    {
        return (int) $root->status === 0 || max((int) $root->datetime, $latest) <= ($now ?? time()) - self::TTL;
    }

    // Caller holds the parent row lock. All model writes take the same lock.
    public static function assertOpen(int $id): void
    {
        $root = DB::table('tickets')->where('id', $id)->lockForUpdate()->first();
        if (!$root || (int) $root->rootid !== 0) throw new \RuntimeException(self::CLOSED);
        $latest = (int) DB::table('tickets')->where('main_id', $id)->max('datetime');
        if (self::expired($root, $latest)) throw new \RuntimeException(self::CLOSED);
    }

    public static function closeDue(int $limit = 100): int
    {
        $ids = DB::table('tickets')->where('rootid', 0)->where('status', '<>', 0)
            ->where('datetime', '<=', time() - self::TTL)->orderBy('id')->pluck('id');
        $closed = 0;
        foreach ($ids as $id) {
            $changed = DB::connection()->transaction(function () use ($id) {
                $root = DB::table('tickets')->where('id', $id)->lockForUpdate()->first();
                $latest = (int) DB::table('tickets')->where('main_id', $id)->max('datetime');
                if (!$root || (int) $root->status === 0 || !self::expired($root, $latest)) return false;
                DB::table('tickets')->where('id', $id)->update(['status' => 0]);
                DB::table('ticket_close_notice')->insert(['ticketid' => $id, 'userid' => $root->userid,
                    'created' => time(), 'mail_sent' => 0, 'telegram_sent' => 0]);
                return true;
            });
            if ($changed && ++$closed >= $limit) break;
        }
        return $closed;
    }

    public static function attachmentName(string $name): bool
    {
        return (bool) preg_match('/^tk_([1-9][0-9]*)_[a-f0-9]{48}\.(jpg|png|webp)$/D', $name);
    }

    public static function validateAttachment(string $name, int $userId): void
    {
        if ($name === '') return;
        if (!self::attachmentName($name) || strpos($name, 'tk_' . $userId . '_') !== 0
            || !is_file(BASE_PATH . '/storage/ticket-images/' . $name)) {
            throw new \RuntimeException('پیوست نامعتبر است. عکس را دوباره انتخاب کنید.');
        }
    }
}
