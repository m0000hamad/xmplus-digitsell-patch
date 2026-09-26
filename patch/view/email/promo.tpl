{*
  E-mail for promotion events (a promoted purchase, a prize won), queued by
  app/Jobs/PromoJob.php through the panel's mail queue like UserJob's notices.
  Variables: $username, $title, $lines (plain-text lines, already in Persian).

  NOTE: this must sit in the same folder as the panel's stock expired.tpl /
  dataused.tpl. If the queue reads them from elsewhere, move this file there
  (or set the `promo_mail_template` setting to a path it can reach).
*}
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head><meta charset="utf-8"><title>{$title|escape:'html'}</title></head>
<body style="margin:0;padding:24px;background:#f4f5fb;font-family:Tahoma,Arial,sans-serif;">
	<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;background:#ffffff;border-radius:16px;overflow:hidden;">
		<tr>
			<td style="padding:20px 24px;background:linear-gradient(135deg,#ff3d6e,#7c3aed);color:#ffffff;font-size:18px;font-weight:bold;">
				{$title|escape:'html'}
			</td>
		</tr>
		<tr>
			<td style="padding:22px 24px;color:#1f2a44;font-size:14px;line-height:2;" dir="rtl">
				<p style="margin:0 0 10px;">{$username|escape:'html'} عزیز،</p>
				{foreach $lines as $line}
					<p style="margin:0 0 6px;">{$line|escape:'html'}</p>
				{/foreach}
			</td>
		</tr>
	</table>
</body>
</html>
