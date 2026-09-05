{include file='user/layout/header.tpl'}

{literal}
<style>
/* ------------------------------------------------------------------ *
 * Servers page. The old card hid both actions: the QR only opened if
 * you happened to click the server name, and copying was a bare icon.
 * Both are real buttons now.
 * ------------------------------------------------------------------ */
.srv-head {
	border: 0;
	padding: 0;
	margin-bottom: 18px;
}
.srv-head-inner {
	border-radius: 20px;
	padding: 20px 22px;
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
	color: #fff;
	box-shadow: 0 14px 34px rgba(79, 70, 229, .3);
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 14px;
}
.srv-head-title {
	font-size: 20px;
	font-weight: 800;
	margin: 0 0 5px;
	color: #fff;
	display: flex;
	align-items: center;
	gap: 9px;
}
.srv-head-sub {
	font-size: 12.5px;
	font-weight: 500;
	margin: 0;
	color: rgba(255, 255, 255, .86);
	max-width: 560px;
	line-height: 1.75;
}
.srv-head-count {
	display: flex;
	align-items: center;
	gap: 7px;
	background: rgba(255, 255, 255, .17);
	border: 1px solid rgba(255, 255, 255, .28);
	border-radius: 999px;
	padding: 8px 15px;
	font-size: 13px;
	font-weight: 800;
	white-space: nowrap;
}
.srv-head-count .srv-dot { background: #4ade80; box-shadow: 0 0 0 3px rgba(74, 222, 128, .3); }

/* ---- search ---- */
.srv-search-wrap { margin-bottom: 16px; }
.srv-search {
	width: 100%;
	max-width: 340px;
	border: 1.5px solid rgba(23, 32, 61, .12);
	border-radius: 14px;
	padding: 10px 14px;
	font-size: 13px;
	font-weight: 600;
	color: #16203d;
	background: #fff;
	outline: none;
	transition: border-color .15s ease, box-shadow .15s ease;
}
.srv-search:focus {
	border-color: #6366f1;
	box-shadow: 0 0 0 4px rgba(99, 102, 241, .13);
}

/* ---- card ---- */
.srv-card {
	--srv: #8b5cf6;
	--srv-soft: rgba(139, 92, 246, .11);
	position: relative;
	height: 100%;
	border-radius: 18px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .09);
	padding: 16px 15px 15px;
	overflow: hidden;
	transition: transform .16s ease, box-shadow .16s ease, border-color .16s ease;
}
.srv-card::before {
	content: "";
	position: absolute;
	top: 0;
	inset-inline: 0;
	height: 4px;
	background: var(--srv);
}
.srv-card:hover {
	transform: translateY(-3px);
	border-color: var(--srv);
	box-shadow: 0 12px 28px rgba(23, 32, 61, .11);
}
.srv-tj { --srv: #f43f5e; --srv-soft: rgba(244, 63, 94, .11); }
.srv-vm { --srv: #6366f1; --srv-soft: rgba(99, 102, 241, .11); }
.srv-vl { --srv: #0ea5e9; --srv-soft: rgba(14, 165, 233, .11); }
.srv-ss { --srv: #f59e0b; --srv-soft: rgba(245, 158, 11, .11); }

.srv-top {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 11px;
}
.srv-flag {
	width: 30px;
	height: 30px;
	border-radius: 50%;
	overflow: hidden;
	flex: 0 0 auto;
	box-shadow: 0 2px 7px rgba(23, 32, 61, .16);
}
.srv-flag img { width: 100%; height: 100%; object-fit: cover; display: block; }
.srv-proto {
	font-size: 11px;
	font-weight: 800;
	letter-spacing: .4px;
	color: var(--srv);
	background: var(--srv-soft);
	border-radius: 8px;
	padding: 3px 8px;
	flex: 0 0 auto;
}
.srv-status {
	margin-inline-start: auto;
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 10.5px;
	font-weight: 700;
	padding: 3px 9px;
	border-radius: 999px;
	white-space: nowrap;
}
.srv-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	display: inline-block;
	flex: 0 0 auto;
}
.srv-on   { color: #047857; background: rgba(16, 185, 129, .13); }
.srv-on   .srv-dot { background: #10b981; box-shadow: 0 0 0 3px rgba(16, 185, 129, .22); }
.srv-idle { color: #b45309; background: rgba(245, 158, 11, .14); }
.srv-idle .srv-dot { background: #f59e0b; }
.srv-off  { color: #b91c1c; background: rgba(239, 68, 68, .13); }
.srv-off  .srv-dot { background: #ef4444; }

.srv-name {
	font-size: 14.5px;
	font-weight: 800;
	color: #16203d;
	margin-bottom: 14px;
	line-height: 1.5;
	word-break: break-word;
}

/* ---- actions ---- */
.srv-actions { display: flex; gap: 8px; }
.srv-btn {
	flex: 1 1 0;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	min-height: 40px;
	padding: 9px 10px;
	border: 0;
	border-radius: 13px;
	font-size: 12.5px;
	font-weight: 700;
	cursor: pointer;
	white-space: nowrap;
	transition: transform .14s ease, box-shadow .14s ease, background .14s ease;
}
.srv-btn:active { transform: scale(.97); }
.srv-btn-emoji { font-size: 15px; line-height: 1; }
.srv-btn-qr {
	color: #fff;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 5px 14px rgba(99, 102, 241, .34);
}
.srv-btn-qr:hover { box-shadow: 0 8px 20px rgba(99, 102, 241, .45); }
.srv-btn-copy {
	color: #047857;
	background: rgba(16, 185, 129, .13);
	border: 1.5px solid rgba(16, 185, 129, .35);
}
.srv-btn-copy:hover { background: rgba(16, 185, 129, .2); }

/* ---- empty states ---- */
.srv-empty {
	border-radius: 18px;
	border: 1.5px dashed rgba(99, 102, 241, .32);
	background: linear-gradient(135deg, rgba(99, 102, 241, .07), rgba(139, 92, 246, .07));
	padding: 34px 20px;
	text-align: center;
	color: #56617a;
	font-size: 13.5px;
	font-weight: 600;
}
.srv-empty-emoji { font-size: 34px; display: block; margin-bottom: 9px; }

/* ---- modal ---- */
.srv-modal {
	border: 0;
	border-radius: 20px;
	overflow: hidden;
	box-shadow: 0 24px 60px rgba(23, 32, 61, .28);
}
.srv-modal-head {
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	color: #fff;
	padding: 17px 20px;
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	gap: 12px;
}
.srv-modal-title { font-size: 16px; font-weight: 800; margin: 0; word-break: break-word; }
.srv-modal-sub { font-size: 11.5px; font-weight: 600; color: rgba(255, 255, 255, .82); margin-top: 3px; }
.srv-modal-close {
	flex: 0 0 auto;
	width: 30px;
	height: 30px;
	border: 0;
	border-radius: 10px;
	background: rgba(255, 255, 255, .2);
	color: #fff;
	font-size: 16px;
	line-height: 1;
	cursor: pointer;
}
.srv-modal-close:hover { background: rgba(255, 255, 255, .32); }
.srv-modal-body { padding: 20px; }
.srv-qr-hint {
	text-align: center;
	font-size: 12.5px;
	font-weight: 700;
	color: #56617a;
	margin-bottom: 12px;
}
/* a QR needs a light ground to stay scannable, dark mode included */
.srv-qr-box {
	background: #fff;
	border-radius: 16px;
	padding: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 190px;
	box-shadow: inset 0 0 0 1.5px rgba(23, 32, 61, .1);
}
.srv-qr-box img, .srv-qr-box canvas { max-width: 100%; height: auto; display: block; }
.srv-link-label {
	font-size: 11.5px;
	font-weight: 700;
	color: #8c98ab;
	margin: 15px 0 6px;
}
.srv-link-row { display: flex; gap: 8px; flex-wrap: wrap; }
.srv-link-field {
	flex: 1 1 190px;
	min-width: 0;
	border: 1.5px solid rgba(23, 32, 61, .12);
	border-radius: 13px;
	padding: 10px 12px;
	font-size: 12px;
	font-family: monospace;
	direction: ltr;
	text-align: left;
	color: #16203d;
	background: rgba(23, 32, 61, .04);
	cursor: pointer;
}
.srv-link-row .srv-btn { flex: 0 0 auto; min-width: 118px; }

/* ---- dark ---- */
html[data-hs-theme="dark"] .srv-card {
	background: #1c2536;
	border-color: rgba(255, 255, 255, .09);
}
html[data-hs-theme="dark"] .srv-card:hover { box-shadow: 0 12px 28px rgba(0, 0, 0, .45); }
html[data-hs-theme="dark"] .srv-name { color: #e7eaf3; }
html[data-hs-theme="dark"] .srv-search {
	background: #1c2536;
	border-color: rgba(255, 255, 255, .12);
	color: #e7eaf3;
}
html[data-hs-theme="dark"] .srv-on   { color: #6ee7b7; background: rgba(16, 185, 129, .18); }
html[data-hs-theme="dark"] .srv-idle { color: #fcd34d; background: rgba(245, 158, 11, .18); }
html[data-hs-theme="dark"] .srv-off  { color: #fca5a5; background: rgba(239, 68, 68, .18); }
html[data-hs-theme="dark"] .srv-btn-copy { color: #6ee7b7; }
html[data-hs-theme="dark"] .srv-empty { color: #b9c2d4; }
html[data-hs-theme="dark"] .srv-modal { background: #1c2536; }
html[data-hs-theme="dark"] .srv-modal-body { background: #1c2536; }
html[data-hs-theme="dark"] .srv-qr-hint { color: #b9c2d4; }
html[data-hs-theme="dark"] .srv-link-field {
	background: rgba(255, 255, 255, .06);
	border-color: rgba(255, 255, 255, .12);
	color: #e7eaf3;
}

/* ---- small screens ---- */
@media (max-width: 575.98px) {
	.srv-head-inner { padding: 17px; }
	.srv-head-title { font-size: 17.5px; }
	.srv-btn { font-size: 12px; min-height: 42px; }
	.srv-link-row .srv-btn { flex: 1 1 100%; }
}
</style>
{/literal}

	<div class="page-header srv-head">
		<div class="srv-head-inner">
			<div>
				<h1 class="srv-head-title">🌍 {$translate->get('Servers')}</h1>
				<p class="srv-head-sub">{$translate->get('ServersSubtitle')}</p>
			</div>
			<div class="srv-head-count">
				<i class="srv-dot"></i>
				<span id="srvOnlineCount">0</span> {$translate->get('ServersOnlineCount')}
			</div>
		</div>
	</div>

	<div class="srv-search-wrap" id="srvSearchWrap" hidden>
		<input type="text" class="srv-search" id="srvSearch" placeholder="{$translate->get('SearchServer')}" autocomplete="off">
	</div>

	<div class="row" id="srvGrid">
		{foreach $servers as $server}
			{if $server['server'] == "Trojan"}
				{assign var="srvTag" value="TJ"}{assign var="srvHue" value="srv-tj"}
			{elseif $server['server'] == "Vmess"}
				{assign var="srvTag" value="VM"}{assign var="srvHue" value="srv-vm"}
			{elseif $server['server'] == "Vless"}
				{assign var="srvTag" value="VL"}{assign var="srvHue" value="srv-vl"}
			{elseif $server['server'] == "Shadowsocks"}
				{assign var="srvTag" value="SS"}{assign var="srvHue" value="srv-ss"}
			{else}
				{assign var="srvTag" value="--"}{assign var="srvHue" value=""}
			{/if}

			<div class="col-sm-12 col-md-6 col-lg-4 col-xl-3 mb-3 mb-lg-4 srv-col" data-name="{$server['name']|escape:'html'} {$srvTag}">
				<div class="srv-card {$srvHue}">
					<div class="srv-top">
						<span class="srv-flag">
							<img src="/assets/vendor/flag-icon-css/flags/1x1/{$server['info']|lower}.svg" alt="">
						</span>
						<span class="srv-proto">{$srvTag}</span>
						{if $server['online'] == 1}
							<span class="srv-status srv-on"><i class="srv-dot"></i>{$translate->get('SrvStatusOn')}</span>
						{elseif $server['online'] == 0}
							<span class="srv-status srv-idle"><i class="srv-dot"></i>{$translate->get('ServerIdle')}</span>
						{else}
							<span class="srv-status srv-off"><i class="srv-dot"></i>{$translate->get('SrvStatusOff')}</span>
						{/if}
					</div>

					<div class="srv-name">{$server['name']|escape:'html'}</div>

					<div class="srv-actions">
						<button type="button" class="srv-btn srv-btn-qr srv-qr-open"
							data-id="{$server['id']|escape:'html'}"
							data-name="{$server['name']|escape:'html'}"
							data-link="{$server['link']|escape:'html'}">
							<span class="srv-btn-emoji">📱</span>{$translate->get('ShowQR')}
						</button>
						<button type="button" class="srv-btn srv-btn-copy copy-text"
							data-clipboard-text="{$server['link']|escape:'html'}">
							<span class="srv-btn-emoji">📋</span>{$translate->get('CopyConfig')}
						</button>
					</div>
				</div>
			</div>
		{foreachelse}
			<div class="col-12">
				<div class="srv-empty">
					<span class="srv-empty-emoji">🛰️</span>
					{$translate->get('NoServers')}
				</div>
			</div>
		{/foreach}
	</div>

	<div id="srvNoMatch" hidden>
		<div class="srv-empty">
			<span class="srv-empty-emoji">🔍</span>
			{$translate->get('NoServerFound')}
		</div>
	</div>

	<div class="modal fade" id="server-info" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="serverModalLabel" aria-hidden="true">
		<div class="modal-dialog modal-dialog-centered" role="document">
			<div class="modal-content srv-modal">
				<div class="srv-modal-head">
					<div>
						<div class="srv-modal-title" id="name"></div>
						<div class="srv-modal-sub" id="type"></div>
					</div>
					<button type="button" class="srv-modal-close" data-bs-dismiss="modal" aria-label="Close">&times;</button>
				</div>
				<div class="srv-modal-body">
					<div class="srv-qr-hint">📷 {$translate->get('ScanToConnect')}</div>
					<div class="srv-qr-box" id="qrcode"></div>

					<div class="srv-link-label">{$translate->get('SrvConfigLink')}</div>
					<div class="srv-link-row">
						<input type="text" class="srv-link-field copy-text" id="srvLink" readonly>
						<button type="button" class="srv-btn srv-btn-copy" id="srvCopyBtn">
							<span class="srv-btn-emoji">📋</span>{$translate->get('CopyConfig')}
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>

{include file='user/layout/footer.tpl'}

<script>
	window.SrvSearchLabel = "{$translate->get('SearchServer')|escape:'javascript'}";
</script>

{literal}
<script>
(function () {
	var grid = document.getElementById('srvGrid');
	if (!grid) { return; }

	var cards = grid.querySelectorAll('.srv-col');
	var noMatch = document.getElementById('srvNoMatch');
	var linkField = document.getElementById('srvLink');
	var currentLink = '';

	/* the header badge counts what the cards already show */
	var online = grid.querySelectorAll('.srv-status.srv-on').length;
	var counter = document.getElementById('srvOnlineCount');
	if (counter) { counter.textContent = online; }

	/* searching only earns its place once the list is long */
	var searchWrap = document.getElementById('srvSearchWrap');
	var search = document.getElementById('srvSearch');
	if (searchWrap && cards.length > 6) {
		searchWrap.hidden = false;
		search.addEventListener('input', function () {
			var needle = search.value.trim().toLowerCase();
			var shown = 0;
			for (var i = 0; i < cards.length; i++) {
				var hay = (cards[i].getAttribute('data-name') || '').toLowerCase();
				var hit = needle === '' || hay.indexOf(needle) !== -1;
				cards[i].hidden = !hit;
				if (hit) { shown++; }
			}
			if (noMatch) { noMatch.hidden = shown !== 0; }
		});
	}

	function openQr(button) {
		var id = button.getAttribute('data-id');
		currentLink = button.getAttribute('data-link') || '';

		if (linkField) { linkField.value = currentLink; }
		document.getElementById('name').textContent = button.getAttribute('data-name') || '';
		document.getElementById('type').textContent = '';
		document.getElementById('qrcode').innerHTML = '';

		layer.load(2);
		$.ajax({
			type: 'POST',
			url: '/portal/server/' + id,
			dataType: 'json',
			data: { id: id },
			success: function (data) {
				layer.closeAll('loading');
				if (data.ret) {
					document.getElementById('type').textContent = data.type;
					document.getElementById('name').textContent = data.name;
					document.getElementById('qrcode').innerHTML = data.qrcode;
					$('#server-info').modal('show');
				}
			},
			error: function (jqXHR) {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText);
			}
		});
	}

	grid.addEventListener('click', function (event) {
		var button = event.target.closest('.srv-qr-open');
		if (button) { openQr(button); }
	});

	var copyBtn = document.getElementById('srvCopyBtn');
	if (copyBtn) {
		copyBtn.addEventListener('click', function () {
			window.CopyText.copy(currentLink, copyBtn);
		});
	}
})();
</script>
{/literal}
