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
		unreachable: "{$translate->get('PromoUnreachable')|escape:'javascript'}"
	};
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
				channel: $("#promo_channel").is(":checked") ? 1 : 0
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
</script>
{/literal}
