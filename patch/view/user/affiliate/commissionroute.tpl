{if $user->commissionChoiceEnabled()}
<div class="row mb-3" id="cmRouteCard" data-saved="{$translate->get('CommissionChoiceSaved')|escape:'html'}">
	<div class="col-12">
		<div class="card card-shadow shadow-lg rounded cm-card">
			<div class="card-body d-flex flex-wrap align-items-center gap-2">
				<div class="me-auto">
					<div class="fw-bold">🤝 {$translate->get('CommissionChoiceTitle')}</div>
					<div class="text-muted small">{$translate->get('CommissionChoiceHint')}</div>
				</div>
				<select class="form-select shadow-lg" id="cmRouteSelect" style="max-width:280px">
					<option value="payout">{$translate->get('CommissionDestPayout')}</option>
					<option value="money">{$translate->get('CommissionDestMoney')}</option>
					<option value="wallet">{$translate->get('CommissionDestWallet')}</option>
				</select>
				<button type="button" class="btn btn-dark" id="cmRouteSave">{$translate->get('Submit')}</button>
			</div>
			<div class="small px-3 pb-3" id="cmRouteMsg"></div>
		</div>
	</div>
</div>

{literal}
<script>
(function () {
	var url = '/xmplus-patch.php?do=commission.pref';
	var card = document.getElementById('cmRouteCard');
	var select = document.getElementById('cmRouteSelect');
	var save = document.getElementById('cmRouteSave');
	var msg = document.getElementById('cmRouteMsg');
	if (!card || !select || !save) { return; }

	var token = '';

	function say(text, bad) {
		msg.textContent = text || '';
		msg.style.color = bad ? '#dc2626' : '#059669';
	}

	fetch(url, { credentials: 'same-origin' })
		.then(function (r) { return r.json(); })
		.then(function (data) {
			if (!data.ok || !data.enabled) { card.hidden = true; return; }
			token = data.token || '';
			var allowed = data.options || [];
			Array.prototype.forEach.call(select.options, function (opt) {
				var shown = allowed.indexOf(opt.value) !== -1;
				opt.disabled = !shown;
				opt.hidden = !shown;
			});
			select.value = data.effective || (allowed[0] || 'money');
		})
		.catch(function () { card.hidden = true; });

	save.addEventListener('click', function () {
		save.disabled = true;
		var body = new FormData();
		body.append('token', token);
		body.append('destination', select.value);

		fetch(url, { method: 'POST', body: body, credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (data) {
				save.disabled = false;
				if (!data.ok) { say(data.error || 'error', true); return; }
				token = data.token || token;
				say(card.getAttribute('data-saved'), false);
			})
			.catch(function () {
				save.disabled = false;
				say('network error', true);
			});
	});
})();
</script>
{/literal}
{/if}
