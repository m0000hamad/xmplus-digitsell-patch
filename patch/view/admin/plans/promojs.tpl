{*
  Behaviour of the promotion fields (promoform.tpl), shared by add.tpl and
  edit.tpl. Needs timeplanjs.tpl first: the patch endpoint's token comes from
  its bootstrap (timeplanToken).
*}
<script>
	var promoText = {
		cycles: {
			onetime: "{$translate->get('Onetime')|escape:'javascript'}",
			month: "{$translate->get('Monthly')|escape:'javascript'}",
			quater: "{$translate->get('Quaterly')|escape:'javascript'}",
			semiannual: "{$translate->get('SemiAnnually')|escape:'javascript'}",
			annual: "{$translate->get('Annually')|escape:'javascript'}",
			custom: "{$translate->get('Custom')|escape:'javascript'}"
		},
		empty: "{$translate->get('PromoPreviewEmpty')|escape:'javascript'}",
		saved: "{$translate->get('PromoSaved')|escape:'javascript'}",
		unreachable: "{$translate->get('PromoUnreachable')|escape:'javascript'}",
		endsPast: "{$translate->get('PromoEndsPast')|escape:'javascript'}",
		endsIs: "{$translate->get('PromoEndsIs')|escape:'javascript'}"
	};
	/* the occasion line an occasion theme fills in when the field is still empty */
	var promoThemeText = new Object();
	promoThemeText.nowruz    = "{$translate->get('PromoOccasionNowruz')|escape:'javascript'}";
	promoThemeText.yalda     = "{$translate->get('PromoOccasionYalda')|escape:'javascript'}";
	promoThemeText.christmas = "{$translate->get('PromoOccasionChristmas')|escape:'javascript'}";
	promoThemeText.mother    = "{$translate->get('PromoOccasionMother')|escape:'javascript'}";
	promoThemeText.father    = "{$translate->get('PromoOccasionFather')|escape:'javascript'}";
	promoThemeText.girl      = "{$translate->get('PromoOccasionGirl')|escape:'javascript'}";
	promoThemeText.boy       = "{$translate->get('PromoOccasionBoy')|escape:'javascript'}";
</script>
{literal}
<script>
	var promoCycles = ["onetime", "month", "quater", "semiannual", "annual", "custom"];

	function promoNumber(value) {
		var clean = String(value || "").replace(/[,\s،]/g, "");
		return clean === "" || isNaN(clean) ? null : parseFloat(clean);
	}

	/* the same rounding as the server: a whole unit */
	function promoDiscounted(price, percent) {
		return Math.round(price * (100 - percent) / 100);
	}

	/* shows or hides the promotion box (subscription plans only) and its parts */
	function promoApply() {
		var box = document.getElementById("promobox");
		if (!box) {
			return;
		}

		var isPlan = $("#type").val() == 2;
		var kind = $("#promo_kind").val();
		var prize = $("#promo_prize_on").is(":checked");
		var mode = $("#promo_prize_mode").val();

		box.hidden = !isPlan;
		document.getElementById("promo_discount_fields").hidden = kind !== "discount";
		document.getElementById("promo_prize_fields").hidden = !prize;
		document.getElementById("promo_gb_row").hidden = mode === "days";
		document.getElementById("promo_days_row").hidden = mode === "gb";
		document.getElementById("promo_extra_fields").hidden = kind === "none" && !prize;

		promoPreview();
	}

	/* an occasion theme writes its occasion line, but never over the admin's own text */
	function promoThemePicked() {
		var theme = $("#promo_theme").val();
		var field = $("#promo_occasion");
		var current = $.trim(field.val());
		var ours = false;

		for (var key in promoThemeText) {
			if (promoThemeText.hasOwnProperty(key) && current === promoThemeText[key]) {
				ours = true;
			}
		}

		if (promoThemeText.hasOwnProperty(theme) && (current === "" || ours)) {
			field.val(promoThemeText[theme]);
		} else if (ours) {
			field.val("");
		}
	}

	/* the end date read back in the Solar Hijri calendar, and whether it has passed.
	   A Solar Hijri year typed straight into the field (1405-...) is converted by
	   the server, so it is only named here, never refused. */
	function promoEndsCheck() {
		var raw = $("#promo_ends_at").val();
		var note = $("#promo_ends_note");

		if (!raw) {
			note.prop("hidden", true).text("");
			return true;
		}

		var year = parseInt(raw.substr(0, 4), 10);
		if (year < 1600) {
			note.prop("hidden", true).text("");
			return true;
		}

		var when = new Date(raw);
		if (isNaN(when.getTime())) {
			note.prop("hidden", true).text("");
			return true;
		}

		var shown = raw.replace("T", " ");
		try {
			shown = when.toLocaleString("fa-IR-u-ca-persian", {
				year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
			});
		} catch (e) {}

		var past = when.getTime() <= Date.now();
		note.prop("hidden", false)
			.toggleClass("text-danger", past)
			.toggleClass("text-success", !past)
			.text((past ? "⚠️ " + promoText.endsPast : "✅ " + promoText.endsIs) + " " + shown);

		return !past;
	}

	/* list price -> price after the discount, for every cycle that has a price */
	function promoPreview() {
		var target = $("#promo_preview");
		if (!target.length) {
			return;
		}

		var percent = parseInt($("#promo_percent").val(), 10);
		var valid = percent >= 1 && percent <= 95;

		target.html("");

		$.each(promoCycles, function (i, cycle) {
			var price = promoNumber($("input[name='" + cycle + "[price]']").val());
			if (price === null) {
				return;
			}

			var chip = $('<span class="badge bg-soft-dark text-dark p-2" dir="auto"></span>');
			chip.append($("<span></span>").text(promoText.cycles[cycle] + ": "));
			chip.append($('<s class="text-muted me-1" dir="ltr"></s>').text(price.toLocaleString("en-US")));
			chip.append($('<b class="text-success" dir="ltr"></b>').text(
				valid ? promoDiscounted(price, percent).toLocaleString("en-US") : "—"));
			target.append(chip);
		});

		if (!target.children().length) {
			target.append($('<span class="text-muted small"></span>').text(promoText.empty));
		}
	}

	/* after /admin/plan/save wrote the list prices; id 0 finds a new plan by name */
	function promoSave(id, done) {
		if ($("#type").val() != 2) {
			done();
			return;
		}

		if (typeof timeplanReady === "undefined" || !timeplanReady) {
			layer.msg(promoText.unreachable, { time: 6000, offset: "100px" });
			return;
		}

		if (($("#promo_kind").val() !== "none" || $("#promo_prize_on").is(":checked")) && !promoEndsCheck()) {
			// the plan itself is already saved; only the promotion waits for a later end date
			layer.msg($("#promo_ends_note").text(), { time: 7000, offset: "100px" });
			$("#promo_ends_at").trigger("focus");
			return;
		}

		$.ajax({
			type: "POST",
			url: "/xmplus-patch.php?do=promo.save",
			dataType: "json",
			data: {
				token: timeplanToken,
				id: id,
				name: $("#name").val(),
				kind: $("#promo_kind").val(),
				percent: $("#promo_percent").val(),
				prize_on: $("#promo_prize_on").is(":checked") ? 1 : 0,
				prize_mode: $("#promo_prize_mode").val(),
				gb_min: $("#promo_gb_min").val(),
				gb_max: $("#promo_gb_max").val(),
				days_min: $("#promo_days_min").val(),
				days_max: $("#promo_days_max").val(),
				occasion: $("#promo_occasion").val(),
				ends_at: $("#promo_ends_at").val(),
				max_sales: $("#promo_max_sales").val(),
				show_left: $("#promo_show_left").is(":checked") ? 1 : 0,
				announce: $("#promo_announce").is(":checked") ? 1 : 0,
				channel: $("#promo_channel").is(":checked") ? 1 : 0,
				theme: $("#promo_theme").val()
			},
			success: function (data) {
				if (!data.ok) {
					// the plan itself is saved with its list prices; only the promotion was refused
					layer.msg(data.error, { time: 7000, offset: "100px" });
					return;
				}

				if (data.running) {
					layer.msg(promoText.saved, { time: 2000, offset: "100px" });
				}

				window.setTimeout(done, 900);
			},
			error: function (jqXHR) {
				layer.msg(jqXHR.responseText, { time: 7000, offset: "100px" });
			}
		});
	}

	$(document).on("input", "input[name$='[price]']", promoPreview);
	$(document).on("input change", "#promo_ends_at", promoEndsCheck);
	$(function () { promoEndsCheck(); });
</script>
{/literal}
