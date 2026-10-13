{*
  Plan reservations - admin side.
  Included by settings.tpl; everything is read from and written to
  /xmplus-patch.php?do=reserve.* (app/Patch/Reserve.php).
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="ReserveSettings">
	<div class="card-header">
		<h4 class="card-header-title">🗓️ {$translate->get('ReserveAdmTitle')}</h4>
	</div>
	<div class="card-body rs">
		<p class="text-muted small">{$translate->get('ReserveAdmIntro')}</p>

		<div class="rs-kpis" id="rsKpis"></div>

		<h5 class="rs-h">⚙️ {$translate->get('ReserveAdmSettings')}</h5>
		<div class="row g-3">
			<div class="col-md-6">
				<label class="form-check">
					<input class="form-check-input" type="checkbox" id="rs_enabled">
					<span class="form-check-label">{$translate->get('ReserveAdmEnabled')}</span>
				</label>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="rs_max_days">{$translate->get('ReserveAdmMaxDays')}</label>
				<input type="number" class="form-control" id="rs_max_days" min="1" max="3650" dir="ltr">
				<small class="text-muted">{$translate->get('ReserveAdmMaxDaysHint')}</small>
			</div>
		</div>
		<div class="d-flex justify-content-end align-items-center gap-3 mt-3">
			<span class="rs-status" id="rsStatus" role="status"></span>
			<button type="button" class="btn btn-primary" id="rsSave">💾 {$translate->get('Save')}</button>
		</div>

		<h5 class="rs-h">📋 {$translate->get('ReserveAdmList')}</h5>
		<div class="table-responsive">
			<table class="table table-sm">
				<thead><tr>
					<th>{$translate->get('ReserveAdmUser')}</th>
					<th>{$translate->get('ReserveAdmPlan')}</th>
					<th>{$translate->get('ReserveAdmCycle')}</th>
					<th>{$translate->get('ReserveAdmStarts')}</th>
					<th>{$translate->get('ReserveAdmAmount')}</th>
					<th>{$translate->get('ReserveAdmStatus')}</th>
				</tr></thead>
				<tbody id="rsList"></tbody>
			</table>
		</div>
	</div>
</div>

<script>
(function () {
	var token = '';

	function cycleWord(cycle) {
		var words = {
			month: "{$translate->get('Monthly')}",
			quater: "{$translate->get('Quaterly')}",
			semiannual: "{$translate->get('SemiAnnually')}",
			annual: "{$translate->get('Annually')}",
			custom: "{$translate->get('Custom')}"
		};
		return words[cycle] || cycle;
	}

	function statusWord(status) {
		var words = {
			'0': "{$translate->get('ReserveStatusPending')}",
			'1': "{$translate->get('ReserveStatusWaiting')}",
			'2': "{$translate->get('ReserveStatusActivated')}",
			'3': "{$translate->get('ReserveStatusCancelled')}"
		};
		return words[String(status)] || status;
	}

	function stamp(value) {
		if (!value) {
			return '—';
		}
		var d = new Date(Number(value) * 1000);
		return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
	}

	function load() {
		$.ajax({
			type: 'GET',
			url: '/xmplus-patch.php?do=reserve.admin',
			dataType: 'json',
			success: function (data) {
				if (!data.ok) {
					return;
				}

				token = data.token;
				$('#rs_enabled').prop('checked', data.settings.enabled == 1);
				$('#rs_max_days').val(data.settings.max_days);

				var c = data.counts || { };
				$('#rsKpis').html(
					'<span class="rs-chip">' + statusWord(0) + ': <b>' + (c.pending || 0) + '</b></span>' +
					'<span class="rs-chip">' + statusWord(1) + ': <b>' + (c.waiting || 0) + '</b></span>' +
					'<span class="rs-chip">' + statusWord(2) + ': <b>' + (c.activated || 0) + '</b></span>' +
					'<span class="rs-chip">' + statusWord(3) + ': <b>' + (c.cancelled || 0) + '</b></span>'
				);

				var rows = data.list || [];
				var body = $('#rsList').empty();

				if (!rows.length) {
					body.append('<tr><td colspan="6" class="text-muted">' + "{$translate->get('ReserveAdmEmpty')}" + '</td></tr>');
					return;
				}

				$.each(rows, function (i, r) {
					var starts = r.mode === 'date'
						? stamp(r.activate_at)
						: "{$translate->get('ReserveStartsAfter')}";
					var who = r.username ? (r.username + ' #' + r.userid) : ('#' + r.userid);
					body.append(
						'<tr><td>' + who + '</td><td>' + r.name + '</td><td>' + cycleWord(r.cycle) +
						'</td><td>' + starts + '</td><td>' + Number(r.amount).toLocaleString('en-US') +
						'</td><td>' + statusWord(r.status) + '</td></tr>'
					);
				});
			}
		});
	}

	$(function () {
		load();

		$('#rsSave').on('click', function () {
			$.ajax({
				type: 'POST',
				url: '/xmplus-patch.php?do=reserve.settings',
				dataType: 'json',
				data: {
					token: token,
					enabled: $('#rs_enabled').is(':checked') ? 1 : 0,
					max_days: $('#rs_max_days').val()
				},
				success: function (data) {
					if (data.ok) {
						$('#rsStatus').text("{$translate->get('ReserveAdmSaved')}");
						window.setTimeout(function () { $('#rsStatus').text(''); }, 2500);
						load();
					} else {
						$('#rsStatus').text(data.error || "{$translate->get('ReserveAdmError')}");
					}
				},
				error: function () {
					$('#rsStatus').text("{$translate->get('ReserveAdmError')}");
				}
			});
		});
	});
})();
</script>

{literal}
<style>
.rs-kpis { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
.rs-chip {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	background: rgba(99, 102, 241, .1);
	border-radius: 999px;
	padding: 5px 12px;
	font-size: 12px;
	font-weight: 600;
	color: #4338ca;
}
.rs-h { margin: 16px 0 10px; font-size: 14px; font-weight: 800; }
.rs-status { font-size: 12px; font-weight: 700; color: #047857; }
</style>
{/literal}
