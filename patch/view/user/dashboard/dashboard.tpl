{include file='user/layout/header.tpl'}  
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0"> 
				<h1 class="page-header-title">{$translate->get('Dashboard')}</h1>
			</div>
        </div>
    </div>
	  
	<div class="row match-height">
		{include file='user/dashboard/subsciption.tpl'}
		{include file='user/dashboard/application.tpl'}
	</div>
	<div class="row match-height">
		{include file='user/dashboard/statistics.tpl'}	
		{include file='user/dashboard/chart.tpl'}	
	</div>
{include file='user/dashboard/servers.tpl'}
	{include file='user/dashboard/order.tpl'}
	
  {literal}
  <style>
  /* ---- latest-notice popup: was a bold text blob with an unlabelled switch ---- */
  .ntcpop .modal-content {
	border: 0;
	border-radius: 20px;
	overflow: hidden;
	box-shadow: 0 26px 64px rgba(23, 32, 61, .32);
  }
  .ntcpop .modal-header {
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
	border: 0;
	padding: 18px 22px;
  }
  .ntcpop .modal-title {
	color: #fff;
	font-size: 16.5px;
	font-weight: 800;
	display: flex;
	align-items: center;
	gap: 9px;
  }
  .ntcpop .modal-header .btn-close {
	filter: brightness(0) invert(1);
	opacity: .9;
  }
  .ntcpop .modal-body { padding: 20px 22px 8px; }
  .ntcpop-title {
	font-size: 15px;
	font-weight: 800;
	color: #16203d;
	margin: 0 0 10px;
	line-height: 1.6;
  }
  .ntcpop-body {
	font-size: 14px;
	font-weight: 500;
	color: #3f4a63;
	line-height: 2.05;
	max-height: 46vh;
	overflow-y: auto;
	padding-inline-end: 4px;
	word-break: break-word;
	font-family: 'IRANSans', Tahoma, sans-serif;
  }
  .ntcpop-body p:last-child { margin-bottom: 0; }
  .ntcpop-body img { max-width: 100%; height: auto; border-radius: 10px; }
  .ntcpop-body a { color: #6366f1; font-weight: 700; }
  .ntcpop .modal-footer {
	border: 0;
	padding: 14px 22px 20px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12px;
	flex-wrap: wrap;
  }
  .ntcpop-dismiss {
	display: inline-flex;
	align-items: center;
	gap: 9px;
	font-size: 12px;
	font-weight: 700;
	color: #56617a;
	margin: 0;
	cursor: pointer;
  }
  .ntcpop-dismiss .form-check-input {
	width: 40px;
	height: 22px;
	margin: 0;
	cursor: pointer;
	box-shadow: none !important;
  }
  .ntcpop-dismiss .form-check-input:checked { background-color: #6366f1; border-color: #6366f1; }
  .ntcpop-ok {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	min-height: 40px;
	padding: 9px 20px;
	border: 0;
	border-radius: 13px;
	font-size: 12.5px;
	font-weight: 800;
	color: #fff;
	cursor: pointer;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 6px 16px rgba(99, 102, 241, .32);
  }
  .ntcpop-ok:hover { box-shadow: 0 9px 22px rgba(99, 102, 241, .44); color: #fff; }
  html[data-hs-theme="dark"] .ntcpop .modal-content { background: #1c2536; }
  html[data-hs-theme="dark"] .ntcpop .modal-body { background: #1c2536; }
  html[data-hs-theme="dark"] .ntcpop-title { color: #e7eaf3; }
  html[data-hs-theme="dark"] .ntcpop-body { color: #b9c2d4; }
  html[data-hs-theme="dark"] .ntcpop .modal-footer { background: #1c2536; }
  html[data-hs-theme="dark"] .ntcpop-dismiss { color: #b9c2d4; }
  </style>
  {/literal}
  <div class="modal fade ntcpop" id="noticemodal" tabindex="-1" aria-labelledby="noticemodal" role="dialog" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
      <div class="modal-content">
		<div class="modal-header">
			<h4 class="modal-title">📢 {$translate->get('LatestNotice')}</h4>
			<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
		</div>
        <div class="modal-body">
			{if $ann != null}
				{if isset($ann->title) && $ann->title}
					<h5 class="ntcpop-title">{$ann->title|escape:'html'}</h5>
				{/if}
				<div class="ntcpop-body">{$ann->content}</div>
			{/if}
        </div>
		<div class="modal-footer">
			<label class="ntcpop-dismiss form-check form-switch">
				<input class="form-check-input modal-check" type="checkbox" name="modal-check">
				<span>{$translate->get('NoticeDontShowAgain')}</span>
			</label>
			<button type="button" class="ntcpop-ok" data-bs-dismiss="modal">👍 {$translate->get('NoticeGotIt')}</button>
		</div>
      </div>
    </div>
  </div>
  
{include file='user/layout/footer.tpl'}
{include file='common/orderresult.tpl'}
<script src="/assets/js/jquery.cookie.min.js"></script>
<script src="/assets/js/apexcharts.js"></script>
<script>
	{assign var=usagedata value=json_encode($user->usageStats())}
	window.usageStats = {$usagedata};
	window.usageI18n = new Object();
	window.usageI18n.total      = "{$translate->get('TotalUsage')|escape:'javascript'}";
	window.usageI18n.up         = "{$translate->get('Uploaded')|escape:'javascript'}";
	window.usageI18n.down       = "{$translate->get('Downloaded')|escape:'javascript'}";
	window.usageI18n.empty      = "{$translate->get('NoUsageData')|escape:'javascript'}";
	window.usageI18n.peak       = "{$translate->get('PeakUsage')|escape:'javascript'}";
	window.usageI18n.share      = "{$translate->get('UsageShare')|escape:'javascript'}";
	window.usageI18n.day        = "{$translate->get('RangeDay')|escape:'javascript'}";
	window.usageI18n.week       = "{$translate->get('RangeWeek')|escape:'javascript'}";
	window.usageI18n.month      = "{$translate->get('RangeMonth')|escape:'javascript'}";
	window.usageI18n.year       = "{$translate->get('RangeYear')|escape:'javascript'}";
	window.usageI18n.remaining  = "{$translate->get('unUsedData')|escape:'javascript'}";
	window.usageQuota = new Object();
	window.usageQuota.remaining = parseFloat("{$user->unusedTrafficPercent()}") || 0;
	window.usageQuota.used      = parseFloat("{$user->usedTrafficPercent()}") || 0;
</script>
{literal}
<script>
var renderUsageCharts = (function () {
	var PALETTE = ['#6366f1', '#06b6d4', '#8b5cf6', '#f59e0b', '#10b981', '#f43f5e', '#3b82f6', '#ec4899', '#14b8a6', '#a855f7'];
	var areaChart = null;
	var donutChart = null;
	var quotaChart = null;
	var currentRange = 'day';
	var wired = false;

	function stats() {
		return window.usageStats || { ranges: {}, servers: {}, totals: {} };
	}

	function txt(key) {
		return (window.usageI18n && window.usageI18n[key]) ? window.usageI18n[key] : key;
	}

	function isDark() {
		return document.documentElement.getAttribute('data-hs-appearance') === 'dark';
	}

	function format(mb) {
		var value = parseFloat(mb);
		if (!value || value <= 0) { return '0 MB'; }
		if (value < 1024) { return (value < 10 ? value.toFixed(2) : value.toFixed(1)) + ' MB'; }
		var gb = value / 1024;
		if (gb < 1024) { return gb.toFixed(2) + ' GB'; }
		return (gb / 1024).toFixed(2) + ' TB';
	}

	function num(value) {
		return '<span class="usage-num">' + value + '</span>';
	}

	function shortLabel(range, label) {
		if (range === 'week' || range === 'month') { return label.substring(5); }
		return label;
	}

	function percent(part, whole) {
		if (!whole || whole <= 0) { return 0; }
		return Math.round((part / whole) * 1000) / 10;
	}

	function axisColor() {
		return isDark() ? '#9fb0cc' : '#97a4af';
	}

	function paintKpis(range) {
		if (!document.getElementById('usageKpiTotal')) { return; }

		var totals = stats().totals[range] || { up: 0, down: 0, total: 0 };
		var series = stats().ranges[range] || { total: [], labels: [] };

		document.getElementById('usageKpiTotal').innerHTML = num(format(totals.total));
		document.getElementById('usageKpiDown').innerHTML  = num(format(totals.down));
		document.getElementById('usageKpiUp').innerHTML    = num(format(totals.up));

		document.getElementById('usageKpiDownPct').innerHTML = num(percent(totals.down, totals.total) + '%') + ' ' + txt('share');
		document.getElementById('usageKpiUpPct').innerHTML   = num(percent(totals.up, totals.total) + '%') + ' ' + txt('share');

		var peak = 0;
		var peakAt = '';
		for (var i = 0; i < series.total.length; i++) {
			if (series.total[i] > peak) {
				peak = series.total[i];
				peakAt = shortLabel(range, series.labels[i]);
			}
		}
		document.getElementById('usageKpiPeak').innerHTML = peak > 0
			? txt('peak') + ': ' + num(format(peak)) + ' &middot; ' + num(peakAt)
			: '&nbsp;';
	}

	function drawArea(range) {
		var host = document.getElementById('usageArea');
		if (!host) { return; }

		var series = stats().ranges[range] || { labels: [], up: [], down: [], total: [] };
		var totals = stats().totals[range] || { total: 0 };
		var dark = isDark();

		if (areaChart) { areaChart.destroy(); areaChart = null; }

		if (!totals.total || totals.total <= 0) {
			host.innerHTML = '<div class="usage-empty"><i class="bi-bar-chart-line"></i><span>' + txt('empty') + '</span></div>';
			return;
		}
		host.innerHTML = '';

		var labels = [];
		for (var i = 0; i < series.labels.length; i++) {
			labels.push(shortLabel(range, series.labels[i]));
		}

		areaChart = new ApexCharts(host, {
			chart: {
				type: 'area',
				height: 300,
				stacked: true,
				fontFamily: 'inherit',
				toolbar: { show: false },
				zoom: { enabled: false },
				animations: { easing: 'easeinout', speed: 450 }
			},
			series: [
				{ name: txt('down'), data: series.down },
				{ name: txt('up'), data: series.up }
			],
			colors: ['#6366f1', '#f59e0b'],
			dataLabels: { enabled: false },
			stroke: { curve: 'smooth', width: 2.5, lineCap: 'round' },
			fill: {
				type: 'gradient',
				gradient: { shadeIntensity: 1, opacityFrom: 0.45, opacityTo: 0.02, stops: [0, 90, 100] }
			},
			markers: { size: 0, strokeWidth: 2, hover: { size: 5 } },
			grid: {
				borderColor: dark ? 'rgba(255,255,255,.08)' : 'rgba(23,32,61,.07)',
				strokeDashArray: 4,
				xaxis: { lines: { show: false } },
				padding: { left: 6, right: 6, top: -6 }
			},
			legend: {
				position: 'top',
				horizontalAlign: 'left',
				fontSize: '12px',
				markers: { radius: 12, width: 9, height: 9 },
				itemMargin: { horizontal: 10 },
				labels: { colors: axisColor() }
			},
			xaxis: {
				categories: labels,
				axisBorder: { show: false },
				axisTicks: { show: false },
				tooltip: { enabled: false },
				labels: { rotate: 0, hideOverlappingLabels: true, style: { colors: axisColor(), fontSize: '11px' } }
			},
			yaxis: {
				tickAmount: 4,
				labels: {
					formatter: function (value) { return format(value); },
					style: { colors: axisColor(), fontSize: '11px' }
				}
			},
			tooltip: {
				theme: dark ? 'dark' : 'light',
				shared: true,
				intersect: false,
				y: { formatter: function (value) { return format(value); } }
			}
		});
		areaChart.render();
	}

	function drawServers(range) {
		var host = document.getElementById('usageDonut');
		var list = document.getElementById('usageServerList');
		var badge = document.getElementById('usageServerRangeLabel');
		if (!host || !list) { return; }

		if (badge) { badge.textContent = txt(range); }

		var servers = stats().servers[range] || [];
		var dark = isDark();

		if (donutChart) { donutChart.destroy(); donutChart = null; }

		if (!servers.length) {
			host.innerHTML = '<div class="usage-empty"><i class="bi-hdd-network"></i><span>' + txt('empty') + '</span></div>';
			list.innerHTML = '';
			return;
		}
		host.innerHTML = '';

		var names = [];
		var values = [];
		var grand = 0;
		for (var i = 0; i < servers.length; i++) {
			names.push(servers[i].name);
			values.push(servers[i].total);
			grand += servers[i].total;
		}

		donutChart = new ApexCharts(host, {
			chart: { type: 'donut', height: 270, fontFamily: 'inherit' },
			series: values,
			labels: names,
			colors: PALETTE,
			stroke: { width: 0 },
			legend: { show: false },
			dataLabels: { enabled: false },
			plotOptions: {
				pie: {
					donut: {
						size: '73%',
						labels: {
							show: true,
							name: { fontSize: '12px', color: axisColor() },
							value: {
								fontSize: '17px',
								fontWeight: 700,
								color: dark ? '#e7eaf3' : '#16203d',
								formatter: function (value) { return format(value); }
							},
							total: {
								show: true,
								label: txt('total'),
								color: axisColor(),
								formatter: function () { return format(grand); }
							}
						}
					}
				}
			},
			tooltip: {
				theme: dark ? 'dark' : 'light',
				y: { formatter: function (value) { return format(value); } }
			},
			responsive: [{ breakpoint: 576, options: { chart: { height: 230 } } }]
		});
		donutChart.render();

		var html = '';
		for (var j = 0; j < servers.length; j++) {
			var server = servers[j];
			var color = PALETTE[j % PALETTE.length];
			var width = grand > 0 ? Math.max((server.total / grand) * 100, 1.5) : 0;

			html += '<div class="usage-server">'
				+ '<span class="usage-server-rank" style="background:' + color + '">' + (j + 1) + '</span>'
				+ '<div class="usage-server-body">'
				+ '<div class="usage-server-head">'
				+ '<span class="usage-server-name">' + escapeHtml(server.name) + '</span>'
				+ '<span class="usage-server-total">' + format(server.total) + '</span>'
				+ '</div>'
				+ '<div class="usage-server-bar"><span style="width:' + width.toFixed(1) + '%;background:' + color + '"></span></div>'
				+ '<div class="usage-server-meta">'
				+ '<span>' + txt('down') + ' <b>' + format(server.down) + '</b></span>'
				+ '<span>' + txt('up') + ' <b>' + format(server.up) + '</b></span>'
				+ '<span>' + percent(server.total, grand) + '%</span>'
				+ '</div>'
				+ '</div></div>';
		}
		list.innerHTML = html;
	}

	function quotaColors(remaining) {
		if (remaining >= 50) { return ['#6366f1', '#a855f7']; }
		if (remaining >= 20) { return ['#f59e0b', '#fb923c']; }
		return ['#f43f5e', '#fb7185'];
	}

	function drawQuota() {
		var host = document.getElementById('quotaChart');
		if (!host) { return; }

		var quota = window.usageQuota || { remaining: 0, used: 0 };
		var remaining = Math.max(0, Math.min(100, quota.remaining));
		var colors = quotaColors(remaining);
		var dark = isDark();

		var dot = document.getElementById('quotaLegendDot');
		if (dot) { dot.style.setProperty('--dot', colors[0]); }

		if (quotaChart) { quotaChart.destroy(); quotaChart = null; }
		host.innerHTML = '';

		quotaChart = new ApexCharts(host, {
			chart: {
				type: 'radialBar',
				height: 260,
				fontFamily: 'inherit',
				offsetY: -8,
				dropShadow: {
					enabled: true,
					top: 4,
					blur: 8,
					opacity: dark ? 0.35 : 0.18,
					color: colors[0]
				}
			},
			series: [Math.round(remaining * 10) / 10],
			labels: [txt('remaining')],
			colors: [colors[0]],
			fill: {
				type: 'gradient',
				gradient: {
					shade: 'dark',
					type: 'horizontal',
					gradientToColors: [colors[1]],
					stops: [0, 100]
				}
			},
			stroke: { lineCap: 'round' },
			plotOptions: {
				radialBar: {
					startAngle: -135,
					endAngle: 135,
					hollow: { size: '66%', background: 'transparent' },
					track: {
						background: dark ? 'rgba(255,255,255,.07)' : '#eef1f8',
						strokeWidth: '100%',
						margin: 8
					},
					dataLabels: {
						name: {
							show: true,
							offsetY: 24,
							fontSize: '12.5px',
							color: axisColor()
						},
						value: {
							show: true,
							offsetY: -14,
							fontSize: '34px',
							fontWeight: 700,
							color: dark ? '#e7eaf3' : '#16203d',
							formatter: function (value) { return value + '%'; }
						}
					}
				}
			}
		});
		quotaChart.render();
	}

	function escapeHtml(value) {
		return String(value).replace(/[&<>"']/g, function (chr) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[chr];
		});
	}

	function wire() {
		if (wired) { return; }
		var box = document.getElementById('usageRange');
		if (!box) { return; }

		box.addEventListener('click', function (event) {
			var button = event.target.closest('.usage-range-btn');
			if (!button) { return; }

			var buttons = box.querySelectorAll('.usage-range-btn');
			for (var i = 0; i < buttons.length; i++) { buttons[i].classList.remove('active'); }
			button.classList.add('active');

			currentRange = button.getAttribute('data-range');
			paint();
		});
		wired = true;
	}

	function paint() {
		paintKpis(currentRange);
		drawArea(currentRange);
		drawServers(currentRange);
		drawQuota();
	}

	return function () {
		if (typeof ApexCharts === 'undefined') { return; }
		wire();
		paint();
	};
})();
</script>
{/literal}

<script>
	window.addEventListener('on-hs-appearance-change', () => renderUsageCharts());
	renderUsageCharts();
	
	{if $bought > 0 && $Order->getSubsciption($user->id) != null && $Order->getPackage($user->id)}
	
	$('.renew').click(function(e) {
		{if $Order->getPackage($user->id)->renew_type == 1}
			var Note = "{$translate->get('RenewPlanNote1')}";
		{elseif $Order->getPackage($user->id)->renew_type == 2}
			var Note = "{$translate->get('RenewPlanNote2')}";
		{elseif $Order->getPackage($user->id)->renew_type == 3}
			var Note = "{$translate->get('RenewPlanNote3')}";
		{elseif $Order->getPackage($user->id)->renew_type == 4}
			var Note = "{$translate->get('RenewPlanNote4')}";
		{elseif $Order->getPackage($user->id)->renew_type == 5}
			var Note = "{$translate->get('RenewPlanNote5')}";
		{elseif $Order->getPackage($user->id)->renew_type == 6}
			var Note = "{$translate->get('RenewPlanNote6')}";
		{/if}
		Swal.fire({
			title: '',
			html: Note,
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('RenewPlan')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1 ',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				RenewPlan();
			}
		});
	})	
	
	function RenewPlan(){
		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/portal/order/create",
			dataType: "json",
			data: {
				packageid : {$Order->getSubsciption($user->id)->packageid},
				plan: "{$Order->getSubsciption($user->id)->plan}",
				code: "",
				renew: 1,
				upgrade: 0,
				disableactive: 1
			},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == -4) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'error',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					});
				}else
				if (data.ret == 1) {
					window.location.href = data.url;
				}else
				if (data.ret == -1) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'info',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.location.href = data.url;
						}
					});
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}
	{/if}

	function TopupOptions() {
		$.ajax({
			type: "POST",
			url: "/portal/topup-options",
			dataType: "json",
			data: {
				packageid: $('#tpackage').val(),
			},
			success: (data) => {
				$('#tplan').html('');
				if (data.package) {
					$.each(data.package, function (key, value) { 
						$("#tplan").append('<option value="' + key + '"> {$Config['default_currency_symbol']} '+value.price+'</option>');
					});
					$("#plan_topup").modal('show');
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
			}
		});	
	}
	

	$('.topupplan').click(function(e) {
		e.preventDefault();
		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/portal/order/create",
			dataType: "json",
			data: {
				packageid : $("#tpackage").val(),
				plan: "topup",
				code: "",
				renew: 0,
				upgrade: 0,
				disableactive: 1
			},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == -4) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'error',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					});
				}else
				if (data.ret == 1) {
					window.location.href = data.url;
				}else
				if (data.ret == -1) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'info',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.location.href = data.url;
						}
					});
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
					time: 3000,
					offset:  '100px'
				});
			}
		});
	})	

	
	function UpgradeOptions() {
		$.ajax({
			type: "POST",
			url: "/portal/package-options",
			dataType: "json",
			data: {
				packageid: $('#package').val(),
			},
			success: (data) => {
			
				$('#plan').html('');
				if (data.package) {
					$.each(data.package, function (key, value) { 
					    if(key != "" || value != ""){
							$("#plan").append('<option value="' + key + '"> {$Config['default_currency_symbol']} '+value.price+' '+value.expire+'</option>');
						}
					});
					$("#plan_upgrade").modal('show');
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
			}
		});	
	}	
	

	$('.upgrade').click(function(e) {
		e.preventDefault();
		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/portal/order/create",
			dataType: "json",
			data: {
				packageid : $("#package").val(),
				plan: $("#plan").val(),
				code: "",
				renew: 0,
				upgrade: 1,
				disableactive: 1
			},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == -4) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'error',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					});
				}else
				if (data.ret == 1) {
					window.location.href = data.url;
				}else
				if (data.ret == -1) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'info',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.location.href = data.url;
						}
					});
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 3000,
						offset:  '100px'
					});
			}
		});
	})

	$(document).ready(function () {
		function noticemodal(){
			$('#noticemodal').modal('show');
		}		
		var my_cookie = $.cookie($('.modal-check').attr('name'));
		if (my_cookie && my_cookie == "true") {
			$(this).prop('checked', my_cookie);
		}else{
			{if $Config['latest_notice'] == 1}
				noticemodal();
			{/if}
		}
		$(".modal-check").change(function() {
			$.cookie($(this).attr("name"), $(this).prop('checked'), {
				path: '/',
				expires: 1
			});
		});	
	});	

	function RsetLink(){
		Swal.fire({
			title: '',
			html:  "{$translate->get('ResetSubLinkNpte')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: '{$translate->get('Continue')}',
			cancelButtonText: '{$translate->get('Cancel')}',
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-sm btn-secondary ms-1',
				cancelButton: 'btn btn-sm  btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				ResetLink();
			}	
		});
	}

	function ResetLink(){
		$.ajax({
			type: "POST",
			url: "/portal/settings/reset_token",
			dataType: "json",
			data: {},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
					window.location.reload();
				}
				else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			}
		});
	}	

    function AddSub(url,jumpurl="") {
		Swal.fire({
			title: '',
			text:  '{$translate->get('importshad')}',
			icon: 'info',
			showCancelButton: true,
			confirmButtonText: '{$translate->get('Export')}',
			cancelButtonText: '{$translate->get('Cancel')}',
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1 ',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				let tmp = window.btoa(url);
				window.location.href = jumpurl + tmp;
			}
		})
    }	
	
	function RedeemCard(){
		$('#redeem_modal').modal('show');
	}
	
	function Redeem(){
		$.ajax({
			type: "POST",
			url: "/portal/redeem",
			dataType: "json",
			data: {
				code: $('#code').val()
			},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 2000,
						offset:  '100px'
					});
					$('#redeem_modal').modal('hide');
					$('#money').html(data.money);
				}
				else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
			}
		});
	}
</script>

{$newCommissions = $user->newCommissions()}
{if count($newCommissions) > 0}
{$firstCommission = $newCommissions[0]}
<script>
	/* CommissionPopup - fires once, reading the rows marks them as seen */
	window.setTimeout(function () {
		Swal.fire({
			title: "{$translate->get('CommissionPopupTitle')|escape:'javascript'}",
			html: "{if $firstCommission->destination == 'payout'}{$translate->get('CommissionPopupPayout')|escape:'javascript'}{else}{$translate->get('CommissionPopupBody')|escape:'javascript'}{/if}"
				.replace('%amount%', "{$currency->symbol_left} {number_format((float)$firstCommission->amount, (int)$currency->decimals)} {$currency->symbol_right}")
				.replace('%user%', "{$firstCommission->buyer_username|escape:'javascript'}"),
			icon: 'success',
			showCancelButton: false,
			showConfirmButton: true,
			confirmButtonText: "{$translate->get('ok')|escape:'javascript'}",
			customClass: {
				confirmButton: 'btn btn-success ms-1'
			},
			buttonsStyling: false
		});
	}, 900);
</script>
{/if}
