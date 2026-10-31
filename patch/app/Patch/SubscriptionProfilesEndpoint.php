<?php
declare(strict_types=1);
require_once ROOT . '/app/Patch/SubscriptionProfiles.php';
requireAdmin();
if(strpos($action,'subprofiles.inforows.')===0){require __DIR__.'/SubInfoRowsEndpoint.php';exit;}
if ($action === 'subprofiles.online') {
    $split = [];
    foreach (db()->query("SELECT name,value FROM settings WHERE name LIKE 'server_profile_billing_%'") as $setting) {
        if (preg_match('/^server_profile_billing_([1-9][0-9]*)$/D', $setting['name'], $match)
            && !empty(json_decode($setting['value'], true)['enabled'])) $split[] = (int) $match[1];
    }
    $nodes = [];
    foreach (db()->query('SELECT serverid,profile1,profile2,unclassified,ready,datetime FROM node_profile_online') as $row) {
        $nodes[(int) $row['serverid']] = ['counts' => [(int) $row['profile1'], (int) $row['profile2']],
            'unclassified' => (int) $row['unclassified'], 'ready' => (bool) $row['ready'], 'at' => (int) $row['datetime']];
    }
    $profiles = SubscriptionProfiles::read((string) setting('sub_profiles', '[]'));
    done(['nodes' => (object) $nodes, 'split' => $split, 'titles' => array_map(static function ($slot) use ($profiles) {
        return (string) ($profiles[$slot - 1]['name'] ?? ('لینک ' . $slot));
    }, [1, 2]), 'now' => time()]);
}
if (in_array($action, ['subprofiles.domains.get', 'subprofiles.domains.save'], true)) {
    $saving = $action === 'subprofiles.domains.save';
    if ($saving) {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') fail('POST required', 405);
        requireToken();
    }
    $id = filter_var(($saving ? $_POST : $_GET)['server_id'] ?? '', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if (!$id) fail('سرور معتبر نیست.');
    $query = db()->prepare('SELECT id FROM servers WHERE id=?');
    $query->execute([$id]);
    if (!$query->fetchColumn()) fail('سرور پیدا نشد.', 404);
    $key = 'server_profile_domains_' . $id;
    if ($saving) {
        $domains = json_decode((string) ($_POST['domains'] ?? ''), true);
        if (!is_array($domains) || count($domains) !== 2 || !array_key_exists(1, $domains) || !array_key_exists(2, $domains)) fail('دامنه‌های هر دو لینک لازم است.');
        foreach ($domains as &$domain) {
            if (!is_string($domain)) fail('دامنه معتبر نیست.');
            $domain = strtolower(rtrim(trim($domain), '.'));
            if ($domain !== '' && (strlen($domain) > 253 || strpos($domain, '.') === false
                || !filter_var($domain, FILTER_VALIDATE_DOMAIN, FILTER_FLAG_HOSTNAME))) fail('فقط نام دامنه وارد کنید؛ بدون https، پورت یا مسیر.');
        }
        unset($domain);
        $names = json_decode((string) ($_POST['names'] ?? '{"1":"","2":""}'), true);
        if (!is_array($names) || count($names) !== 2 || !array_key_exists(1, $names) || !array_key_exists(2, $names)) fail('نام‌های هر دو لینک لازم است.');
        foreach ($names as &$name) {
            if (!is_string($name)) fail('نام سرور معتبر نیست.');
            $name = trim($name);
            if (strlen($name) > 240 || !preg_match('//u', $name) || preg_match('/[\x00-\x1F\x7F]/', $name)) fail('نام سرور معتبر نیست یا بیش از حد طولانی است.');
        }
        unset($name);
        $billing = null;
        if (isset($_POST['billing'])) {
            require_once __DIR__ . '/ProfileBilling.php';
            $value = json_decode((string) $_POST['billing'], true);
            if (!is_array($value)) fail('تنظیمات پورت و ضریب معتبر نیست.');
            try { $billing = ProfileBilling::normalize($value); }
            catch (InvalidArgumentException $error) { fail($error->getMessage()); }
            if ($billing['enabled']) {
                $agent = ProfileBilling::read((string) setting('profile_agent_' . $id, '{}'));
                if (($agent['capability'] ?? '') !== 'profile-billing-v1' || (int) ($agent['at'] ?? 0) < time() - 180)
                    fail('ابتدا عامل Xray این سرور را به نسخه ۱.۴.۰ به‌روزرسانی کنید و تا اتصال آن به پنل صبر کنید.');
                if (array_intersect($billing['ports'], $agent['reserved_ports'] ?? [])) fail('یکی از پورت‌ها در همین عامل برای نود دیگر یا API رزرو شده است.');
            }
        }
        db()->beginTransaction();
        try {
            putSetting($key, json_encode($domains, JSON_UNESCAPED_UNICODE));
            putSetting('server_profile_names_' . $id, json_encode($names, JSON_UNESCAPED_UNICODE));
            if ($billing !== null) {
                putSetting('server_profile_billing_' . $id, json_encode($billing));
                if ($billing['enabled']) putSetting('server_profile_billing_history_' . $id . '_' . $billing['revision'], json_encode($billing));
            }
            db()->commit();
        } catch (Throwable $e) { db()->rollBack(); fail('ذخیره انجام نشد.'); }
        done(['saved' => true]);
    }
    $domains = json_decode((string) setting($key, '{}'), true);
    $names = json_decode((string) setting('server_profile_names_' . $id, '{}'), true);
    done(['domains' => is_array($domains) ? $domains : new stdClass(),
        'names' => is_array($names) ? $names : new stdClass(),
        'billing' => json_decode((string) setting('server_profile_billing_' . $id, '{}')) ?: new stdClass(),
        'agent' => json_decode((string) setting('profile_agent_' . $id, '{}')) ?: new stdClass(),
        'profiles' => SubscriptionProfiles::read((string) setting('sub_profiles', '[]')),
        'token' => ($_SESSION['patch_csrf'] ?? ($_SESSION['patch_csrf'] = bin2hex(random_bytes(24))))]);
}
if ($action === 'subprofiles.save') {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') fail('POST required', 405);
    requireToken();
    $profiles = SubscriptionProfiles::read((string) ($_POST['profiles'] ?? ''));
    if (!$profiles) fail('دو لینک باید تعریف شوند.');
    $groups = array_map('intval', db()->query('SELECT id FROM `group`')->fetchAll(PDO::FETCH_COLUMN));
    $servers = array_map('intval', db()->query('SELECT id FROM servers')->fetchAll(PDO::FETCH_COLUMN));
    foreach ($profiles as &$profile) {
        if (!is_array($profile)) fail('تنظیمات لینک معتبر نیست.');
        $profile = ['name' => trim((string) ($profile['name'] ?? '')), 'enabled' => !empty($profile['enabled']), 'description' => trim((string) ($profile['description'] ?? '')),
            'groups' => array_values(array_unique(array_map('intval', (array) ($profile['groups'] ?? [])))),
            'servers' => array_values(array_unique(array_map('intval', (array) ($profile['servers'] ?? []))))];
        if (strlen($profile['description']) > 4000) fail('توضیحات بیش از حد طولانی است.');
        if ($profile['name'] === '' || strlen($profile['name']) > 160) fail('نام لینک معتبر نیست.');
        if (array_diff($profile['groups'], $groups) || array_diff($profile['servers'], $servers)) fail('گروه یا سرور انتخابی معتبر نیست.');
        if ($profile['enabled'] && (!$profile['groups'] || !$profile['servers'])) fail('برای لینک فعال، گروه کاربران و سرور انتخاب کنید.');
    }
    unset($profile);
    $combined = null;
    if (isset($_POST['combined'])) {
        $value = json_decode((string) $_POST['combined'], true);
        if (!is_array($value) || !isset($value['name'], $value['description'])
            || !is_string($value['name']) || !is_string($value['description'])) fail('تنظیمات لینک ترکیبی معتبر نیست.');
        $combined = SubscriptionProfiles::combined((string) $_POST['combined']);
        $combined['name'] = trim($combined['name']);
        $combined['description'] = trim($combined['description']);
        if ($combined['name'] === '' || strlen($combined['name']) > 160 || strlen($combined['description']) > 4000
            || !preg_match('//u', $combined['name'] . $combined['description'])) fail('عنوان یا توضیحات لینک ترکیبی معتبر نیست.');
    }
    db()->beginTransaction();
    try {
        if (!setting('sub_profiles_secret', '')) putSetting('sub_profiles_secret', bin2hex(random_bytes(32)));
        putSetting('sub_profiles', json_encode($profiles, JSON_UNESCAPED_UNICODE));
        if ($combined !== null) putSetting('sub_profiles_combined', json_encode($combined, JSON_UNESCAPED_UNICODE));
        db()->commit();
    } catch (Throwable $e) { db()->rollBack(); fail('ذخیره انجام نشد.'); }
    done(['saved' => true]);
}
if ($action !== 'subprofiles.get') fail('عملیات معتبر نیست.');
done(['profiles' => SubscriptionProfiles::read((string) setting('sub_profiles', '[]')),
    'combined' => SubscriptionProfiles::combined((string) setting('sub_profiles_combined', '{}')),
    'groups' => db()->query('SELECT id,name FROM `group` ORDER BY id')->fetchAll(),
    'servers' => db()->query('SELECT id,name FROM servers ORDER BY sort,id')->fetchAll(),
    'token' => ($_SESSION['patch_csrf'] ?? ($_SESSION['patch_csrf'] = bin2hex(random_bytes(24))))]);
