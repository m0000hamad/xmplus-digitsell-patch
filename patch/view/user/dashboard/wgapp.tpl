{*
  Step 3 of the apps card for a WireGuard / AmneziaWG app. Included by application.tpl in
  place of the subscription link when the client's name contains "WireGuard" or "Amnezia".
  Parameter: app - the client row.
*}
{include file='user/dashboard/wgstyle.tpl'}

<div class="app-step">
	<div class="app-step-head">
		<span class="app-step-num">3</span>
		<div>
			<h5 class="app-step-title">{$translate->get('InstallConnect')}</h5>
			<span class="app-step-sub">{$translate->get('WgAppHint')}</span>
		</div>
	</div>

	<div class="app-connect">
		{if $user->wgEnabled()}
			{$wgDevs = $user->wgDevices()}
			{$wgLimit = $user->wgDeviceLimit()}
			<div class="wg-device-manager mb-3">
				<div class="d-flex align-items-center justify-content-between mb-2">
					<span class="fw-bold fs-13 text-muted">📱 مدیریت دستگاه‌ها: <span id="wgDeviceCount" class="badge bg-primary text-white ms-1">{count($wgDevs)} از {$wgLimit}</span></span>
					<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 fs-12 rounded-pill" id="wgAddDeviceBtn" {if count($wgDevs) >= $wgLimit}style="display:none"{/if}>➕ افزودن دستگاه</button>
				</div>
				<div class="d-flex flex-wrap gap-2" id="wgDeviceList">
					{foreach $wgDevs as $dev}
						<div class="wg-dev-pill{if $dev@first} is-active{/if}" data-dev-id="{$dev.id}">
							<span class="wg-dev-name">{if $dev.id == 1}⭐{else}📱{/if} {$dev.name}</span>
							{if $dev.id > 1}
								<button type="button" class="wg-dev-del" data-del-id="{$dev.id}" title="حذف این دستگاه">&times;</button>
							{/if}
						</div>
					{/foreach}
				</div>
			</div>

			<ul class="wg-servers mb-3" id="wgServersList">
				{foreach $user->wgNodes() as $wgNode}
					{include file='user/dashboard/wgnode.tpl' node=$wgNode}
				{/foreach}
			</ul>
		{else}
			<p class="wg-note">{$translate->get('WgNoServer')}</p>
		{/if}

		<div class="app-actions">
			<a class="app-btn app-btn-get" href="{$app->url}" target="_blank" rel="noopener">⬇️ {$translate->get('Download')} {$app->client}</a>
			{if $app->uuid || $app->uuid != 0}
				<a class="app-btn app-btn-help" href="/portal/knowledgebase/{$app->uuid}">📖 {$translate->get('Instruction')}</a>
			{/if}
		</div>

		<ol class="wg-steps">
			<li>{$translate->get('WgHow1')}</li>
			<li>{$translate->get('WgHow2')}</li>
			<li>{$translate->get('WgHow3')}</li>
		</ol>
		<p class="wg-note">{$translate->get('WgResetNote')}</p>
	</div>
</div>

{literal}
<script>
(function () {
	var activeDevId = 1;
	var limit = 1;

	function updateDownloadLinks() {
		var list = document.getElementById('wgServersList');
		if (!list) return;
		var links = list.querySelectorAll('.wg-get');
		for (var i = 0; i < links.length; i++) {
			var href = links[i].getAttribute('href') || '';
			href = href.replace(/[?&]device=\d+/g, '');
			var sep = href.indexOf('?') === -1 ? '?' : '&';
			links[i].setAttribute('href', href + sep + 'device=' + activeDevId);
		}
	}

	function bindPills() {
		var container = document.getElementById('wgDeviceList');
		if (!container) return;

		var pills = container.querySelectorAll('.wg-dev-pill');
		pills.forEach(function (pill) {
			pill.onclick = function (e) {
				if (e.target.classList.contains('wg-dev-del')) return;
				pills.forEach(function (p) { p.classList.remove('is-active'); });
				pill.classList.add('is-active');
				activeDevId = parseInt(pill.getAttribute('data-dev-id'), 10) || 1;
				updateDownloadLinks();
			};
		});

		var dels = container.querySelectorAll('.wg-dev-del');
		dels.forEach(function (btn) {
			btn.onclick = function (e) {
				e.stopPropagation();
				var id = parseInt(btn.getAttribute('data-del-id'), 10);
				if (!id || id <= 1) return;

				var doDelete = function () {
					var fd = new FormData();
					fd.append('device_id', id);
					fetch('/xmplus-patch.php?do=wg.device.del', { method: 'POST', body: fd })
						.then(function (r) { return r.json(); })
						.then(function (res) {
							if (res.ret || res.ok) {
								if (activeDevId === id) activeDevId = 1;
								refreshDevices();
							} else {
								alert(res.msg || res.error || 'خطا در حذف دستگاه');
							}
						})
						.catch(function (err) { alert('خطای ارتباط با سرور'); });
				};

				if (window.Swal) {
					Swal.fire({
						title: 'حذف دستگاه؟',
						text: 'کانفیگ اختصاصی این دستگاه بلافاصله در سرور باطل می‌شود.',
						icon: 'warning',
						showCancelButton: true,
						confirmButtonText: 'بله، حذف شود',
						cancelButtonText: 'انصراف',
						customClass: { confirmButton: 'btn btn-danger ms-1', cancelButton: 'btn btn-secondary ms-1' },
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) doDelete();
					});
				} else if (confirm('آیا از حذف این دستگاه اطمینان دارید؟ کانفیگ آن باطل خواهد شد.')) {
					doDelete();
				}
			};
		});
	}

	function refreshDevices() {
		fetch('/xmplus-patch.php?do=wg.devices')
			.then(function (r) { return r.json(); })
			.then(function (data) {
				if (!data.ok) return;
				limit = data.limit;
				var container = document.getElementById('wgDeviceList');
				var counter = document.getElementById('wgDeviceCount');
				var addBtn = document.getElementById('wgAddDeviceBtn');

				if (counter) counter.textContent = data.count + ' از ' + data.limit;
				if (addBtn) addBtn.style.display = data.can_add ? 'inline-block' : 'none';

				if (container) {
					container.innerHTML = '';
					var hasActive = false;
					data.devices.forEach(function (dev) {
						if (dev.id === activeDevId) hasActive = true;
						var div = document.createElement('div');
						div.className = 'wg-dev-pill' + (dev.id === activeDevId ? ' is-active' : '');
						div.setAttribute('data-dev-id', dev.id);

						var span = document.createElement('span');
						span.className = 'wg-dev-name';
						span.textContent = (dev.id === 1 ? '⭐ ' : '📱 ') + dev.name;
						div.appendChild(span);

						if (dev.id > 1) {
							var del = document.createElement('button');
							del.type = 'button';
							del.className = 'wg-dev-del';
							del.setAttribute('data-del-id', dev.id);
							del.innerHTML = '&times;';
							div.appendChild(del);
						}
						container.appendChild(div);
					});

					if (!hasActive && data.devices.length) {
						activeDevId = data.devices[0].id;
						var first = container.querySelector('.wg-dev-pill');
						if (first) first.classList.add('is-active');
					}
					bindPills();
					updateDownloadLinks();
				}
			})
			.catch(function (e) { console.error('wg.devices refresh error', e); });
	}

	function setupAdd() {
		var btn = document.getElementById('wgAddDeviceBtn');
		if (!btn) return;

		btn.onclick = function () {
			var doAdd = function (name) {
				var fd = new FormData();
				fd.append('name', name);
				fetch('/xmplus-patch.php?do=wg.device.add', { method: 'POST', body: fd })
					.then(function (r) { return r.json(); })
					.then(function (res) {
						if (res.ret || res.ok) {
							if (res.device && res.device.id) {
								activeDevId = res.device.id;
							}
							refreshDevices();
						} else {
							alert(res.msg || res.error || 'خطا در افزودن دستگاه');
						}
					})
					.catch(function () { alert('خطای ارتباط با سرور'); });
			};

			if (window.Swal) {
				Swal.fire({
					title: 'افزودن دستگاه جدید',
					input: 'text',
					inputLabel: 'یک نام دلخواه برای این دستگاه وارد کنید:',
					inputPlaceholder: 'مثلاً: لپ‌تاپ یا گوشی دوم',
					showCancelButton: true,
					confirmButtonText: 'تولید کانفیگ دستگاه',
					cancelButtonText: 'انصراف',
					customClass: { confirmButton: 'btn btn-primary ms-1', cancelButton: 'btn btn-secondary ms-1' },
					buttonsStyling: false,
					inputValidator: function (value) {
						if (!value || !value.trim()) {
							return 'لطفاً نام دستگاه را بنویسید!';
						}
					}
				}).then(function (result) {
					if (result.isConfirmed && result.value) {
						doAdd(result.value.trim());
					}
				});
			} else {
				var name = prompt('نام دستگاه جدید را وارد کنید (مثلاً: لپ‌تاپ یا گوشی دوم):');
				if (name && name.trim()) {
					doAdd(name.trim());
				}
			}
		};
	}

	function start() {
		bindPills();
		setupAdd();
		updateDownloadLinks();
	}

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', start);
	} else {
		start();
	}
})();
</script>
{/literal}