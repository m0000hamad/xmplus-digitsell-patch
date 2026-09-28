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
		endsIs: "{$translate->get('PromoEndsIs')|escape:'javascript'}",
		endsBad: "{$translate->get('PromoEndsBad')|escape:'javascript'}"
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

	/* Solar Hijri -> Gregorian [y, m, d] (the same arithmetic as Promo.php) */
	function promoJalaliToGregorian(jy, jm, jd) {
		jy += 1595;
		var days = -355668 + 365 * jy + Math.floor(jy / 33) * 8 + Math.floor((jy % 33 + 3) / 4) + jd
			+ (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);
		var gy = 400 * Math.floor(days / 146097);
		days %= 146097;
		if (days > 36524) {
			days--;
			gy += 100 * Math.floor(days / 36524);
			days %= 36524;
			if (days >= 365) {
				days++;
			}
		}
		gy += 4 * Math.floor(days / 1461);
		days %= 1461;
		if (days > 365) {
			gy += Math.floor((days - 1) / 365);
			days = (days - 1) % 365;
		}
		var gd = days + 1;
		var leap = (gy % 4 === 0 && gy % 100 !== 0) || gy % 400 === 0;
		var months = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
		var gm = 0;
		for (; gm < 13 && gd > months[gm]; gm++) {
			gd -= months[gm];
		}
		return [gy, gm, gd];
	}

	/* "1405/07/30 23:59" (Persian digits too) -> epoch ms on Tehran time (+03:30,
	   no daylight saving since 2022), or null. The time is optional (23:59). */
	function promoEndsStamp(raw) {
		var clean = String(raw || "").replace(/[۰-۹]/g, function (d) {
			return String("۰۱۲۳۴۵۶۷۸۹".indexOf(d));
		}).replace(/[-.]/g, "/").trim();
		var m = /^(\d{4})\/(\d{1,2})\/(\d{1,2})(?:[ T]+(\d{1,2}):(\d{2}))?$/.exec(clean);
		if (!m) {
			return null;
		}
		var y = +m[1], mo = +m[2], d = +m[3];
		var h = m[4] === undefined ? 23 : +m[4], mi = m[5] === undefined ? 59 : +m[5];
		if (y >= 1300 && y < 1600) {
			if (mo < 1 || mo > 12 || d < 1 || d > (mo <= 6 ? 31 : 30)) {
				return null;
			}
			var g = promoJalaliToGregorian(y, mo, d);
			// 30 Esfand only in a leap year
			if (mo === 12 && d === 30 && String(g) === String(promoJalaliToGregorian(y + 1, 1, 1))) {
				return null;
			}
			y = g[0]; mo = g[1]; d = g[2];
		}
		if (h > 23 || mi > 59) {
			return null;
		}
		return Date.UTC(y, mo - 1, d, h, mi) - 3.5 * 3600 * 1000;
	}

	/* the end date read back in words, and whether it has passed */
	function promoEndsCheck() {
		var raw = $("#promo_ends_at").val();
		var note = $("#promo_ends_note");

		if (!$.trim(raw)) {
			note.prop("hidden", true).text("");
			return true;
		}

		var stamp = promoEndsStamp(raw);
		if (stamp === null) {
			note.prop("hidden", false).removeClass("text-success").addClass("text-danger")
				.text("⚠️ " + promoText.endsBad);
			return false;
		}

		var shown = "";
		try {
			shown = new Date(stamp).toLocaleString("fa-IR-u-ca-persian", {
				timeZone: "Asia/Tehran", year: "numeric", month: "long", day: "numeric",
				hour: "2-digit", minute: "2-digit", hour12: false
			});
		} catch (e) {}

		var past = stamp <= Date.now();
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
