<?php
namespace App\Patch;

use Illuminate\Database\Capsule\Manager as DB;

final class EmailAction
{
    public static function url(string $path): string
    {
        $base = '';
        foreach (['promo_site_url', 'c2c_site_url', 'baseUrl', 'appName'] as $name) {
            try {
                $value = trim((string) DB::table('settings')->where('name', $name)->value('value'));
            } catch (\Throwable $error) {
                $value = '';
            }
            if ($value === '') continue;
            if (preg_match('~^https?://~i', $value)) {
                $base = $value;
                break;
            }
            if (strpos($value, '.') !== false && !preg_match('~\s~', $value)) {
                $base = 'https://' . $value;
                break;
            }
        }

        if ($base === '' && !empty($_SERVER['HTTP_HOST'])) {
            $base = 'https://' . $_SERVER['HTTP_HOST'];
        }
        if ($base === '') $base = 'https://p.digitsell-shop.ir';

        return rtrim($base, '/') . '/' . ltrim($path, '/');
    }

    public static function fields(string $path, string $label): array
    {
        return ['action_url' => self::url($path), 'action_label' => $label];
    }
}
