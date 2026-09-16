{*
  Which subscription plans a traffic top-up is offered on.

  Shown only when the type selector is set to 1. The encoded /admin/plan/save
  has no idea about this field, so the page sends it separately to
  /xmplus-patch.php?do=timeplan.topupscope right after the package is saved.
*}
<div class="row mb-2" id="topupscope" hidden>
	<label class="col-sm-3 col-form-label form-label" for="topup_applies">{$translate->get('TimePlanAppliesTo')}</label>
	<div class="col-sm-9" style="max-width: 60rem">
		<select class="form-control shadow-lg" id="topup_applies" multiple size="8"></select>
		<small class="text-muted">{$translate->get('TimePlanAllPlans')}</small>
	</div>
</div>

<div class="row mb-2" id="topupgroupscope" hidden>
	<label class="col-sm-3 col-form-label form-label" for="topup_groups">{$translate->get('TimePlanGroups')}</label>
	<div class="col-sm-9" style="max-width: 60rem">
		<select class="form-control shadow-lg" id="topup_groups" multiple size="6"></select>
		<small class="text-muted">{$translate->get('TimePlanAllGroups')}</small>
	</div>
</div>
