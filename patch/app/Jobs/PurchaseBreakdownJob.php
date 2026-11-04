<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/** Complement to the ionCube transaction alert. Never changes an order or balance.
 * The claim is durable before send: a crash/ambiguous Telegram timeout cannot
 * duplicate a financial notice. Explicit Telegram rejection is retried next run.
 */
final class PurchaseBreakdownJob
{
    public function dispatch(): void
    {
        $db = DB::connection('default')->getPdo();
        $settings = [];
        foreach ($db->query("SELECT name,value FROM settings WHERE name IN ('telegram','telegramtoken','telegramchatid','purchase_breakdown_since')")->fetchAll(\PDO::FETCH_ASSOC) as $r) {
            $settings[$r['name']] = $r['value'];
        }
        if (($settings['telegram'] ?? '') != '1' || empty($settings['telegramtoken']) || empty($settings['purchase_breakdown_since'])) { return; }
        $chats = array_unique(preg_split('~[\s,]+~', trim($settings['telegramchatid'] ?? ''), -1, PREG_SPLIT_NO_EMPTY));
        require_once __DIR__ . '/../Patch/PurchaseBreakdown.php';
        foreach ($chats as $chat) {
            $q = $db->prepare("SELECT o.* FROM orders o LEFT JOIN purchase_breakdown_notice n ON n.orderid=o.id AND n.chat=?
                WHERE o.pay_date>=? AND o.pay_date>0 AND o.status IN (1,2) AND (n.orderid IS NULL OR n.state='retry') ORDER BY o.id LIMIT 30");
            $q->execute([$chat, $settings['purchase_breakdown_since']]);
            foreach ($q->fetchAll(\PDO::FETCH_ASSOC) as $o) {
                $h = $db->prepare("SELECT * FROM checkout_funds WHERE orderid=? AND state IN ('reserved','spent')");
                $h->execute([$o['id']]);
                $text = \PurchaseBreakdown::text($o, $h->fetch(\PDO::FETCH_ASSOC) ?: null);
                $claim = $db->prepare("INSERT IGNORE INTO purchase_breakdown_notice (orderid,chat,state,updated) VALUES (?,?,'retry',?)");
                $claim->execute([$o['id'], $chat, time()]);
                $claim = $db->prepare("UPDATE purchase_breakdown_notice SET state='sending',updated=? WHERE orderid=? AND chat=? AND state='retry'");
                $claim->execute([time(), $o['id'], $chat]);
                if (!$claim->rowCount()) { continue; }
                $ch = curl_init('https://api.telegram.org/bot' . $settings['telegramtoken'] . '/sendMessage');
                curl_setopt_array($ch, [CURLOPT_POST=>true, CURLOPT_POSTFIELDS=>http_build_query(['chat_id'=>$chat,'text'=>$text]),
                    CURLOPT_RETURNTRANSFER=>true, CURLOPT_CONNECTTIMEOUT=>5, CURLOPT_TIMEOUT=>10]);
                $answer = json_decode((string) curl_exec($ch), true);
                curl_close($ch);
                $state = !empty($answer['ok']) ? 'sent' : (isset($answer['ok']) && $answer['ok'] === false ? 'retry' : 'uncertain');
                $db->prepare('UPDATE purchase_breakdown_notice SET state=?,updated=? WHERE orderid=? AND chat=?')->execute([$state,time(),$o['id'],$chat]);
            }
        }
    }
}

