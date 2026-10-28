<?php
declare(strict_types=1);
require_once ROOT . '/app/Patch/SubscriptionProfiles.php';
requireAdmin();
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
