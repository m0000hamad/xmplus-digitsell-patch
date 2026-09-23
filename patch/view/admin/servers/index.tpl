{include file='admin/layout/header.tpl'}
	<script>localStorage.setItem('toggleID', 'serversMenu'); </script>	
	<style>
		.nav-pills .nav-item .nav-link.active {
			background-color: var(--bs-dark);
			color:var(--bs-body-bg);
		}
	</style>  
	
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('ServerList')}</h1>
			</div>
			<div class="col-sm-auto">
				<a href="/admin/server/add" class="btn btn-sm btn-dark" >{$translate->get('AddServer')}</a>
			</div>
        </div>
    </div>
	  
	<div class="row match-height">
			<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
				<div class="card mb-3 mb-lg-5 card-shadow shadow-lg rounded">
				
					<div class="card-header card-header-content-between border-bottom">						
						<h4 class="page-header-title">{$translate->get('List')}</h4>
						<div class="col-xl-2">
							<div class="mb-2 mb-md-0">
								<form>
									<div class="input-group input-group-merge input-group-flush">
										<div class="input-group-prepend input-group-text">
											<i class="bi-search"></i>
										</div>
										<input id="tableSearch" type="search" class="form-control" placeholder="{$translate->get('sSearch')}" aria-label="{$translate->get('sSearch')}">
									</div>
								</form>
							</div>
						</div>
					</div>
					
					<div class="card-body">
						{include file='table/columns.tpl'}
						<div class="table-responsive">
							{include file='table/datatable.tpl'}								
						</div>				
					</div>
				</div>
			</div>
	</div>
	<div class="row">
			<div class="col-12 mb-3 mb-lg-5">
				<div class="card card-shadow shadow-lg rounded su-card" id="serverUsageCard">
					<div class="card-header card-header-content-between border-bottom flex-wrap gap-2">
						<h4 class="page-header-title mb-0">{$translate->get('ServerUsageTitle')}</h4>
						<ul class="nav nav-pills nav-sm su-tabs" role="tablist">
							<li class="nav-item"><a class="nav-link active" href="javascript:;" data-range="day">{$translate->get('ServerUsageDay')}</a></li>
							<li class="nav-item"><a class="nav-link" href="javascript:;" data-range="week">{$translate->get('ServerUsageWeek')}</a></li>
							<li class="nav-item"><a class="nav-link" href="javascript:;" data-range="month">{$translate->get('ServerUsageMonth')}</a></li>
						</ul>
					</div>
					<div class="card-body">
						<div class="su-state text-muted small" id="serverUsageState"></div>
						<div class="su-chart-wrap"><canvas id="serverUsageChart"></canvas></div>
						<div class="su-rank" id="serverUsageRank"></div>
						<div class="su-foot text-muted small" id="serverUsageFoot"></div>
					</div>
				</div>
			</div>
	</div>
	<style>
		{literal}
		.su-chart-wrap { position: relative; height: 320px; }
		.su-tabs .nav-link { padding: .3rem .8rem; font-size: .8125rem; }
		.su-rank { margin-top: 1.25rem; display: grid; gap: .55rem; }
		.su-row { display: grid; grid-template-columns: minmax(90px, 180px) 1fr auto; gap: .75rem; align-items: center; font-size: .8125rem; }
		.su-name { display: flex; align-items: center; gap: .45rem; min-width: 0; font-weight: 600; }
		.su-name span:last-child { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
		.su-dot { width: 10px; height: 10px; border-radius: 3px; flex: 0 0 10px; }
		.su-bar { height: 8px; border-radius: 999px; background: rgba(127, 127, 127, .15); overflow: hidden; }
		.su-bar i { display: block; height: 100%; border-radius: 999px; }
		.su-val { white-space: nowrap; font-variant-numeric: tabular-nums; }
		.su-val small { opacity: .65; margin-inline-start: .35rem; }
		.su-foot { margin-top: 1rem; }
		.su-badge { display: flex; flex-wrap: wrap; gap: .3rem; margin-top: .3rem; font-size: .72rem; font-weight: 500; }
		.su-badge b { font-weight: 600; padding: .1rem .45rem; border-radius: 999px; background: rgba(55, 125, 255, .1); color: #377dff; white-space: nowrap; }
		.su-badge b.su-top { background: rgba(237, 76, 120, .12); color: #ed4c78; }
		html[data-hs-theme="dark"] .su-badge b { background: rgba(55, 125, 255, .18); color: #8fb5ff; }
		html[data-hs-theme="dark"] .su-badge b.su-top { background: rgba(237, 76, 120, .2); color: #ff8fae; }
		@media (max-width: 575px) {
			.su-chart-wrap { height: 260px; }
			.su-row { grid-template-columns: 1fr auto; }
			.su-row .su-bar { grid-column: 1 / -1; order: 3; }
		}
		{/literal}
	</style>
{include file='admin/layout/footer.tpl'}

<script>
    {include file='table/table_storage.tpl'}
	{include file='table/table_asc.tpl'}
	
    function deleteServer(id) {
        deleteid = id;
		Swal.fire({
			title: "{$translate->get('ConfirmDelete')}",
			text: "{$translate->get('ConfirmDeleteNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Delete')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				delete_id();
			}
		});
    }

	function delete_id() {
        $.ajax({
            type: "DELETE",
            url: "/admin/server/delete",
            dataType: "json",
            data: {
                id: deleteid
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    {include file='table/reload.tpl'}
                } else {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
            }
        });
    }	
	
	function ServerStatus(id) {
		if (document.getElementById('status_'+id).checked) {
			var status = 1;
		} else  {
			var status = 0;
		}
		$.ajax({
			type: "POST",
			url: "/admin/server/status",
			dataType: "json",
			data: {
				id: id,
				status : status
			},
			success: (data) => {
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
            }
		});			
	}	
	
	function cloneServer(id) {
		Swal.fire({
			title: "{$translate->get('ConfirmClone')}",
			text: "{$translate->get('ConfirmCloneNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Clone')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				clone(id);
			}
		});
    }
	
	function clone(id) {
		$.ajax({
			type: "POST",
			url: "/admin/server/"+ id +"/clone",
			dataType: "json",
			data: {},
			success: (data) => {
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					{include file='table/reload.tpl'}		
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
            }
		});			
	}
</script>
<script>
	var serverUsageText = {
		today: "{$translate->get('ServerUsageToday')}",
		week: "{$translate->get('ServerUsageWeekShort')}",
		month: "{$translate->get('ServerUsageMonthShort')}",
		total: "{$translate->get('ServerUsageTotal')}",
		empty: "{$translate->get('ServerUsageEmpty')}",
		since: "{$translate->get('ServerUsageSince')}",
		error: "{$translate->get('ServerUsageLoadError')}"
	};
</script>
<script>
{literal}
(function () {
	var COLORS = ['#377dff', '#ed4c78', '#00c9a7', '#f5ca99', '#7a5af8', '#09a5be', '#f58b3d', '#71869d', '#9ccc65', '#e45b9b', '#4e5d78', '#c7a26a'];
	var data = null, chart = null, range = 'day';

	function fmt(gb) {
		gb = Number(gb) || 0;
		if (gb >= 1024) { return (gb / 1024).toFixed(2) + ' TB'; }
		if (gb >= 100) { return gb.toFixed(0) + ' GB'; }
		return gb.toFixed(gb >= 10 ? 1 : 2) + ' GB';
	}

	function esc(text) {
		return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}

	function colorOf(id) {
		var index = 0;
		data.servers.forEach(function (s, i) { if (s.id === id) { index = i; } });
		return COLORS[index % COLORS.length];
	}

	function textColor() {
		return getComputedStyle(document.body).color || '#677788';
	}

	function rangeTotals(key) {
		var series = data.ranges[key].series, out = [];
		data.servers.forEach(function (s) {
			var values = series[String(s.id)] || [], sum = 0;
			values.forEach(function (v) { sum += Number(v) || 0; });
			out.push({ server: s, total: sum });
		});
		out.sort(function (a, b) { return b.total - a.total; });
		return out;
	}

	function drawChart() {
		var r = data.ranges[range];
		var labels = r.labels.map(function (l) { return range === 'day' ? l : l.slice(5); });
		var datasets = data.servers.map(function (s) {
			return {
				label: s.name,
				data: r.series[String(s.id)] || [],
				backgroundColor: colorOf(s.id),
				borderWidth: 0,
				maxBarThickness: 28
			};
		});
		var fg = textColor();

		if (chart) { chart.destroy(); }
		chart = new Chart(document.getElementById('serverUsageChart').getContext('2d'), {
			type: 'bar',
			data: { labels: labels, datasets: datasets },
			options: {
				responsive: true,
				maintainAspectRatio: false,
				animation: { duration: 300 },
				legend: { position: 'bottom', labels: { fontColor: fg, boxWidth: 12 } },
				tooltips: {
					mode: 'index',
					intersect: false,
					itemSort: function (a, b) { return b.yLabel - a.yLabel; },
					filter: function (item) { return Number(item.yLabel) > 0; },
					callbacks: {
						label: function (item, d) { return d.datasets[item.datasetIndex].label + ': ' + fmt(item.yLabel); },
						footer: function (items) {
							var sum = 0;
							items.forEach(function (i) { sum += Number(i.yLabel) || 0; });
							return serverUsageText.total + ': ' + fmt(sum);
						}
					}
				},
				scales: {
					xAxes: [{ stacked: true, gridLines: { display: false }, ticks: { fontColor: fg, autoSkip: true, maxRotation: 0 } }],
					yAxes: [{ stacked: true, gridLines: { color: 'rgba(127,127,127,.15)', zeroLineColor: 'rgba(127,127,127,.25)' }, ticks: { fontColor: fg, beginAtZero: true, callback: function (v) { return fmt(v); } } }]
				}
			}
		});
	}

	function drawRank() {
		var rows = rangeTotals(range), grand = 0, html = '';
		rows.forEach(function (r) { grand += r.total; });
		if (grand <= 0) {
			document.getElementById('serverUsageRank').innerHTML = '';
			document.getElementById('serverUsageState').textContent = serverUsageText.empty;
			return;
		}
		document.getElementById('serverUsageState').textContent = '';
		var top = rows[0].total || 1;
		rows.forEach(function (r) {
			if (r.total <= 0) { return; }
			var color = colorOf(r.server.id);
			html += '<div class="su-row">' +
				'<div class="su-name"><span class="su-dot" style="background:' + color + '"></span><span>' + esc(r.server.name) + '</span></div>' +
				'<div class="su-bar"><i style="width:' + (r.total / top * 100).toFixed(1) + '%;background:' + color + '"></i></div>' +
				'<div class="su-val">' + fmt(r.total) + '<small>' + (r.total / grand * 100).toFixed(1) + '%</small></div>' +
				'</div>';
		});
		html += '<div class="su-row"><div class="su-name">' + serverUsageText.total + '</div><div></div><div class="su-val">' + fmt(grand) + '</div></div>';
		document.getElementById('serverUsageRank').innerHTML = html;
	}

	function render() {
		drawChart();
		drawRank();
	}

	/* The server list is a DataTable fed by the encoded controller, so usage
	   is written into the name cell after every draw instead of being a real
	   column. A row whose id or name cannot be matched is left alone. */
	function badges() {
		if (!data) { return; }
		var byId = {}, byName = {}, leader = data.servers.length ? data.servers[0].id : null;
		data.servers.forEach(function (s) { byId[s.id] = s; byName[String(s.name).trim()] = s; });

		$('table tbody tr').each(function () {
			var row = this;
			if (row.querySelector('.su-badge')) { return; }
			var match = row.innerHTML.match(/deleteServer\((\d+)\)|cloneServer\((\d+)\)|status_(\d+)|\/admin\/server\/(\d+)/);
			var cells = row.querySelectorAll('td'), server = null, target = null;
			if (match) { server = byId[Number(match[1] || match[2] || match[3] || match[4])] || null; }

			for (var i = 0; i < cells.length; i++) {
				var hit = byName[cells[i].textContent.trim()];
				if (hit && (!server || hit === server)) {
					target = cells[i];
					server = hit;
					break;
				}
			}
			if (!server) { return; }
			if (!target) { target = cells.length > 1 ? cells[1] : cells[0]; }
			if (!target) { return; }

			var badge = document.createElement('div');
			badge.className = 'su-badge';
			badge.innerHTML =
				'<b' + (server.id === leader ? ' class="su-top"' : '') + '>' + serverUsageText.today + ' ' + fmt(server.today) + '</b>' +
				'<b>' + serverUsageText.week + ' ' + fmt(server.week) + '</b>' +
				'<b>' + serverUsageText.month + ' ' + fmt(server.month) + '</b>';
			target.appendChild(badge);
		});
	}

	$('#serverUsageCard .su-tabs').on('click', '.nav-link', function () {
		$('#serverUsageCard .su-tabs .nav-link').removeClass('active');
		$(this).addClass('active');
		range = $(this).data('range');
		if (data) { render(); }
	});

	if (typeof table_1 !== 'undefined' && table_1 && table_1.on) {
		table_1.on('draw', badges);
	}

	$.ajax({
		type: 'GET',
		url: '/xmplus-patch.php?do=servers.usage',
		dataType: 'json',
		success: function (res) {
			if (!res || !res.ok) {
				document.getElementById('serverUsageState').textContent = serverUsageText.error + (res && res.error ? ' - ' + res.error : '');
				return;
			}
			data = res;
			document.getElementById('serverUsageFoot').textContent = serverUsageText.since + ' ' + res.since + ' · ' + res.generated;
			render();
			badges();
		},
		error: function () {
			document.getElementById('serverUsageState').textContent = serverUsageText.error;
		}
	});
})();
{/literal}
</script>
