{literal}
<style>
.app-card { border: 0; border-radius: 18px; overflow: visible; }
.app-card .card-header { background: transparent; }

/* ---- step scaffolding ---- */
.app-step { margin-bottom: 20px; }
.app-step:last-child { margin-bottom: 4px; }
.app-step-head {
	display: flex;
	align-items: center;
	gap: 9px;
	margin-bottom: 12px;
}
.app-step-num {
	flex: 0 0 auto;
	width: 26px;
	height: 26px;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	font-weight: 700;
	color: #fff;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 3px 10px rgba(99, 102, 241, .35);
}
.app-step-title {
	font-size: 14px;
	font-weight: 700;
	color: #16203d;
	margin: 0;
}
.app-step-sub {
	font-size: 11.5px;
	color: #8c98ab;
	font-weight: 500;
}

/* ---- choice grids ---- */
.app-grid {
	display: grid;
	grid-template-columns: repeat(auto-fill, minmax(146px, 1fr));
	gap: 10px;
	list-style: none;
	padding: 0;
	margin: 0;
}
.app-pick {
	display: flex !important;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 7px;
	min-height: 84px;
	padding: 12px 8px;
	border-radius: 15px;
	border: 1.5px solid rgba(23, 32, 61, .1);
	background: #fff;
	color: #16203d !important;
	font-size: 13px;
	font-weight: 600;
	text-align: center;
	cursor: pointer;
	position: relative;
	transition: border-color .16s ease, transform .16s ease, box-shadow .16s ease;
}
.app-pick:hover {
	border-color: var(--pick, #6366f1);
	transform: translateY(-2px);
	box-shadow: 0 8px 20px rgba(23, 32, 61, .08);
}
.app-pick.active {
	border-color: var(--pick, #6366f1);
	background: var(--pick-soft, rgba(99, 102, 241, .09)) !important;
	color: #16203d !important;
	box-shadow: 0 6px 18px rgba(23, 32, 61, .09);
}
.app-pick.active::after {
	content: "✓";
	position: absolute;
	top: 6px;
	inset-inline-end: 8px;
	width: 17px;
	height: 17px;
	border-radius: 50%;
	background: var(--pick, #6366f1);
	color: #fff;
	font-size: 10px;
	line-height: 17px;
	text-align: center;
	font-weight: 700;
}
.app-pick-emoji { font-size: 26px; line-height: 1; }
.app-pick-icon { font-size: 24px; color: var(--pick, #6366f1); line-height: 1; }
.app-pick-name { display: block; }
.app-here {
	position: absolute;
	top: -9px;
	inset-inline-start: 8px;
	background: #10b981;
	color: #fff;
	font-size: 9.5px;
	font-weight: 700;
	padding: 2px 7px;
	border-radius: 999px;
	white-space: nowrap;
	box-shadow: 0 3px 8px rgba(16, 185, 129, .4);
}

/* ---- the connect box ---- */
.app-connect {
	border-radius: 16px;
	padding: 15px;
	background: linear-gradient(135deg, rgba(99, 102, 241, .09), rgba(139, 92, 246, .09));
	border: 1.5px dashed rgba(99, 102, 241, .32);
}
.app-link-row { display: flex; gap: 8px; flex-wrap: wrap; }
.app-link-field {
	flex: 1 1 210px;
	min-width: 0;
	font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
	font-size: 11.5px;
	direction: ltr;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .12);
	border-radius: 11px;
	padding: 10px 12px;
	color: #3b4a6b;
	text-overflow: ellipsis;
}
.app-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 7px;
	border: 0;
	border-radius: 11px;
	padding: 10px 16px;
	font-size: 13px;
	font-weight: 700;
	line-height: 1.2;
	cursor: pointer;
	text-decoration: none !important;
	white-space: nowrap;
	transition: transform .14s ease, box-shadow .14s ease, background .14s ease;
}
.app-btn:hover { transform: translateY(-1px); }
.app-btn-copy { background: linear-gradient(135deg, #4f46e5, #7c3aed); color: #fff !important; box-shadow: 0 6px 16px rgba(99, 102, 241, .34); }
.app-btn-copy.app-done { background: linear-gradient(135deg, #059669, #10b981); box-shadow: 0 6px 16px rgba(16, 185, 129, .34); }
.app-btn-import { background: linear-gradient(135deg, #059669, #10b981); color: #fff !important; box-shadow: 0 6px 16px rgba(16, 185, 129, .3); }
.app-btn-get { background: #16203d; color: #fff !important; }
.app-btn-help { background: rgba(23, 32, 61, .07); color: #16203d !important; }
.app-actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 11px; }

/* ---- the 3 line how-to ---- */
.app-howto {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
	gap: 8px;
	margin-top: 13px;
}
.app-howto-item {
	display: flex;
	align-items: center;
	gap: 8px;
	background: rgba(255, 255, 255, .72);
	border: 1px solid rgba(23, 32, 61, .07);
	border-radius: 11px;
	padding: 9px 11px;
	font-size: 11.5px;
	font-weight: 600;
	color: #3b4a6b;
	line-height: 1.6;
}
.app-howto-emoji { font-size: 17px; flex: 0 0 auto; }

/* resetting the subscription link used to be a bare icon nobody noticed */
.app-reset {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	border: 1.5px solid rgba(245, 158, 11, .38);
	background: rgba(245, 158, 11, .1);
	color: #b45309;
	border-radius: 999px;
	padding: 7px 14px;
	font-size: 12px;
	font-weight: 700;
	line-height: 1;
	cursor: pointer;
	transition: background .15s ease, border-color .15s ease, color .15s ease;
}
.app-reset:hover {
	background: rgba(245, 158, 11, .2);
	border-color: rgba(245, 158, 11, .6);
	color: #92400e;
}
.app-reset i { transition: transform .4s ease; }
.app-reset:hover i { transform: rotate(180deg); }
html[data-hs-theme="dark"] .app-reset {
	background: rgba(245, 158, 11, .15);
	border-color: rgba(245, 158, 11, .4);
	color: #fcd34d;
}
html[data-hs-theme="dark"] .app-reset:hover { color: #fde68a; }
@media (max-width: 340px) {
	.app-reset { padding: 7px 10px; font-size: 11px; }
}

html[data-hs-theme="dark"] .app-step-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .app-pick {
	background: rgba(255, 255, 255, .04);
	border-color: rgba(255, 255, 255, .12);
	color: #e7eaf3 !important;
}
html[data-hs-theme="dark"] .app-pick.active { color: #fff !important; }
html[data-hs-theme="dark"] .app-connect {
	background: linear-gradient(135deg, rgba(99, 102, 241, .16), rgba(139, 92, 246, .16));
	border-color: rgba(139, 92, 246, .4);
}
html[data-hs-theme="dark"] .app-link-field {
	background: rgba(255, 255, 255, .06);
	border-color: rgba(255, 255, 255, .13);
	color: #cfd8ea;
}
html[data-hs-theme="dark"] .app-btn-get { background: #4f46e5; }
html[data-hs-theme="dark"] .app-btn-help { background: rgba(255, 255, 255, .1); color: #e7eaf3 !important; }
html[data-hs-theme="dark"] .app-howto-item {
	background: rgba(255, 255, 255, .05);
	border-color: rgba(255, 255, 255, .08);
	color: #b6c4dc;
}

@media (max-width: 575.98px) {
	.app-grid { grid-template-columns: repeat(auto-fill, minmax(104px, 1fr)); gap: 8px; }
	.app-pick { min-height: 76px; font-size: 12px; }
	.app-pick-emoji { font-size: 22px; }
	.app-btn { width: 100%; }
	.app-link-field { flex: 1 1 100%; }
}
</style>
{/literal}

<div class="col-lg-12 col-xl-8 col-md-12 col-sm-12 mb-4">
	<div class="card card-shadow shadow-lg rounded app-card">
		<div class="card-header card-header-content-between border-bottom">
			<h4 class="card-header-title mb-0">🚀 {$translate->get('HowTo')}</h4>
			<button type="button" class="app-reset" onClick="RsetLink()" data-bs-toggle="tooltip" data-bs-placement="bottom" title="{$translate->get('ResetSubLinkHint')}">
				<i class="fa-solid fa-repeat"></i>
				<span>{$translate->get('ResetSubLink')}</span>
			</button>
		</div>

		<div class="card-body">

			<div class="app-step">
				<div class="app-step-head">
					<span class="app-step-num">1</span>
					<div>
						<h5 class="app-step-title">{$translate->get('PickDevice')}</h5>
						<span class="app-step-sub">{$translate->get('PickDeviceHint')}</span>
					</div>
				</div>

				<ul class="nav app-grid" id="appPlatforms" role="tabpanel">
					{$t = 0}
					{$apptype = ""}
					{foreach $clients as $client_type}
					{$t = $t + 1}
						{if !in_array($client_type->type, explode(",",$apptype))}
							<li class="nav-item">
								<a class="nav-link app-pick {if $t == 1}active{/if}" data-platform="{$client_type->type}" href="#os-{$client_type->type}" data-bs-toggle="pill" role="presentation" aria-controls="os-{$client_type->type}" aria-selected="{if $t == 1}true{else}false{/if}"
									{if $client_type->type == "android"}style="--pick:#3ddc84;--pick-soft:rgba(61,220,132,.14)"
									{elseif $client_type->type == "ios"}style="--pick:#0ea5e9;--pick-soft:rgba(14,165,233,.13)"
									{elseif $client_type->type == "windows"}style="--pick:#2563eb;--pick-soft:rgba(37,99,235,.12)"
									{elseif $client_type->type == "macos"}style="--pick:#8b5cf6;--pick-soft:rgba(139,92,246,.13)"
									{elseif $client_type->type == "linux"}style="--pick:#f59e0b;--pick-soft:rgba(245,158,11,.14)"
									{else}style="--pick:#6366f1;--pick-soft:rgba(99,102,241,.12)"{/if}>
									{if $client_type->type == "android"}
										<span class="app-pick-emoji">🤖</span><span class="app-pick-name">Android</span>
									{elseif $client_type->type == "ios"}
										<span class="app-pick-emoji">📱</span><span class="app-pick-name">iPhone / iPad</span>
									{elseif $client_type->type == "windows"}
										<span class="app-pick-emoji">💻</span><span class="app-pick-name">Windows</span>
									{elseif $client_type->type == "macos"}
										<span class="app-pick-emoji">🍎</span><span class="app-pick-name">Mac</span>
									{elseif $client_type->type == "linux"}
										<span class="app-pick-emoji">🐧</span><span class="app-pick-name">Linux</span>
									{else}
										<span class="app-pick-emoji">🖥️</span><span class="app-pick-name">{$client_type->type}</span>
									{/if}
								</a>
							</li>
						{/if}
						{$apptype = "{$apptype},{$client_type->type}"}
					{/foreach}
				</ul>
			</div>

			<div class="tab-content">
				{$type = ""}
				{$c = 0}
				{foreach $clients as $client}
				{$c = $c + 1}
				{if $client->type != $type}
				{$type = $client->type}
				<div class="tab-pane fade {if $c == 1}show active{/if}" id="os-{$client->type}" role="tabpanel">

					<div class="app-step">
						<div class="app-step-head">
							<span class="app-step-num">2</span>
							<div>
								<h5 class="app-step-title">{$translate->get('PickApp')}</h5>
								<span class="app-step-sub">{$translate->get('PickAppHint')}</span>
							</div>
						</div>

						<ul class="nav app-grid">
							{$a = 0}
							{foreach $clients as $app}
								{if $app->type == $client->type}
								{$a = $a + 1}
								{$appid = $app->type|cat:"-"|cat:$app->client|replace:" ":"-"|replace:".":"-"}
									<li class="nav-item">
										<a class="nav-link app-pick {if $a == 1}active{/if}" href="#app-{$appid}" data-bs-toggle="pill" data-bs-target="#app-{$appid}" role="presentation" aria-controls="app-{$appid}" aria-selected="false" style="--pick:#6366f1;--pick-soft:rgba(99,102,241,.11)">
											<span class="app-pick-icon">{$app->icon}</span>
											<span class="app-pick-name">{$app->client}</span>
											{if $a == 1}<span class="app-here">⭐ {$translate->get('Recommended')}</span>{/if}
										</a>
									</li>
								{/if}
							{/foreach}
						</ul>
					</div>

					<div class="tab-content">
						{$t = 0}
						{$content = ""}
						{foreach $clients as $contentTab}
						{if $contentTab->client != $content && $contentTab->type == $type}
						{$t = $t + 1}
						{$content = $contentTab->client}
						{$tabid = $contentTab->type|cat:"-"|cat:$contentTab->client|replace:" ":"-"|replace:".":"-"}
							<div class="tab-pane fade {if $t == 1}show active{/if}" id="app-{$tabid}" role="tabpanel">

								<div class="app-step">
									<div class="app-step-head">
										<span class="app-step-num">3</span>
										<div>
											<h5 class="app-step-title">{$translate->get('InstallConnect')}</h5>
											<span class="app-step-sub">{$translate->get('InstallConnectHint')}</span>
										</div>
									</div>

									<div class="app-connect">
										<div class="app-link-row">
											<input class="app-link-field" type="text" readonly onclick="this.select()" value="{$SubUrl}{$contentTab->link}">
											<button type="button" class="app-btn app-btn-copy copy-text" data-clipboard-text="{$SubUrl}{$contentTab->link}">
												📋 <span>{$translate->get('CopyLink')}</span>
											</button>
										</div>

										<div class="app-actions">
											{if strpos($contentTab->client, "Clash") !== false && strpos($contentTab->client, "Open") === false}
												<a class="app-btn app-btn-import" href="clash://install-config?url={urlencode($SubUrl)}{urlencode($contentTab->link)}">⚡ {$translate->get('ExportLink')}</a>
											{/if}
											{if strpos($contentTab->client, "Shadowrocket") !== false}
												<a class="app-btn app-btn-import" onclick=AddSub("{$SubUrl}{$contentTab->link}","shadowrocket://add/sub://")>⚡ {$translate->get('ExportLink')}</a>
											{/if}
											{if strpos($contentTab->client, "Surfboard") !== false}
												<a class="app-btn app-btn-import" href="surfboard:///install-config?url={urlencode($SubUrl)}{urlencode($contentTab->link)}">⚡ {$translate->get('ExportLink')}</a>
											{/if}
											{if strpos($contentTab->client, "Stash") !== false}
												<a class="app-btn app-btn-import" href="stash://install-config?url={urlencode($SubUrl)}{urlencode($contentTab->link)}">⚡ {$translate->get('ExportLink')}</a>
											{/if}

											<a class="app-btn app-btn-get" href="{$contentTab->url}" target="_blank" rel="noopener">⬇️ {$translate->get('Download')} {$contentTab->client}</a>

											{if $contentTab->uuid || $contentTab->uuid != 0}
												<a class="app-btn app-btn-help" href="/portal/knowledgebase/{$contentTab->uuid}">📖 {$translate->get('Instruction')}</a>
											{/if}
										</div>

										<div class="app-howto">
											<div class="app-howto-item"><span class="app-howto-emoji">⬇️</span><span>{$translate->get('HowToStep1')}</span></div>
											<div class="app-howto-item"><span class="app-howto-emoji">📋</span><span>{$translate->get('HowToStep2')}</span></div>
											<div class="app-howto-item"><span class="app-howto-emoji">🔌</span><span>{$translate->get('HowToStep3')}</span></div>
										</div>
									</div>
								</div>

							</div>
						{/if}
						{/foreach}
					</div>
				</div>
				{/if}
				{/foreach}
			</div>

		</div>
	</div>
</div>

<script>
	window.AppPickerI18n = new Object();
	window.AppPickerI18n.yourDevice = "{$translate->get('YourDevice')|escape:'javascript'}";
	window.AppPickerI18n.copied     = "{$translate->get('LinkCopied')|escape:'javascript'}";
	window.AppPickerI18n.copy       = "{$translate->get('CopyLink')|escape:'javascript'}";
</script>
{literal}
<script>
(function () {
	function detect() {
		var ua = navigator.userAgent || '';
		if (/android/i.test(ua)) { return 'android'; }
		if (/iphone|ipad|ipod/i.test(ua) || (/mac/i.test(ua) && navigator.maxTouchPoints > 1)) { return 'ios'; }
		if (/windows|win32|win64/i.test(ua)) { return 'windows'; }
		if (/mac os x/i.test(ua)) { return 'macos'; }
		if (/linux|x11/i.test(ua)) { return 'linux'; }
		return null;
	}

	function start() {
		var list = document.getElementById('appPlatforms');
		if (!list) { return; }

		var mine = detect();
		var tabs = list.querySelectorAll('.app-pick');

		for (var i = 0; i < tabs.length; i++) {
			if (mine && tabs[i].getAttribute('data-platform') === mine) {
				var flag = document.createElement('span');
				flag.className = 'app-here';
				flag.textContent = '👉 ' + (window.AppPickerI18n ? window.AppPickerI18n.yourDevice : 'your device');
				tabs[i].appendChild(flag);

				// open the tab that matches the device the visitor is holding
				if (window.bootstrap && bootstrap.Tab) {
					bootstrap.Tab.getOrCreateInstance(tabs[i]).show();
				} else {
					tabs[i].click();
				}
			}
		}

		// visible confirmation right on the button, not just a toast
		document.addEventListener('click', function (event) {
			var button = event.target.closest ? event.target.closest('.app-btn-copy') : null;
			if (!button) { return; }

			var label = button.querySelector('span');
			if (!label || button.classList.contains('app-done')) { return; }

			var original = label.textContent;
			button.classList.add('app-done');
			label.textContent = (window.AppPickerI18n ? window.AppPickerI18n.copied : 'Copied');

			setTimeout(function () {
				button.classList.remove('app-done');
				label.textContent = original;
			}, 2000);
		});
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', start);
	} else {
		start();
	}
})();
</script>
{/literal}
