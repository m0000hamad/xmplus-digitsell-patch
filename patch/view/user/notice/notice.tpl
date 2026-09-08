{include file='user/layout/header.tpl'}

{literal}
<style>
/* ================================================================== *
 * Notices timeline.
 *
 * The stock page was a grey pseudo-step rail that printed a date and a
 * blob of text and never showed notice.title even though it is filled.
 * It is now a stack of cards, each with a coloured spine, the title in
 * full, a date pill, a "new" flag on anything from the last three days,
 * and the panel's dark theme followed. The rail styling the old markup
 * needed for RTL is gone with it.
 * ================================================================== */
.ntc-hero {
	position: relative;
	border-radius: 20px;
	padding: 22px 24px;
	margin-bottom: 22px;
	overflow: hidden;
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
	color: #fff;
	box-shadow: 0 14px 34px rgba(79, 70, 229, .3);
}
.ntc-hero h1 {
	font-size: 21px;
	font-weight: 800;
	margin: 0 0 6px;
	color: #fff;
	display: flex;
	align-items: center;
	gap: 10px;
}
.ntc-hero p {
	font-size: 12.5px;
	font-weight: 500;
	margin: 0;
	color: rgba(255, 255, 255, .88);
	line-height: 1.8;
}

.ntc-list { display: grid; gap: 14px; }

.ntc-card {
	--nc: #6366f1;
	--nc-soft: rgba(99, 102, 241, .12);
	position: relative;
	border-radius: 16px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .09);
	padding: 16px 18px 16px 20px;
	overflow: hidden;
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
}
.ntc-card::before {
	content: "";
	position: absolute;
	inset-block: 0;
	inset-inline-start: 0;
	width: 4px;
	background: var(--nc);
}
/* a colour per card, cycled so a long list still reads as a list */
.ntc-card:nth-child(5n+1) { --nc: #6366f1; --nc-soft: rgba(99, 102, 241, .12); }
.ntc-card:nth-child(5n+2) { --nc: #0ea5e9; --nc-soft: rgba(14, 165, 233, .12); }
.ntc-card:nth-child(5n+3) { --nc: #10b981; --nc-soft: rgba(16, 185, 129, .12); }
.ntc-card:nth-child(5n+4) { --nc: #f59e0b; --nc-soft: rgba(245, 158, 11, .13); }
.ntc-card:nth-child(5n+5) { --nc: #ec4899; --nc-soft: rgba(236, 72, 153, .12); }

.ntc-top {
	display: flex;
	align-items: center;
	gap: 8px;
	flex-wrap: wrap;
	margin-bottom: 9px;
}
.ntc-date {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	font-size: 11px;
	font-weight: 800;
	color: var(--nc);
	background: var(--nc-soft);
	border-radius: 999px;
	padding: 4px 11px;
	direction: ltr;
	unicode-bidi: isolate;
}
.ntc-new {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 10px;
	font-weight: 800;
	letter-spacing: .3px;
	color: #b91c1c;
	background: rgba(239, 68, 68, .13);
	border-radius: 999px;
	padding: 4px 10px;
}
.ntc-title {
	font-size: 15px;
	font-weight: 800;
	color: #16203d;
	margin: 0 0 6px;
	line-height: 1.6;
}
.ntc-body {
	font-size: 13.5px;
	font-weight: 500;
	color: #3f4a63;
	line-height: 2;
	word-break: break-word;
}
.ntc-body p:last-child { margin-bottom: 0; }
.ntc-body img { max-width: 100%; height: auto; border-radius: 10px; }
.ntc-body a { color: var(--nc); font-weight: 700; }

.ntc-empty {
	border-radius: 18px;
	border: 1.5px dashed rgba(99, 102, 241, .32);
	background: linear-gradient(135deg, rgba(99, 102, 241, .07), rgba(139, 92, 246, .07));
	padding: 40px 20px;
	text-align: center;
	color: #56617a;
	font-size: 13.5px;
	font-weight: 600;
}
.ntc-empty-emoji { font-size: 36px; display: block; margin-bottom: 10px; }

html[data-hs-theme="dark"] .ntc-card {
	background: #1c2536;
	border-color: rgba(255, 255, 255, .09);
	box-shadow: 0 10px 26px rgba(0, 0, 0, .4);
}
html[data-hs-theme="dark"] .ntc-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .ntc-body { color: #b9c2d4; }
html[data-hs-theme="dark"] .ntc-new { color: #fca5a5; background: rgba(239, 68, 68, .18); }
html[data-hs-theme="dark"] .ntc-empty { color: #b9c2d4; }

@media (max-width: 575.98px) {
	.ntc-hero { padding: 18px; }
	.ntc-hero h1 { font-size: 18px; }
	.ntc-card { padding: 14px 15px 14px 17px; }
}
</style>
{/literal}

<div class="page-header ntc-hero">
	<h1>📢 {$translate->get('Notices')}</h1>
	<p>{str_replace(['%appName%'],[$Config['appName']],$translate->get('NoticeList'))}</p>
</div>

<div class="ntc-list">
	{foreach $anns as $ann}
		<div class="ntc-card">
			<div class="ntc-top">
				<span class="ntc-date">🕒 {date('Y-m-d H:i', $ann->updated_at)}</span>
				{if ($smarty.now - $ann->updated_at) < 259200}
					<span class="ntc-new">● {$translate->get('NoticeNew')}</span>
				{/if}
			</div>
			{if isset($ann->title) && $ann->title}
				<h5 class="ntc-title">{$ann->title|escape:'html'}</h5>
			{/if}
			<div class="ntc-body">{$ann->content}</div>
		</div>
	{foreachelse}
		<div class="ntc-empty">
			<span class="ntc-empty-emoji">🗒️</span>
			{$translate->get('NoticeEmpty')}
		</div>
	{/foreach}
</div>

{include file='user/layout/footer.tpl'}
