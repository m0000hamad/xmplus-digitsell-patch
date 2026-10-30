<?php
declare(strict_types=1);

/** Two physical inbounds share the native node, accounts and quota. */
final class ProfileBilling
{
    public static function normalize(array $value): array
    {
        foreach (['ports', 'rates'] as $key) {
            if (isset($value[$key]) && !is_array($value[$key])) throw new InvalidArgumentException('تنظیمات پورت و ضریب معتبر نیست.');
        }
        $enabled = !empty($value['enabled']);
        $ports = []; $rates = [];
        foreach ([1, 2] as $slot) {
            $port = filter_var($value['ports'][$slot] ?? null, FILTER_VALIDATE_INT,
                ['options' => ['min_range' => 1, 'max_range' => 65535]]);
            $rate = $value['rates'][$slot] ?? ($slot === 1 ? 1 : 4);
            if (!is_scalar($rate) || !is_numeric($rate) || !is_finite((float) $rate)
                || (float) $rate < 0 || (float) $rate > 1000) throw new InvalidArgumentException('ضریب باید بین صفر و ۱۰۰۰ باشد.');
            if ($enabled && !$port) throw new InvalidArgumentException('برای هر لینک یک پورت بین ۱ و ۶۵۵۳۵ وارد کنید.');
            $ports[$slot] = $port ? (int) $port : null;
            $rates[$slot] = (float) $rate;
        }
        if ($enabled && $ports[1] === $ports[2]) throw new InvalidArgumentException('پورت دو لینک باید متفاوت باشد.');
        $out = ['enabled' => $enabled, 'ports' => $ports, 'rates' => $rates];
        $out['revision'] = hash('sha256', json_encode($out));
        return $out;
    }

    public static function read(string $json): array
    {
        $value = json_decode($json, true);
        return is_array($value) ? $value : [];
    }

    public static function setting(PDO $db, string $key): string
    {
        $q = $db->prepare('SELECT value FROM settings WHERE name=?'); $q->execute([$key]);
        return (string) ($q->fetchColumn() ?: '');
    }

    /** An acknowledged batch is debited once, including after a lost HTTP reply. */
    public static function charge(PDO $db, array $body): array
    {
        $node = filter_var($body['node_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        $batch = $body['batch_id'] ?? '';
        $rows = $body['data'] ?? null;
        if (!$node || !is_string($batch) || !preg_match('/^[a-f0-9]{32}$/D', $batch)
            || !is_array($rows) || !$rows || count($rows) > 10000) throw new InvalidArgumentException('Invalid traffic batch');
        $q = $db->prepare('SELECT id,name FROM servers WHERE id=?'); $q->execute([$node]);
        $server = $q->fetch(PDO::FETCH_ASSOC);
        if (!$server) throw new InvalidArgumentException('Unknown node');
        $prepared = []; $rawTotal = 0;
        foreach ($rows as $row) {
            if (!is_array($row)) throw new InvalidArgumentException('Invalid traffic row');
            $uid = filter_var($row['subscription_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            $slot = $row['profile'] ?? null; $revision = $row['revision'] ?? '';
            if (!$uid || !in_array($slot, [1, 2], true) || !is_string($revision)
                || !preg_match('/^[a-f0-9]{64}$/D', $revision)) throw new InvalidArgumentException('Invalid traffic identity');
            $snapshot = self::read(self::setting($db, 'server_profile_billing_history_' . $node . '_' . $revision));
            if (empty($snapshot['enabled']) || ($snapshot['revision'] ?? '') !== $revision
                || !isset($snapshot['rates'][$slot])) throw new InvalidArgumentException('Unknown billing revision');
            $rate = (float) $snapshot['rates'][$slot]; $bytes = [];
            foreach (['u', 'd'] as $direction) {
                $amount = $row[$direction] ?? null;
                if (!is_int($amount) || $amount < 0 || $amount > 1000000000000) throw new InvalidArgumentException('Invalid traffic counter');
                $bytes[$direction] = $amount;
            }
            $rawTotal += $bytes['u'] + $bytes['d'];
            $prepared[] = ['uid' => $uid, 'slot' => $slot, 'rate' => $rate,
                'u' => (int) ($bytes['u'] * $rate), 'd' => (int) ($bytes['d'] * $rate)];
        }
        $digest = hash('sha256', json_encode($body));
        $db->beginTransaction();
        try {
            try {
                $db->prepare('INSERT INTO profile_traffic_batch(node_id,batch_id,digest,created_at) VALUES(?,?,?,?)')
                    ->execute([$node, $batch, $digest, time()]);
            } catch (PDOException $error) {
                $q = $db->prepare('SELECT digest FROM profile_traffic_batch WHERE node_id=? AND batch_id=?');
                $q->execute([$node, $batch]); $previous = $q->fetchColumn();
                if ($previous === false || !hash_equals((string) $previous, $digest)) throw $error;
                $db->rollBack();
                return ['accepted' => true, 'duplicate' => true];
            }
            $logging = self::setting($db, 'disable_trafficlog') !== '1';
            foreach ($prepared as $row) {
                $q = $db->prepare('SELECT id,username,email FROM user WHERE id=?'); $q->execute([$row['uid']]);
                $user = $q->fetch(PDO::FETCH_ASSOC);
                if (!$user) continue;
                $db->prepare('UPDATE user SET u=u+?, d=d+?, total_data_used=total_data_used+?, t=? WHERE id=?')
                    ->execute([$row['u'], $row['d'], $row['u'] + $row['d'], time(), $row['uid']]);
                if ($logging) $db->prepare('INSERT INTO trafficlog(userid,username,serverid,email,u,d,servername,rate,total,datetime) VALUES(?,?,?,?,?,?,?,?,?,?)')
                    ->execute([$row['uid'], $user['username'], $node, $user['email'], $row['u'], $row['d'],
                        $server['name'] . ' [link ' . $row['slot'] . ']', $row['rate'], $row['u'] + $row['d'], time()]);
            }
            $db->prepare('UPDATE servers SET bandwidth=bandwidth+? WHERE id=?')->execute([$rawTotal, $node]);
            $db->commit();
            return ['accepted' => true, 'duplicate' => false];
        } catch (Throwable $error) { if ($db->inTransaction()) $db->rollBack(); throw $error; }
    }
}
