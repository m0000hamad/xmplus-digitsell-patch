<?php
declare(strict_types=1);
require_once ROOT . '/app/Patch/SubscriptionProfiles.php';
requireAdmin();
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
        db()->beginTransaction();
        try {
            putSetting($key, json_encode($domains, JSON_UNESCAPED_UNICODE));
            putSetting('server_profile_names_' . $id, json_encode($names, JSON_UNESCAPED_UNICODE));
            db()->commit();
        } catch (Throwable $e) { db()->rollBack(); fail('ذخیره انجام نشد.'); }
        done(['saved' => true]);
    }
    $domains = json_decode((string) setting($key, '{}'), true);
    $names = json_decode((string) setting('server_profile_names_' . $id, '{}'), true);
    done(['domains' => is_array($domains) ? $domains : new stdClass(),
        'names' => is_array($names) ? $names : new stdClass(),
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
    db()->beginTransaction();
    try {
        if (!setting('sub_profiles_secret', '')) putSetting('sub_profiles_secret', bin2hex(random_bytes(32)));
        putSetting('sub_profiles', json_encode($profiles, JSON_UNESCAPED_UNICODE));
        db()->commit();
    } catch (Throwable $e) { db()->rollBack(); fail('ذخیره انجام نشد.'); }
    done(['saved' => true]);
}
if ($action !== 'subprofiles.get') fail('عملیات معتبر نیست.');
done(['profiles' => SubscriptionProfiles::read((string) setting('sub_profiles', '[]')),
    'groups' => db()->query('SELECT id,name FROM `group` ORDER BY id')->fetchAll(),
    'servers' => db()->query('SELECT id,name FROM servers ORDER BY sort,id')->fetchAll(),
    'token' => ($_SESSION['patch_csrf'] ?? ($_SESSION['patch_csrf'] = bin2hex(random_bytes(24))))]);
