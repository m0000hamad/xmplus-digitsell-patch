{*
  Fields for a "time" plan - a plan that sells days rather than gigabytes.

  Included by admin/plans/add.tpl and admin/plans/edit.tpl and shown only when
  the type selector is set to 3. These fields are not posted to /admin/plan/save
  (that controller is encoded and knows nothing about them); the page sends them
  to /xmplus-patch.php?do=timeplan.save instead.
*}
<span id="timeplanbox" hidden>

	<h4>{$translate->get('TimePlanSection')}</h4>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="tp_mode">{$translate->get('TimePlanMode')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<select class="form-control form-select shadow-lg" id="tp_mode" onchange="timeplanMode()">
				<option value="fixed">{$translate->get('TimePlanFixed')}</option>
				<option value="perday">{$translate->get('TimePlanPerDay')}</option>
			</select>
		</div>
	</div>

	<span id="tp_fixed_fields">
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="tp_days">{$translate->get('TimePlanDays')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<input type="text" class="form-control shadow-lg" id="tp_days" value="30">
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="tp_price">{$translate->get('TimePlanPrice')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="input-group">
					<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
					<input type="text" class="form-control shadow-lg" id="tp_price" value="">
				</div>
			</div>
		</div>
	</span>

	<span id="tp_perday_fields" hidden>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="tp_price_per_day">{$translate->get('TimePlanDayPrice')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="input-group">
					<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
					<input type="text" class="form-control shadow-lg" id="tp_price_per_day" value="">
				</div>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="tp_min_days">{$translate->get('TimePlanMinDays')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<input type="text" class="form-control shadow-lg" id="tp_min_days" value="1">
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="tp_max_days">{$translate->get('TimePlanMaxDays')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<input type="text" class="form-control shadow-lg" id="tp_max_days" value="30">
			</div>
		</div>
	</span>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="tp_applies">{$translate->get('TimePlanAppliesTo')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<select class="form-control shadow-lg" id="tp_applies" multiple size="8"></select>
			<small class="text-muted">{$translate->get('TimePlanAllPlans')}</small>
		</div>
	</div>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="tp_visible_days">{$translate->get('TimePlanVisibleDays')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<input type="text" class="form-control shadow-lg" id="tp_visible_days" value="7">
		</div>
	</div>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="tp_grace_hours">{$translate->get('TimePlanGraceHours')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<input type="text" class="form-control shadow-lg" id="tp_grace_hours" value="24">
			<small class="text-muted">{$translate->get('TimePlanNote')}</small>
		</div>
	</div>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="tp_sort">{$translate->get('Sorting')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<input type="text" class="form-control shadow-lg" id="tp_sort" value="0">
		</div>
	</div>

</span>
