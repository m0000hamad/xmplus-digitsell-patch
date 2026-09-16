{*
  Behaviour for the "time" plan type, shared by add.tpl and edit.tpl.

  Braces are always followed by a space or a newline so Smarty leaves this
  script alone.
*}
<script>
	var timeplanToken = "";
	var timeplanReady = false;

	function timeplanBoot(selected, mode, days, price, perday, mindays, maxdays) {
		// a plan this time plan already names stays in the list even if disabled
		var keep = selected && selected.length ? "&keep=" + selected.join(",") : "";

		$.ajax( {
			type: "GET",
			url: "/xmplus-patch.php?do=timeplan.admin" + keep,
			dataType: "json",
			success: function (data) {
				if (!data.ok) {
					return;
				}

				timeplanToken = data.token;
				timeplanReady = true;

				var box = $("#tp_applies");
				box.html('');

				$.each(data.packages, function (i, pack) {
					var option = $('<option></option>').attr('value', pack.id).text(pack.name);
					if (selected && selected.indexOf(parseInt(pack.id, 10)) !== -1) {
						option.attr('selected', 'selected');
					}
					box.append(option);
				} );

				$("#tp_visible_days").val(data.settings.visible_days);
				$("#tp_grace_hours").val(data.settings.grace_hours);

				if (mode) {
					$("#tp_mode").val(mode);
					$("#tp_days").val(days);
					$("#tp_price").val(price);
					$("#tp_price_per_day").val(perday);
					$("#tp_min_days").val(mindays);
					$("#tp_max_days").val(maxdays);
					timeplanMode();
				}
			}
		} );
	}

	function timeplanMode() {
		if ($("#tp_mode").val() == "perday") {
			document.getElementById("tp_fixed_fields").setAttribute("hidden", true);
			document.getElementById("tp_perday_fields").removeAttribute("hidden");
		} else {
			document.getElementById("tp_fixed_fields").removeAttribute("hidden");
			document.getElementById("tp_perday_fields").setAttribute("hidden", true);
		}
	}

	/* called by pricring() - true when the time plan fields are the ones on show */
	function timeplanApply() {
		var isTime = $("#type").val() == 3;

		if (isTime) {
			document.getElementById("timeplanbox").removeAttribute("hidden");
			timeplanMode();
		} else {
			document.getElementById("timeplanbox").setAttribute("hidden", true);
		}

		["fullpack", "top", "packnote", "datafields"].forEach(function (id) {
			var node = document.getElementById(id);
			if (node && isTime) {
				node.setAttribute("hidden", true);
			}
		} );

		return isTime;
	}

	function timeplanSelectedPlans() {
		var ids = [];
		$("#tp_applies option:selected").each(function () {
			ids.push($(this).val());
		} );
		return ids;
	}

	/* saves the plan and the two visibility settings; id 0 creates a new one */
	function timeplanSave(id, done) {
		if (!timeplanReady) {
			layer.msg("time plan endpoint not reachable", { time: 5000, offset: '100px' } );
			return;
		}

		layer.load(2);

		$.ajax( {
			type: "POST",
			url: "/xmplus-patch.php?do=timeplan.settings",
			dataType: "json",
			data: {
				token: timeplanToken,
				visible_days: $("#tp_visible_days").val(),
				grace_hours: $("#tp_grace_hours").val()
			},
			complete: function () {
				$.ajax( {
					type: "POST",
					url: "/xmplus-patch.php?do=timeplan.save",
					dataType: "json",
					data: {
						token: timeplanToken,
						id: id,
						name: $("#name").val(),
						status: $("#status").val(),
						sort: $("#tp_sort").val(),
						mode: $("#tp_mode").val(),
						days: $("#tp_days").val(),
						price: $("#tp_price").val(),
						price_per_day: $("#tp_price_per_day").val(),
						min_days: $("#tp_min_days").val(),
						max_days: $("#tp_max_days").val(),
						applies_to: timeplanSelectedPlans()
					},
					success: function (data) {
						layer.closeAll('loading');

						if (!data.ok) {
							layer.msg(data.error, { time: 6000, offset: '100px' } );
							return;
						}

						layer.msg("{$translate->get('TimePlanSaved')}", { time: 2000, offset: '100px' } );
						window.setTimeout(done, 1200);
					},
					error: function (jqXHR) {
						layer.closeAll('loading');
						layer.msg(jqXHR.responseText, { time: 6000, offset: '100px' } );
					}
				} );
			}
		} );
	}
</script>
