<?php
require __DIR__ . '/../patch/app/Patch/ServerProfileCards.php';
function check($ok, $message) { if (!$ok) throw new RuntimeException($message); echo "PASS $message\n"; }
$cards = [['id'=>11,'name'=>'Native','server'=>'Vless','online'=>1,'info'=>'DE',
    'link'=>'vless://fixture@native.invalid:443?security=tls&sni=tls.invalid&type=ws&path=%2Fsocket#Native'],
    ['id'=>12,'name'=>'Unmapped','link'=>'trojan://fixture@other.invalid:443#Other']];
$a = ['enabled'=>true,'groups'=>[2],'servers'=>[11,99]];
$settings = ['sub_profiles'=>json_encode([$a,$a]),
    'server_profile_billing_11'=>'{"enabled":true,"ports":{"1":2052,"2":2053}}',
    'server_profile_domains_11'=>'{"1":"first.invalid","2":"second.invalid"}',
    'server_profile_names_11'=>'{"1":"First <name>","2":"Second"}'];
$rows = ServerProfileCards::expand($cards, $settings, ['server_group'=>2]);
check(count($rows) === 3, 'two distinct cards and untouched unmapped server; no extra node access');
check($rows[0]['link'] === 'vless://fixture@first.invalid:2052?security=tls&sni=tls.invalid&type=ws&path=%2Fsocket#' . rawurlencode('First <name> (2052)'), 'first card preserves native credentials and transport');
check($rows[1]['link'] === 'vless://fixture@second.invalid:2053?security=tls&sni=tls.invalid&type=ws&path=%2Fsocket#Second%20%282053%29', 'second card has its own address, port and label');
check($rows[2] === $cards[1] && $rows[1]['online'] === 1, 'native metadata and unmapped cards retained');
check(ServerProfileCards::expand($cards,$settings,['server_group'=>4]) === $cards, 'other group gets no profile overrides');
$settings['sub_profiles'] = json_encode([$a, ['enabled'=>false]+$a]);
check(count(ServerProfileCards::expand($cards,$settings,['server_group'=>2])) === 2, 'disabled second profile excluded');
$settings['sub_profiles'] = json_encode([['enabled'=>false]+$a,$a]);
check(strpos(ServerProfileCards::expand($cards,$settings,['server_group'=>2])[0]['link'],'second.invalid:2053') !== false, 'source slot preserved when first profile is disabled');
$settings['server_profile_billing_11'] = '{"enabled":false}';
check(ServerProfileCards::expand($cards,$settings,['server_group'=>2]) === $cards, 'disabled billing preserves original links');
$vmess = ['add'=>'native.invalid','port'=>'443','ps'=>'Native','id'=>'fixture','net'=>'ws','host'=>'ws.invalid','path'=>'/socket','tls'=>'tls','sni'=>'tls.invalid'];
$link = ServerProfileCards::link('vmess://'.base64_encode(json_encode($vmess)), 'second.invalid',2053,'Second');
$actual = json_decode(base64_decode(substr($link,8)),true);
check($actual === array_replace($vmess,['add'=>'second.invalid','port'=>2053,'ps'=>'Second']), 'VMess JSON updates endpoint and label only');
foreach (['trojan://fixture@[2001:db8::1]:443?security=tls&sni=native.invalid#Old',
          'ss://'.base64_encode('aes-256-gcm:fixture').'@native.invalid:443/?plugin=obfs-local%3Bobfs%3Dhttp#Old'] as $link) {
    $updated = ServerProfileCards::link($link,'2001:db8::2',2053,'New');
    check(strpos($updated,'@[2001:db8::2]:2053') !== false && substr($updated,-4) === '#New', 'URI endpoint supports IPv6 and new label');
    check(strpos($updated,substr($link,strpos($link,'?'),strpos($link,'#')-strpos($link,'?'))) !== false, 'native TLS/plugin query retained');
}
$legacy = 'ss://'.base64_encode('aes-256-gcm:fixture@native.invalid:443').'#Old';
$updated = ServerProfileCards::link($legacy,'second.invalid',2053,'New');
check(base64_decode(explode('#',substr($updated,5))[0]) === 'aes-256-gcm:fixture@second.invalid:2053', 'legacy Shadowsocks retains credentials');
check(ServerProfileCards::link('unknown://native.invalid:443','',2053,'New') === null, 'unknown formats are not mislabeled as a new config');

// Optional local Smarty installation: render the real page with layout includes stubbed.
if (isset($argv[1])) {
    require $argv[1];
    $smarty = new Smarty;
    $compile = sys_get_temp_dir() . '/digitsell-cards-smarty-' . getmypid();
    mkdir($compile);
    $smarty->setCompileDir($compile);
    $smarty->assign('user', new class($rows) {
        private $rows;
        public function __construct($rows) { $this->rows = $rows; }
        public function serverProfileCards($servers) { return $this->rows; }
    });
    $smarty->assign('servers', $cards);
    $smarty->assign('translate', new class { public function get($key) { return $key; } });
    $template = file_get_contents(__DIR__ . '/../patch/view/user/server/server.tpl');
    $template = preg_replace('~\{include file=\x27user/layout/(header|footer)\.tpl\x27\}~', '', $template);
    $html = $smarty->fetch('string:' . $template);
    check(substr_count($html, 'srv-qr-open"') === 3, 'real Smarty page renders one QR action for each expanded card');
    check(strpos($html, 'First &lt;name&gt; (2052)') !== false && strpos($html,'First <name>') === false, 'profile card names are escaped');
    foreach ([$rows[0]['link'],$rows[1]['link']] as $link) {
        check(substr_count($html, htmlspecialchars($link, ENT_QUOTES, 'UTF-8')) === 2, 'QR and copy buttons use the same independent config');
    }
    foreach (glob($compile . '/*') as $file) unlink($file);
    rmdir($compile);
}
