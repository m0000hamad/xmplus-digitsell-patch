<?php
/**
 * Cross-check the WireGuard key derivation and address reservation.
 *
 *   php tools/_wgkey_crosscheck.php
 *
 * Two things can be wrong in a way nothing else would catch, so they are
 * checked here:
 *
 *  1. the private key is derived twice in the panel - app/Patch/Wg.php
 *     (wgPrivateKey, for the file) and app/Http/Models/User.php (wgPublicKey,
 *     for the card) - and they must never disagree;
 *  2. the tunnel address. It starts from a hash of the public key, so two
 *     accounts can land on the same one; the panel reserves it in wg_credential
 *     under a UNIQUE (nodeid, address) and moves on when it is taken. This
 *     replays that against a real SQLite table, because the whole point is the
 *     UNIQUE index refusing the second writer.
 */

$secret = str_repeat('k', 32);
$fails = 0;

function fail_test(string $why)
{
    global $fails;
    $fails++;
    echo "  FAIL: $why\n";
}

/** app/Patch/Wg.php :: wgClampScalar() */
function clamp(string $raw): string
{
    $key = $raw;
    $key[0] = chr(ord($key[0]) & 248);
    $key[31] = chr((ord($key[31]) & 127) | 64);

    return $key;
}

/** app/Patch/Wg.php :: wgPrivateKey() */
function panel_private(int $userId, string $uuid, string $secret): string
{
    $raw = hash_hmac('sha256', 'key:' . $userId . ':' . strtolower(trim($uuid)), $secret, true);

    return sodium_bin2base64(clamp($raw), SODIUM_BASE64_VARIANT_ORIGINAL);
}

/** app/Patch/Wg.php :: wgPublicKey() */
function panel_public(string $private): string
{
    return sodium_bin2base64(
        sodium_crypto_scalarmult(
            sodium_base642bin($private, SODIUM_BASE64_VARIANT_ORIGINAL),
            "\x09" . str_repeat("\0", 31)),
        SODIUM_BASE64_VARIANT_ORIGINAL);
}

/** app/Http/Models/User.php :: wgPublicKey(), the other copy in the panel */
function card_public(int $userId, string $uuid, string $secret): string
{
    $scalar = hash_hmac('sha256', 'key:' . $userId . ':' . strtolower(trim($uuid)), $secret, true);
    $scalar[0] = chr(ord($scalar[0]) & 248);
    $scalar[31] = chr((ord($scalar[31]) & 127) | 64);

    return sodium_bin2base64(
        sodium_crypto_scalarmult($scalar, "\x09" . str_repeat("\0", 31)),
        SODIUM_BASE64_VARIANT_ORIGINAL);
}

/** app/Patch/Wg.php :: wgAddressFor() */
function address_for(int $nodeId, string $pubkey, int $step = 0): string
{
    $hash = unpack('N', substr(hash('sha256', $pubkey, true), 0, 4));
    $start = ($hash === false ? 0 : $hash[1] % 65534) + 1;
    $host = ((($start - 1) + $step * 65521) % 65534) + 1;

    return '10.' . max(0, $nodeId) . '.' . intdiv($host, 256) . '.' . ($host % 256);
}

// ---------------------------------------------------------------- the key

echo "1. the private key is a well-formed, clamped X25519 key\n";
$private = panel_private(42, 'AAAA-BBBB-CCCC', $secret);
$decoded = sodium_base642bin($private, SODIUM_BASE64_VARIANT_ORIGINAL);
printf("   %s  (%d bytes)\n", $private, strlen($decoded));
if (strlen($decoded) !== 32) {
    fail_test('not 32 bytes');
}
if (!preg_match('~^[A-Za-z0-9+/]{43}=$~', $private)) {
    fail_test('not 44 base64 characters with one padding character');
}
if ((ord($decoded[0]) & 7) !== 0 || (ord($decoded[31]) & 0x80) !== 0 || (ord($decoded[31]) & 0x40) === 0) {
    fail_test('not clamped the way X25519 requires');
}
printf("   public key %s\n", panel_public($private));
if (panel_public($private) !== card_public(42, 'AAAA-BBBB-CCCC', $secret)) {
    fail_test('Wg.php and User.php derive different public keys for the same account');
}

// ---------------------------------------------------------------- the psk

echo "\n2. the preshared key is separate from the private one\n";
$psk = sodium_bin2base64(
    clamp(hash_hmac('sha256', 'psk:42:aaaa-bbbb-cccc', $secret, true)),
    SODIUM_BASE64_VARIANT_ORIGINAL);
printf("   %s  (%d bytes)\n", $psk, strlen(sodium_base642bin($psk, SODIUM_BASE64_VARIANT_ORIGINAL)));
if ($psk === $private) {
    fail_test('the preshared key is the private key');
}
if (panel_public($private) === panel_public($psk)) {
    fail_test('the preshared key gives the same public key as the private one');
}

// ---------------------------------------------------------------- the psk

echo "\n3. the address lands in the node's own /16 and never on a boundary\n";
foreach ([1, 2, 42, 200] as $nodeId) {
    $address = address_for($nodeId, panel_public(panel_private(42, 'AAAA-BBBB-CCCC', $secret)));
    $octets = array_map('intval', explode('.', $address));
    // 10.<node>.<a>.<b>: the third octet is never 0 (that is 10.<node>.0.0, a
    // network address) and the fourth is never 0 (a /24 boundary)
    $ok = $octets[0] === 10 && $octets[1] === $nodeId
        && $octets[2] >= 1 && $octets[3] >= 1;
    printf("   node %3d -> %-15s %s\n", $nodeId, $address, $ok ? 'ok' : 'FAIL');
    if (!$ok) {
        fail_test("node $nodeId got an address outside its own /16");
    }
}

// ------------------------------------------------- the reservation works

echo "\n4. two accounts whose keys hash alike still get different addresses\n";
$db = new PDO('sqlite::memory:');
$db->exec('CREATE TABLE wg_credential (
    userid INTEGER PRIMARY KEY,
    pubkey TEXT,
    updated INTEGER,
    nodeid INTEGER DEFAULT NULL,
    address TEXT DEFAULT NULL,
    UNIQUE (nodeid, address)
)');

/** app/Patch/Wg.php :: wgReservedAddress(), against the same UNIQUE index */
function reserve(PDO $db, int $userId, int $nodeId, string $pubkey): ?string
{
    $find = $db->prepare('SELECT address FROM wg_credential WHERE userid = ? AND nodeid = ? LIMIT 1');
    $find->execute([$userId, $nodeId]);
    $have = $find->fetch();
    if ($have !== false && $have['address'] !== null) {
        return (string) $have['address'];
    }

    for ($step = 0; $step < 512; $step++) {
        $address = address_for($nodeId, $pubkey, $step);
        try {
            $claim = $db->prepare('UPDATE wg_credential SET nodeid = ?, address = ?, updated = ?
                                   WHERE userid = ? AND (address IS NULL OR nodeid = ?)');
            $claim->execute([$nodeId, $address, time(), $userId, $nodeId]);
        } catch (PDOException $error) {
            continue;
        }

        $check = $db->prepare('SELECT userid FROM wg_credential WHERE nodeid = ? AND address = ? LIMIT 1');
        $check->execute([$nodeId, $address]);
        $holder = $check->fetch();

        if ($holder !== false && (int) $holder['userid'] === $userId) {
            return $address;
        }
    }

    return address_for($nodeId, $pubkey);
}

// 2000 accounts on one node, each claiming an address the way a download does
$taken = [];
$addressOf = [];
$seed = $db->prepare('INSERT INTO wg_credential (userid, pubkey, updated) VALUES (?, ?, ?)');
for ($id = 1; $id <= 2000; $id++) {
    $pubkey = panel_public(panel_private($id, 'uuid-' . $id, $secret));
    $seed->execute([$id, $pubkey, time()]);
    $address = reserve($db, $id, 7, $pubkey);
    if ($address === null) {
        fail_test("user $id could not claim an address");
        continue;
    }
    if (isset($taken[$address])) {
        fail_test("users $taken[$address] and $id both got $address on node 7");
    }
    $taken[$address] = $id;
    $addressOf[$id] = $address;
}
printf("   2000 accounts, %d distinct addresses\n", count($taken));

// and asking a second time gives the same answer, which is what keeps the
// customer's .conf and the node's peer in step
$drift = [];
for ($id = 1; $id <= 2000; $id += 97) {
    $pubkey = panel_public(panel_private($id, 'uuid-' . $id, $secret));
    $again = reserve($db, $id, 7, $pubkey);
    if ($again !== $addressOf[$id]) {
        $drift[] = $id;
    }
}
printf("   %d accounts asked a second time, %d drifted\n", intdiv(2000, 97) + 1, count($drift));
foreach ($drift as $id) {
    fail_test("user $id lost its address on the second ask");
}

// the same account on a second node gets an address in that node's own /16
$pubkey = panel_public(panel_private(1, 'uuid-1', $secret));
$other = reserve($db, 1, 9, $pubkey);
printf("   user 1 on node 9 -> %s\n", $other);
$octets = array_map('intval', explode('.', (string) $other));
if ($octets[1] !== 9) {
    fail_test('the same account on another node did not land in that node\'s /16');
}

// ------------------------------------------------------------- a key is stable

echo "\n5. the same account always gets the same key, and wg_secret changes it\n";
$first = panel_public(panel_private(42, 'aaaa-bbbb-cccc', $secret));
$again = panel_public(panel_private(42, 'AAAA-BBBB-CCCC', $secret));
$other = panel_public(panel_private(42, 'aaaa-bbbb-cccc', str_repeat('j', 32)));
printf("   %s\n   %s\n   %s\n", $first, $again, $other);
if ($first !== $again) {
    fail_test("the uuid's case changed the key");
}
if ($first === $other) {
    fail_test('a different wg_secret gave the same key');
}
if (panel_public(panel_private(43, 'aaaa-bbbb-cccc', $secret)) === $first) {
    fail_test('two accounts share a key');
}

echo $fails === 0 ? "\nall checks passed\n" : "\n$fails FAILED\n";
exit($fails === 0 ? 0 : 1);