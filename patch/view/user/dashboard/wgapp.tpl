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
					<span class="fw-bold fs-13 text-muted">📱 مدیریت دستگاه‌ها: <span class="badge bg-primary text-white ms-1 wg-device-count">{count($wgDevs)} از {$wgLimit}</span></span>
					<button type="button" class="btn btn-sm btn-outline-primary py-1 px-2 fs-12 rounded-pill wg-add-device-btn" {if count($wgDevs) >= $wgLimit}style="display:none"{/if}>➕ افزودن دستگاه</button>
				</div>
				<div class="d-flex flex-wrap gap-2 wg-device-list">
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

			<ul class="wg-servers mb-3 wg-servers-list">
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
	window.__wgActiveDevId = window.__wgActiveDevId || 1;

	function syncPillsAndLinks() {
		var activeId = window.__wgActiveDevId || 1;
		var pills = document.querySelectorAll('.wg-dev-pill');
		for (var i = 0; i < pills.length; i++) {
			var id = parseInt(pills[i].getAttribute('data-dev-id'), 10) || 1;
			if (id === activeId) {
				pills[i].classList.add('is-active');
			} else {
				pills[i].classList.remove('is-active');
			}
		}

		var links = document.querySelectorAll('.wg-servers-list .wg-get');
		for (var j = 0; j < links.length; j++) {
			var href = links[j].getAttribute('href') || '';
			href = href.replace(/[?&]device=\d+/g, '');
			var sep = href.indexOf('?') === -1 ? '?' : '&';
			links[j].setAttribute('href', href + sep + 'device=' + activeId);
		}
	}

	function refreshAllDevices() {
		fetch('/xmplus-patch.php?do=wg.devices')
			.then(function (r) { return r.json(); })
			.then(function (data) {
				if (!data.ok) return;
				var activeId = window.__wgActiveDevId || 1;
				var hasActive = false;
				data.devices.forEach(function (d) { if (d.id === activeId) hasActive = true; });
				if (!hasActive && data.devices.length) {
					activeId = data.devices[0].id;
					window.__wgActiveDevId = activeId;
				}

				var counters = document.querySelectorAll('.wg-device-count');
				for (var c = 0; c < counters.length; c++) {
					counters[c].textContent = data.count + ' از ' + data.limit;
				}

				var addBtns = document.querySelectorAll('.wg-add-device-btn');
				for (var b = 0; b < addBtns.length; b++) {
					addBtns[b].style.display = data.can_add ? 'inline-block' : 'none';
				}

				var containers = document.querySelectorAll('.wg-device-list');
				for (var k = 0; k < containers.length; k++) {
					containers[k].innerHTML = '';
					data.devices.forEach(function (dev) {
						var div = document.createElement('div');
						div.className = 'wg-dev-pill' + (dev.id === activeId ? ' is-active' : '');
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
							del.setAttribute('title', 'حذف این دستگاه');
							del.innerHTML = '&times;';
							div.appendChild(del);
						}
						containers[k].appendChild(div);
					});
				}

				syncPillsAndLinks();
			})
			.catch(function (e) { console.error('wg.devices refresh error', e); });
	}

	function handleAddDevice() {
		var doSubmit = function (name) {
			var fd = new FormData();
			fd.append('name', name);
			fetch('/xmplus-patch.php?do=wg.device.add', { method: 'POST', body: fd })
				.then(function (r) { return r.json(); })
				.then(function (res) {
					if (res.ret || res.ok) {
						if (res.device && res.device.id) {
							window.__wgActiveDevId = res.device.id;
						}
						refreshAllDevices();
					} else {
						alert(res.msg || res.error || 'خطا در افزودن دستگاه');
					}
				})
				.catch(function () { alert('خطای ارتباط با سرور'); });
		};

		if (typeof Swal !== 'undefined' && typeof Swal.fire === 'function') {
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
				if (result && result.isConfirmed && result.value) {
					doSubmit(result.value.trim());
				}
			});
		} else {
			var name = prompt('نام دستگاه جدید را وارد کنید (مثلاً: لپ‌تاپ یا گوشی دوم):');
			if (name && name.trim()) {
				doSubmit(name.trim());
			}
		}
	}

	function handleDeleteDevice(devId) {
		var doDelete = function () {
			var fd = new FormData();
			fd.append('device_id', devId);
			fetch('/xmplus-patch.php?do=wg.device.del', { method: 'POST', body: fd })
				.then(function (r) { return r.json(); })
				.then(function (res) {
					if (res.ret || res.ok) {
						if (window.__wgActiveDevId === devId) {
							window.__wgActiveDevId = 1;
						}
						refreshAllDevices();
					} else {
						alert(res.msg || res.error || 'خطا در حذف دستگاه');
					}
				})
				.catch(function () { alert('خطای ارتباط با سرور'); });
		};

		if (typeof Swal !== 'undefined' && typeof Swal.fire === 'function') {
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
				if (result && result.isConfirmed) {
					doDelete();
				}
			});
		} else if (confirm('آیا از حذف این دستگاه اطمینان دارید؟ کانفیگ آن باطل خواهد شد.')) {
			doDelete();
		}
	}

	// Global event delegation (only bound once)
	if (!window.__wgDeviceManagerBound) {
		window.__wgDeviceManagerBound = true;

		document.addEventListener('click', function (e) {
			var target = e.target;
			if (!target) return;

			var delBtn = target.closest ? target.closest('.wg-dev-del') : null;
			if (delBtn) {
				e.preventDefault();
				e.stopPropagation();
				var delId = parseInt(delBtn.getAttribute('data-del-id'), 10);
				if (delId && delId > 1) {
					handleDeleteDevice(delId);
				}
				return;
			}

			var addBtn = target.closest ? target.closest('.wg-add-device-btn') : null;
			if (addBtn) {
				e.preventDefault();
				e.stopPropagation();
				handleAddDevice();
				return;
			}

			var pill = target.closest ? target.closest('.wg-dev-pill') : null;
			if (pill) {
				e.preventDefault();
				var pId = parseInt(pill.getAttribute('data-dev-id'), 10) || 1;
				window.__wgActiveDevId = pId;
				syncPillsAndLinks();
				return;
			}
		});
	}

	syncPillsAndLinks();
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', syncPillsAndLinks);
	}
})();
</script>
{/literal}