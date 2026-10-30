<?php
/** Authoritative online snapshot, scoped to one authenticated node. */
declare(strict_types=1);

function nodeOnlineRows(array $rows): array
{
    if (count($rows) > 10000) {
        throw new InvalidArgumentException('too many online addresses');
    }
    $clean = [];
    foreach ($rows as $row) {
        if (!is_array($row) || !isset($row['subscription_id'], $row['ip'])
            || !is_scalar($row['subscription_id']) || !is_string($row['ip'])
            || !ctype_digit((string) $row['subscription_id']) || (int) $row['subscription_id'] <= 0) {
            throw new InvalidArgumentException('invalid online row');
        }
        $id = (int) $row['subscription_id'];
        $ip = trim($row['ip'], " \t\n\r\0\x0B[]");
        if (filter_var($ip, FILTER_VALIDATE_IP) === false) {
            throw new InvalidArgumentException('invalid online IP');
        }
        $packed = inet_pton($ip);
        if (strlen($packed) === 16 && substr($packed, 0, 12) === str_repeat("\0", 10) . "\xff\xff") {
            $ip = inet_ntop(substr($packed, 12));
        } else {
            $ip = inet_ntop($packed);
        }
        $clean[$id . '|' . $ip] = ['subscription_id' => $id, 'ip' => $ip];
    }
    return array_values($clean);
}

function nodeOnlineProfiles(array $rows, array $online): array
{
    if (count($rows) > 20000) throw new InvalidArgumentException('too many profile addresses');
    $allowed = [];
    foreach ($online as $row) $allowed[$row['subscription_id'] . '|' . $row['ip']] = true;
    $clean = [];
    foreach ($rows as $row) {
        if (!is_array($row) || !in_array($row['profile'] ?? null, [1, 2], true)) throw new InvalidArgumentException('invalid online profile');
        $normalized = nodeOnlineRows([$row])[0];
        $key = $normalized['subscription_id'] . '|' . $normalized['ip'];
        if (!isset($allowed[$key])) throw new InvalidArgumentException('profile IP is not in the allowed online snapshot');
        $clean[$row['profile'] . '|' . $key] = $normalized + ['profile' => $row['profile']];
    }
    return array_values($clean);
}

function nodeOnlineSnapshot(PDO $pdo, int $node, array $rows, int $now, ?array $profiles = null, bool $profilesActive = false): int
{
    if ($node <= 0) {
        throw new InvalidArgumentException('invalid node id');
    }
    // Validate the entire payload before deleting anything, including empty snapshots.
    if ($profilesActive && $profiles === null) throw new InvalidArgumentException('profile snapshot missing');
    $rows = nodeOnlineRows($rows);
    $profiles = nodeOnlineProfiles($profiles ?? [], $rows);
    $pdo->beginTransaction();
    try {
        $sql = 'SELECT name FROM servers WHERE id = ?';
        if ($pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql') {
            $sql .= ' FOR UPDATE';
        }
        $query = $pdo->prepare($sql);
        $query->execute([$node]);
        $server = $query->fetch(PDO::FETCH_ASSOC);
        if (!$server) {
            throw new InvalidArgumentException('node not found');
        }
        $users = [];
        foreach (array_chunk(array_values(array_unique(array_column($rows, 'subscription_id'))), 500) as $ids) {
            $query = $pdo->prepare('SELECT id, username FROM user WHERE id IN (' . implode(',', array_fill(0, count($ids), '?')) . ')');
            $query->execute($ids);
            foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $user) {
                $users[(int) $user['id']] = (string) $user['username'];
            }
        }
        $pdo->prepare('DELETE FROM online_ip WHERE serverid = ?')->execute([$node]);
        $insert = $pdo->prepare('INSERT INTO online_ip (userid, serverid, ip, datetime, username, servername) VALUES (?, ?, ?, ?, ?, ?)');
        $count = 0;
        foreach ($rows as $row) {
            if (!array_key_exists($row['subscription_id'], $users)) {
                continue;
            }
            $insert->execute([$row['subscription_id'], $node, $row['ip'], $now,
                              $users[$row['subscription_id']], $server['name']]);
            ++$count;
        }
        $perProfile = [1 => [], 2 => []]; $identified = []; $unknown = [];
        foreach ($profiles as $row) {
            if (!isset($users[$row['subscription_id']])) continue;
            $perProfile[$row['profile']][$row['subscription_id']] = true;
            $identified[$row['subscription_id'] . '|' . $row['ip']] = true;
        }
        foreach ($rows as $row) {
            if (isset($users[$row['subscription_id']]) && !isset($identified[$row['subscription_id'] . '|' . $row['ip']])) $unknown[$row['subscription_id']] = true;
        }
        $pdo->prepare('DELETE FROM node_profile_online WHERE serverid=?')->execute([$node]);
        $pdo->prepare('INSERT INTO node_profile_online(serverid,profile1,profile2,unclassified,ready,datetime) VALUES(?,?,?,?,?,?)')
            ->execute([$node, count($perProfile[1]), count($perProfile[2]), count($unknown), $profilesActive ? 1 : 0, $now]);
        $pdo->commit();
        return $count;
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
}
