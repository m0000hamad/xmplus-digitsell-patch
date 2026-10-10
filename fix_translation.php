<?php
/**
 * Fix missing TorExitNotSupported translation key in localization files.
 * Run: php /www/wwwroot/p.digitsell-shop.ir/fix_translation.php
 */

$files = [
    '/www/wwwroot/p.digitsell-shop.ir/patch/localization/fa_IR.php',
    '/www/wwwroot/p.digitsell-shop.ir/patch/localization/en_US.php',
    '/www/wwwroot/p.digitsell-shop.ir/patch/localization/zh_CN.php',
];

$translations = [
    'fa_IR' => "'TorExitNotSupported'       => \"لوکیشن خروجی Tor برای این نوع سرور پشتیبانی نمی‌شود (فقط سرورهای Xray پشتیبانی می‌شوند)\",",
    'en_US' => "'TorExitNotSupported'       => \"Tor exit location is not supported for this server type (only Xray servers are supported)\",",
    'zh_CN' => "'TorExitNotSupported'       => \"此服务器类型不支持Tor出口位置（仅支持Xray服务器）\",",
];

foreach ($files as $file) {
    $lang = basename($file, '.php');
    if (!file_exists($file)) {
        echo "SKIP (not found): $file\n";
        continue;
    }
    
    $content = file_get_contents($file);
    if (strpos($content, 'TorExitNotSupported') !== false) {
        echo "OK (key exists): $file\n";
        continue;
    }
    
    $translation = $translations[$lang] ?? $translations['en_US'];
    
    // Find the last translation entry and add after it
    $lines = explode("\n", $content);
    $inserted = false;
    for ($i = count($lines) - 1; $i >= 0; $i--) {
        if (preg_match("/^\s*'[^']+'\s*=>/", $lines[$i])) {
            // Insert after this line
            array_splice($lines, $i + 1, 0, ["\t" . $translation]);
            $inserted = true;
            break;
        }
    }
    
    if ($inserted) {
        file_put_contents($file, implode("\n", $lines));
        echo "FIXED (key added): $file\n";
    } else {
        echo "ERROR (could not find insertion point): $file\n";
    }
}

echo "\nDone. Now clear cache:\n";
echo "rm -rf /www/wwwroot/p.digitsell-shop.ir/storage/smarty/compile/*\n";
echo "rm -rf /www/wwwroot/p.digitsell-shop.ir/storage/smarty/cache/*\n";
