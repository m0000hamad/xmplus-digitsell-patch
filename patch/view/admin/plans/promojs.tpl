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
		endsBad: "{$translate->get('PromoEndsBad')|escape:'javascript'}",
		calToday: "{$translate->get('PromoCalToday')|escape:'javascript'}",
		calClear: "{$translate->get('PromoCalClear')|escape:'javascript'}",
		calDone: "{$translate->get('PromoCalDone')|escape:'javascript'}",
		calTime: "{$translate->get('PromoCalTime')|escape:'javascript'}"
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
<style>
	.promo-ends-wrap { position: relative; max-width: 22rem; }
	.promo-cal { position: absolute; z-index: 1060; top: calc(100% + 6px); inset-inline-start: 0; width: 19rem; background: var(--bs-body-bg, #fff); border: 1px solid rgba(127,127,127,.25); border-radius: 14px; padding: 10px; direction: rtl; }
	.promo-cal-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px; font-weight: 700; }
	.promo-cal-head button { border: 0; background: transparent; font-size: 20px; line-height: 1; padding: 2px 10px; border-radius: 8px; color: inherit; }
	.promo-cal-head button:hover { background: rgba(99,102,241,.12); }
	.promo-cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 3px; text-align: center; }
	.promo-cal-grid .wd { font-size: 11px; opacity: .6; padding: 2px 0; }
	.promo-cal-grid button { border: 0; background: transparent; border-radius: 8px; padding: 6px 0; font-size: 13px; color: inherit; }
	.promo-cal-grid button:hover:not([disabled]) { background: rgba(99,102,241,.14); }
	.promo-cal-grid button[disabled] { opacity: .3; cursor: not-allowed; }
	.promo-cal-grid button.is-fri { color: #e11d48; }
	.promo-cal-grid button.is-today { box-shadow: inset 0 0 0 1.5px #6366f1; }
	.promo-cal-grid button.is-sel, .promo-cal-grid button.is-sel:hover { background: #6366f1; color: #fff; font-weight: 700; }
	.promo-cal-foot { display: flex; align-items: center; gap: 6px; margin-top: 8px; flex-wrap: wrap; font-size: 13px; }
	.promo-cal-foot select { width: auto; padding: 2px 6px; }
	.promo-cal-foot .promo-cal-btns { margin-inline-start: auto; display: flex; gap: 4px; }
	.promo-ends-span { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; font-size: 13px; }
	.promo-ends-span input[type=number] { width: 5rem; }
	.promo-ends-span input[type=time] { width: 7.5rem; }
</style>
{/literal}
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

	/* ---- Solar Hijri calendar and "N days until HH:MM" for the end date ---- */
	var promoMonths = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
		"مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
	var promoWeekdays = ["ش", "ی", "د", "س", "چ", "پ", "ج"];
	var promoCal = null;

	function promoFa(n) {
		return String(n).replace(/[0-9]/g, function (d) { return "۰۱۲۳۴۵۶۷۸۹".charAt(+d); });
	}

	function promoPad(n) {
		return (n < 10 ? "0" : "") + n;
	}

	/* Gregorian -> Solar Hijri [y, m, d] (the same arithmetic as Package::jalaliParts) */
	function promoGregorianToJalali(gy, gm, gd) {
		var days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
		var gy2 = gm > 2 ? gy + 1 : gy;
		var total = 355666 + 365 * gy + Math.floor((gy2 + 3) / 4) - Math.floor((gy2 + 99) / 100)
			+ Math.floor((gy2 + 399) / 400) + gd + days[gm - 1];
		var jy = -1595 + 33 * Math.floor(total / 12053);
		total %= 12053;
		jy += 4 * Math.floor(total / 1461);
		total %= 1461;
		if (total > 365) {
			jy += Math.floor((total - 1) / 365);
			total = (total - 1) % 365;
		}
		var jm = total < 186 ? 1 + Math.floor(total / 31) : 7 + Math.floor((total - 186) / 30);
		var jd = 1 + (total < 186 ? total % 31 : (total - 186) % 30);
		return [jy, jm, jd];
	}

	function promoJalaliMonthDays(jy, jm) {
		if (jm <= 6) {
			return 31;
		}
		if (jm <= 11) {
			return 30;
		}
		return String(promoJalaliToGregorian(jy, 12, 30)) === String(promoJalaliToGregorian(jy + 1, 1, 1)) ? 29 : 30;
	}

	/* an epoch (ms) as Solar Hijri parts on Tehran time */
	function promoTehranParts(ms) {
		var t = new Date(ms + 3.5 * 3600 * 1000);
		var j = promoGregorianToJalali(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
		return { y: j[0], m: j[1], d: j[2], h: t.getUTCHours(), mi: t.getUTCMinutes() };
	}

	function promoSetEnds(y, m, d, h, mi) {
		$("#promo_ends_at").val(y + "/" + promoPad(m) + "/" + promoPad(d) + " " + promoPad(h) + ":" + promoPad(mi));
		promoEndsCheck();
	}

	function promoCalToggle() {
		var box = document.getElementById("promo_cal");
		if (!box.hidden) {
			box.hidden = true;
			return;
		}

		var stamp = promoEndsStamp($("#promo_ends_at").val());
		var today = promoTehranParts(Date.now());
		var at = stamp !== null ? promoTehranParts(stamp) : null;

		promoCal = {
			y: at ? at.y : today.y,
			m: at ? at.m : today.m,
			sel: at ? [at.y, at.m, at.d] : null,
			h: at ? at.h : 23,
			mi: at ? at.mi : 59,
			today: today
		};
		box.hidden = false;
		promoCalDraw();
	}

	function promoCalDraw() {
		var c = promoCal;
		var box = $("#promo_cal").empty();
		var head = $('<div class="promo-cal-head"></div>');
		head.append($('<button type="button" data-cal="prev">‹</button>'));
		head.append($("<span></span>").text(promoMonths[c.m - 1] + " " + promoFa(c.y)));
		head.append($('<button type="button" data-cal="next">›</button>'));
		box.append(head);

		var grid = $('<div class="promo-cal-grid"></div>');
		$.each(promoWeekdays, function (i, w) {
			grid.append($('<span class="wd"></span>').text(w));
		});

		// Saturday first: the column of day 1 comes from the Gregorian weekday
		var g = promoJalaliToGregorian(c.y, c.m, 1);
		var first = (new Date(Date.UTC(g[0], g[1] - 1, g[2])).getUTCDay() + 1) % 7;
		for (var i = 0; i < first; i++) {
			grid.append("<span></span>");
		}

		var total = promoJalaliMonthDays(c.y, c.m);
		var todayKey = c.today.y * 10000 + c.today.m * 100 + c.today.d;
		for (var d = 1; d <= total; d++) {
			var key = c.y * 10000 + c.m * 100 + d;
			var btn = $('<button type="button"></button>').text(promoFa(d)).attr("data-day", d);
			if ((first + d - 1) % 7 === 6) {
				btn.addClass("is-fri");
			}
			if (key === todayKey) {
				btn.addClass("is-today");
			}
			if (key < todayKey) {
				btn.prop("disabled", true);
			}
			if (c.sel && c.sel[0] === c.y && c.sel[1] === c.m && c.sel[2] === d) {
				btn.addClass("is-sel");
			}
			grid.append(btn);
		}
		box.append(grid);

		var foot = $('<div class="promo-cal-foot"></div>');
		var hour = $('<select class="form-select form-select-sm" data-cal="h" dir="ltr"></select>');
		for (var h = 0; h < 24; h++) {
			hour.append($("<option></option>").val(h).text(promoPad(h)).prop("selected", h === c.h));
		}
		var minute = $('<select class="form-select form-select-sm" data-cal="mi" dir="ltr"></select>');
		var minutes = [0, 15, 30, 45, 59];
		if (minutes.indexOf(c.mi) < 0) {
			minutes.push(c.mi);
			minutes.sort(function (a, b) { return a - b; });
		}
		$.each(minutes, function (i, mi) {
			minute.append($("<option></option>").val(mi).text(promoPad(mi)).prop("selected", mi === c.mi));
		});
		var clock = $('<span dir="ltr" class="d-inline-flex align-items-center gap-1"></span>').append(hour, $("<b>:</b>"), minute);
		foot.append($("<span></span>").text("🕒 " + promoText.calTime), clock);
		var btns = $('<span class="promo-cal-btns"></span>');
		btns.append($('<button type="button" class="btn btn-sm btn-soft-secondary" data-cal="today"></button>').text(promoText.calToday));
		btns.append($('<button type="button" class="btn btn-sm btn-soft-danger" data-cal="clear"></button>').text(promoText.calClear));
		btns.append($('<button type="button" class="btn btn-sm btn-primary" data-cal="done"></button>').text(promoText.calDone));
		foot.append(btns);
		box.append(foot);
	}

	$(document).on("click", "#promo_cal [data-cal=prev], #promo_cal [data-cal=next]", function () {
		var step = $(this).data("cal") === "next" ? 1 : -1;
		promoCal.m += step;
		if (promoCal.m > 12) { promoCal.m = 1; promoCal.y++; }
		if (promoCal.m < 1) { promoCal.m = 12; promoCal.y--; }
		promoCalDraw();
	});

	$(document).on("click", "#promo_cal [data-day]", function () {
		promoCal.sel = [promoCal.y, promoCal.m, +$(this).data("day")];
		$("#promo_ends_days").val("");
		promoSetEnds(promoCal.sel[0], promoCal.sel[1], promoCal.sel[2], promoCal.h, promoCal.mi);
		promoCalDraw();
	});

	$(document).on("change", "#promo_cal select", function () {
		promoCal[$(this).data("cal")] = +$(this).val();
		if (promoCal.sel) {
			promoSetEnds(promoCal.sel[0], promoCal.sel[1], promoCal.sel[2], promoCal.h, promoCal.mi);
		}
	});

	$(document).on("click", "#promo_cal [data-cal=today]", function () {
		var t = promoTehranParts(Date.now());
		promoCal.y = t.y; promoCal.m = t.m; promoCal.sel = [t.y, t.m, t.d];
		promoSetEnds(t.y, t.m, t.d, promoCal.h, promoCal.mi);
		promoCalDraw();
	});

	$(document).on("click", "#promo_cal [data-cal=clear]", function () {
		$("#promo_ends_at").val("");
		$("#promo_ends_days").val("");
		promoEndsCheck();
		document.getElementById("promo_cal").hidden = true;
	});

	$(document).on("click", "#promo_cal [data-cal=done]", function () {
		document.getElementById("promo_cal").hidden = true;
	});

	// a click anywhere else closes the calendar
	$(document).on("mousedown", function (e) {
		var box = document.getElementById("promo_cal");
		if (box && !box.hidden && !$(e.target).closest("#promo_cal, #promo_cal_open").length) {
			box.hidden = true;
		}
	});

	/* "2 days from today, until 18:00" -> the end date, on Tehran time */
	function promoEndsFromSpan() {
		var days = $("#promo_ends_days").val();
		if (days === "" || isNaN(days)) {
			return;
		}
		var time = String($("#promo_ends_hour").val() || "23:59").split(":");
		var t = new Date(Date.now() + 3.5 * 3600 * 1000);
		var at = new Date(Date.UTC(t.getUTCFullYear(), t.getUTCMonth(), t.getUTCDate() + Math.max(0, parseInt(days, 10))));
		var j = promoGregorianToJalali(at.getUTCFullYear(), at.getUTCMonth() + 1, at.getUTCDate());
		promoSetEnds(j[0], j[1], j[2], parseInt(time[0], 10) || 0, parseInt(time[1], 10) || 0);
		document.getElementById("promo_cal").hidden = true;
	}

	$(document).on("input change", "#promo_ends_days, #promo_ends_hour", promoEndsFromSpan);

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
