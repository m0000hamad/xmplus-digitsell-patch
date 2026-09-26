{*
  The Telegram channel promotions are posted in (setting promo_channel_id).
  Included by settings.tpl under the patch updater; talks to
  /xmplus-patch.php?do=promo.channel / promo.channelsave / promo.channeltest.
  A plan's promotion goes there only when its "send to channel" switch is on.
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="PromoChannelSettings">
	<div class="card-header">
		<h4 class="card-header-title">📣 {$translate->get('PromoChannelTitle')}</h4>
	</div>
	<div class="card-body">
		<p class="text-muted small">{$translate->get('PromoChannelIntro')}</p>
		<div class="row mb-3">
			<label class="col-sm-3 col-form-label form-label" for="promoChannelId">{$translate->get('PromoChannelId')}</label>
			<div class="col-sm-9">
				<input type="text" class="form-control shadow-lg" id="promoChannelId" dir="ltr" placeholder="-1001234567890">
				<small class="text-muted">{$translate->get('PromoChannelIdHint')}</small>
			</div>
		</div>
		<div class="d-flex flex-wrap gap-2 justify-content-end">
			<button type="button" class="btn btn-outline-primary" id="promoChannelTest">✉️ {$translate->get('PromoChannelTest')}</button>
			<button type="button" class="btn btn-primary" id="promoChannelSave">💾 {$translate->get('Save')}</button>
		</div>
	</div>
</div>
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.PromoChannelWords = new Object();
	window.PromoChannelWords.saved = "{$translate->get('PromoChannelSaved')|escape:'javascript'}";
	window.PromoChannelWords.sent  = "{$translate->get('PromoChannelSent')|escape:'javascript'}";
</script>
{literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var token = '';
	var box = document.getElementById('promoChannelId');

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 6000, offset: '100px' });
		} else {
			alert(text);
		}
	}

	function post(action) {
		var body = new FormData();
		body.append('token', token);
		body.append('channel', box.value.trim());
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', body: body })
			.then(function (r) { return r.json(); });
	}

	fetch(endpoint + '?do=promo.channel', { credentials: 'same-origin' })
		.then(function (r) { return r.json(); })
		.then(function (data) {
			if (data.ok) {
				token = data.token || '';
				box.value = data.channel || '';
			}
		});

	document.getElementById('promoChannelSave').addEventListener('click', function () {
		post('promo.channelsave').then(function (data) {
			say(data.ok ? window.PromoChannelWords.saved : data.error);
		});
	});

	document.getElementById('promoChannelTest').addEventListener('click', function () {
		post('promo.channeltest').then(function (data) {
			say(data.ok ? window.PromoChannelWords.sent : data.error);
		});
	});
})();
</script>
{/literal}
