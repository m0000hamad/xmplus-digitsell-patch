<!doctype html>
<html lang="fa" dir="rtl">
<head><meta charset="utf-8"><title>{$title|escape:'html'}</title></head>
<body style="font-family:Tahoma,Arial,sans-serif;background:#f4f5fb;padding:24px;line-height:2">
 <div style="max-width:560px;margin:auto;background:white;padding:24px;border-radius:16px">
  <h1 style="font-size:20px">{$title|escape:'html'}</h1>
  <p>{$username|escape:'html'} عزیز،</p>
  {foreach $lines as $line}<p>{$line|escape:'html'}</p>{/foreach}
  <a href="{$invoice_url|escape:'html'}" style="display:inline-block;background:#4f46e5;color:white;padding:10px 20px;border-radius:10px;text-decoration:none">مشاهده و پرداخت فاکتور</a>
 </div>
</body>
</html>
