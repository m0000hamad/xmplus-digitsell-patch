<?php
/** Standalone model/save allowlist regression checks; no database needed. */
declare(strict_types=1);
namespace App\Http\Models { class Model {} }
namespace {
require __DIR__.'/../patch/app/Http/Models/Package.php';
function fail($message, $code = 400): void { throw new RuntimeException($message); }
try { require __DIR__.'/../patch/app/Patch/Promo.php'; }
catch (RuntimeException $e) { if ($e->getMessage() !== 'unknown promotion action') throw $e; }
$keys = ['attar','saadi','ferdowsi','khayyam','avicenna','razi','rumi','hafez','cyrus',
    'rainy','autumn_rain','walking','winter_snow','rainbow'];
$model = App\Http\Models\Package::class;
foreach ($keys as $key) {
    if (!in_array($key, PROMO_THEMES, true) || $model::promoTheme(['theme'=>$key]) !== $key
        || empty($model::PROMO_THEMES[$key])) throw new RuntimeException('Theme cannot survive save/render: '.$key);
}
foreach (['classic','spring','summer','autumn','winter','nowruz','yalda','christmas','mother','father','girl','boy'] as $key) {
    if ($model::promoTheme(['theme'=>$key]) !== $key) throw new RuntimeException('Existing theme changed: '.$key);
}
if ($model::promoTheme(['theme'=>'invalid']) !== $model::promoTheme(['theme'=>'auto'])) throw new RuntimeException('Invalid theme fallback changed');
echo "PASS 14 new themes retain their identity; existing themes and automatic fallback preserved\n";
}
