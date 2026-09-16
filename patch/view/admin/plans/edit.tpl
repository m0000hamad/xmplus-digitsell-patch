{include file='admin/layout/header.tpl'}
{* a time plan is stored as a topup package carrying a marker in order_note *}
{$tpnote = json_decode($package->order_note, true)}
{$tpprice = json_decode($package->price_option, true)}
{$tpmeta = false}
{$tpmode = 'fixed'}
{$tpdays = 30}
{$tpperday = ''}
{$tpmin = 1}
{$tpmax = 30}
{$tpapplies = '[]'}
{$tpamount = ''}
{$tpmaxbuys = 0}
{$tpmaxtotal = 0}
{$tpgenerated = false}
{if isset($tpnote.timeplan)}
	{$tpmeta = $tpnote.timeplan}
	{if isset($tpmeta.mode) && $tpmeta.mode == 'minted'}{$tpgenerated = true}{/if}
	{if isset($tpmeta.max_buys)}{$tpmaxbuys = $tpmeta.max_buys}{/if}
	{if isset($tpmeta.max_total)}{$tpmaxtotal = $tpmeta.max_total}{/if}
	{if isset($tpmeta.mode)}{$tpmode = $tpmeta.mode}{/if}
	{if isset($tpmeta.days)}{$tpdays = $tpmeta.days}{/if}
	{if isset($tpmeta.price_per_day)}{$tpperday = $tpmeta.price_per_day}{/if}
	{if isset($tpmeta.min_days)}{$tpmin = $tpmeta.min_days}{/if}
	{if isset($tpmeta.max_days)}{$tpmax = $tpmeta.max_days}{/if}
	{if isset($tpmeta.applies_to)}{$tpapplies = json_encode($tpmeta.applies_to)}{/if}
{/if}
{if isset($tpprice.topup.price)}{$tpamount = $tpprice.topup.price}{/if}
	<script>localStorage.setItem('toggleID', 'transactionMenu'); </script>	
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('EditPlan')}</h1>
			</div>
        </div>
    </div>
	<div class="row match-height">
		<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
			<div class="card card-shadow shadow-lg rounded">
				<div class="card-header card-header-content-sm-between border-bottom">
					<h3 class="card-header-title mb-2 mb-sm-0">{$translate->get('EditPlanN')}</h3>
				</div>
				<div class="card-body">
					<div class="col-12 col-sm-offset-2 col-md-12 col-lg-offset-2 col-lg-8 mx-auto mb-3">
					<form  id="formsubmit">
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="status">{$translate->get('Status')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="status" name="status" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0"  {if $package->status == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1"  {if $package->status == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="type">{$translate->get('Type')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="type" name="type" onchange="pricring()" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="1" {if $package->type == 1 && !$tpmeta}selected{/if}>{$translate->get('TopupPlan')}</option>
									<option value="2" {if $package->type == 2}selected{/if}>{$translate->get('DataPlan')}</option>
									<option value="3" {if $tpmeta}selected{/if}>{$translate->get('TimePlan')}</option>
								</select>
							</div>
						</div>
													
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="name">{$translate->get('PackageName')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="name" name="name" value="{$package->name}">	
							</div>
						</div>
						<span id="datafields">
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="bandwidth">{$translate->get('Bandwidth')} (GB)</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="bandwidth" name="bandwidth" value="{$package->bandwidth}">	
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="stocks">{$translate->get('EnableStock')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="stocks" name="stocks" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $package->stocks == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $package->stocks == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="stockcount">{$translate->get('StockCount')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="stockcount" name="stockcount" value="{$package->stockcount}">
							</div>
						</div>
						</span>
						<span id="fullpack">
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="speedlimit">{$translate->get('Speedlimit')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="speedlimit" name="speedlimit" value="{$package->speedlimit}">	
								</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="iplimit">{$translate->get('IPLimit')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="iplimit" name="iplimit" value="{$package->iplimit}">	
								</div>
							</div>
							<div class="row mb-2">
									<label class="col-sm-3 col-form-label form-label" for="server_group">{$translate->get('ServerGroup')}</label>
									<div class="col-sm-9 tom-select-custom">
										<select class="js-select form-select shadow-lg" id="server_group" name="server_group" data-hs-tom-select-options='{
										  "hideSearch": false
										}'>
											{foreach $group as $server_group}
												<option value="{$server_group->id}" {if $package->server_group == $server_group->id}selected{/if}>{$server_group->name}</option>
											{/foreach}
										</select>
									</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="sort">{$translate->get('Sorting')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="sort" name="sort" value="{$package->sort}">	
								</div>
							</div>
							<div class="row mb-2" id="plantype" {if $package->type == 1}hidden{/if}>
								<label class="col-sm-3 col-form-label form-label" for="renew_type">{$translate->get('PlanType')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<select class="js-select form-select shadow-lg" id="renew_type" name="renew_type" data-hs-tom-select-options='{
										"hideSearch": true
									}'>
										<option value="0" {if $package->renew_type == 0}selected{/if}>{$translate->get('Disable')}</option>
										<option value="1" {if $package->renew_type == 1}selected{/if}>{$translate->get('ResetPlan')}</option>
										<option value="4" {if $package->renew_type == 4}selected{/if}>{$translate->get('ExtendPlan')}</option>
										<option value="2" {if $package->renew_type == 2}selected{/if}>{$translate->get('ResetPlanData')}</option>
										<option value="3" {if $package->renew_type == 3}selected{/if}>{$translate->get('ResetPlanExpire')}</option>
										<option value="5" {if $package->renew_type == 5}selected{/if}>{$translate->get('ExtendExpire')}</option>
										<option value="6" {if $package->renew_type == 6}selected{/if}>{$translate->get('ExtendData')}</option>
									</select>
								</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="reset_days">{$translate->get('ResetDays')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="reset_days" name="reset_days" value="{$package->reset_days}">	
								</div>
							</div>
							
							<h4>{$translate->get('Pricing')}</h4>
							{$options = json_decode($package->price_option, true)}
							
							<div class="row mb-2" id="sub" {if $package->type == 1}hidden{/if}>
								<label for="sub" class="col-sm-3 col-form-label form-label"></label>
								<div class="col-sm-9">
									<div class="row">
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Onetime')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="onetime[price]" value="{if isset($options['onetime']['price'])}{$options['onetime']['price']}{/if}" >
											</div>
										</div>
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Monthly')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="month[price]" value="{if isset($options['month']['price'])}{$options['month']['price']}{/if}" >				
											</div>
										</div>			
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Quaterly')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="quater[price]" value="{if isset($options['quater']['price'])}{$options['quater']['price']}{/if}" >				
											</div>
										</div>	
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('SemiAnnually')}</label> 
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="semiannual[price]" value="{if isset($options['semiannual']['price'])}{$options['semiannual']['price']}{/if}" >				
											</div>
										</div>	
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Annually')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="annual[price]" value="{if isset($options['annual']['price'])}{$options['annual']['price']}{/if}" >				
											</div>
										</div>	
										<div class="col-lg-6 col-xl-6 col-md-12 col-sm-12 mb-2">
											<label class="form-label text-center">{$translate->get('Custom')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="custom[price]" value="{if isset($options['custom']['price'])}{$options['custom']['price']}{/if}">
												<a class="btn btn-dark text-center"><i class="fa-duotone fa-calendar-days"></i></a>
												<input type="text" class="form-control shadow-lg" name="custom[expire]" value="{if isset($options['custom']['expire'])}{$options['custom']['expire']}{/if}">
											</div>
										</div>
									</div>
								</div>
							</div>
						</span>
						<div class="row mb-3" id="top" {if $package->type == 2}hidden{/if}>
							<label class="col-sm-3 col-form-label form-label" for="topup_price"></label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<label class="form-label text-center">{$translate->get('TopupPrice')}</label>
								<div class="input-group">
									<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a> 
									<input type="text" class="form-control shadow-lg" name="topup[price]" value="{if isset($options['topup']['price'])}{$options['topup']['price']}{/if}" >				
								</div>
							</div>
						</div>

						{include file='admin/plans/topupscopeform.tpl'}

						{if $tpgenerated}
							<div class="alert alert-warning">{$translate->get('TimePlanGeneratedRow')}</div>
						{/if}

						{include file='admin/plans/timeplanform.tpl'}

						<div class="row mb-2" id="packnote">
							<label for="" class="col-sm-3 col-form-label form-label">{$translate->get('OrderNote')}</label> 
							<div class="col-sm-9 tom-select-custom">
							<div class="accordion shadow-lg rounded" id="accordion">
							{$c = 0}
							{$content = json_decode($package->order_note,true)}
							{foreach $languages as $language}
								{$c = $c + 1}
								{assign var=lang value="_"|explode:$language}
								<div class="accordion-item">
									<div class="accordion-header" id="heading_{$language}">
									  <a class="accordion-button text-dark fs-8" role="button" data-bs-toggle="collapse" data-bs-target="#collapse_{$language}" aria-expanded="true" aria-controls="collapse_{$language}">
										<img class="avatar avatar-xss avatar-circle me-2" src="/assets/vendor/flag-icon-css/flags/1x1/{$lang[1]|lower|escape}.svg">
										<span class="text-truncate" >{$translate->get({$language})}</span>
									  </a>
									</div>
									<div id="collapse_{$language}" class="accordion-collapse collapse {if $c == 1}show{/if}" aria-labelledby="heading_{$language}" data-bs-parent="#accordion">
									  <div class="accordion-body">
										<textarea  id="order_note_{$lang[1]}" class="display mb-2 shadow-lg" name="order_note[{$lang[1]}]">{if isset($content[$lang[1]])}{$content[$lang[1]]}{/if}</textarea>
									  </div>
									</div>
								</div>
							{/foreach}
							</div>
							</div>
						</div>
						
						<div class="row" hidden>
							<input type="text" class="form-control" name="id" value="{$package->id}" >
						</div>
					</form>
					</div>	
				</div>	
			</div>		
		</div>			
	</div>
      <div class="position-fixed start-50 bottom-0 translate-middle-x w-100 zi-99 mb-3" style="max-width: 40rem;">
        <!-- Card -->
        <div class="card card-sm bg-dark border-dark mx-2">
          <div class="card-body">
            <div class="row justify-content-center justify-content-sm-between">
              <div class="col">
                <a type="button" onClick="deletePlan()" class="btn btn-ghost-danger">{$translate->get('Delete')}</a>
              </div>
              <div class="col-auto">
                <div class="d-flex gap-3">
                  <a type="button" href="/admin/plans" class="btn btn-ghost-light">{$translate->get('Discard')}</a>
                  <button type="submit" onClick="submit()" class="btn btn-dark">{$translate->get('Save')}</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>	
{include file='admin/layout/footer.tpl'}
{include file='admin/plans/timeplanjs.tpl'}
<script src="/assets/plugins/tinymce/tinymce.min.js"></script>
<script>
	$(document).ready(function () {
		var isSmallScreen = window.matchMedia('(max-width: 1023.5px)').matches;
		tinymce.init({
			selector: '.display',
			{if $session->get('locale') == "zh_CN"}language : "zh_CN",{/if}
			plugins: 'preview importcss searchreplace  directionality code visualblocks visualchars fullscreen link template codesample table charmap nonbreaking insertdatetime advlist lists charmap quickbars emoticons',
			editimage_cors_hosts: ['picsum.photos'],
			menubar: 'file edit view insert format tools table',
			toolbar: 'undo redo | bold italic underline strikethrough | fontfamily fontsize blocks | alignleft aligncenter alignright alignjustify | outdent indent |  numlist bullist | forecolor backcolor removeformat | charmap emoticons | fullscreen  preview | insertfile template link  codesample | ltr rtl',
			toolbar_sticky: false,
			toolbar_sticky_offset: isSmallScreen ? 102 : 108,
			image_advtab: true,
			importcss_append: true,
			mobile: {
				menubar: true
			},
			height: 300,
			image_caption: true,
			quickbars_selection_toolbar: 'bold italic | quicklink h2 h3 blockquote quickimage quicktable',
			toolbar_mode: 'sliding',
			contextmenu: 'link table',
			content_style: 'body { font-family:Helvetica,Arial,sans-serif; font-size:16px }',
			file_picker_types: 'file media',				
			relative_urls : false,
			remove_script_host : true,
			document_base_url : "/",
			convert_urls : true, 
		});
	});
	
	pricring();

	timeplanBoot({$tpapplies}, "{$tpmode}", "{$tpdays}", "{$tpamount}", "{$tpperday}", "{$tpmin}", "{$tpmax}", "{$tpmaxbuys}", "{$tpmaxtotal}", {$package->id});

	function pricring(){
		if($("#type").val() == 1){
			document.getElementById("top").removeAttribute("hidden");
			document.getElementById("fullpack").setAttribute("hidden", true);
			document.getElementById("packnote").setAttribute("hidden", true);
			document.getElementById("datafields").removeAttribute("hidden");
		}else{
			document.getElementById("top").setAttribute("hidden", true);
			document.getElementById("fullpack").removeAttribute("hidden");
			document.getElementById("packnote").removeAttribute("hidden");
			document.getElementById("datafields").removeAttribute("hidden");
		}

		// type 3 is a time plan: it hides everything above and shows its own box
		timeplanApply();
	}

    function deletePlan() {
		if({$user->role} != 1){
			layer.msg("{$translate->get('OnlyAdmin')}", {
				time: 5000,
				offset:  '100px'
			});
			return;
		}
		Swal.fire({
			title: "{$translate->get('ConfirmDelete')}",
			text: "{$translate->get('ConfirmDeleteNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Delete')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				delete_id();
			}
		});
    }

	function delete_id() {
		// a time plan takes its minted day-count rows with it, which the
		// encoded delete route knows nothing about
		if($("#type").val() == 3){
			$.ajax({
				type: "POST",
				url: "/xmplus-patch.php?do=timeplan.delete",
				dataType: "json",
				data: {
					token: timeplanToken,
					id: {$package->id}
				},
				success: data => {
					if (data.ok) {
						layer.msg("{$translate->get('TimePlanDeleted')}", {
							time: 3000,
							offset:  '100px'
						});
						window.setTimeout("location.href='/admin/plans'", 800);
					} else {
						layer.msg(data.error, {
							time: 5000,
							offset:  '100px'
						});
					}
				}
			});
			return;
		}

        $.ajax({
            type: "DELETE",
            url: "/admin/plan/delete",
            dataType: "json",
            data: {
                id: {$package->id}
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    window.setTimeout("location.href='/admin/plans'", 500);
                } else {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
            }
        });
    }
	
	function submit(){
		{if $tpgenerated}
		// this row was generated to price one purchase, not authored as a plan
		layer.msg("{$translate->get('TimePlanGeneratedRow')}", {
			time: 6000,
			offset:  '100px'
		});
		return false;
		{/if}

		// a time plan is not something /admin/plan/save knows how to store
		if($("#type").val() == 3){
			timeplanSave({$package->id}, function () {
				location.href = '/admin/plans';
			});
			return false;
		}

		layer.load(2);
		tinyMCE.triggerSave();
		$.ajax({
			type: "POST",
			url: "/admin/plan/save",
			dataType: "json",
			data: $('#formsubmit').serialize(),
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					// the plan list of a traffic top-up is stored separately
					if ($("#type").val() == 1) {
						timeplanSaveTopupScope({$package->id}, function () {
							window.setTimeout("location.href='/admin/plans'", 800);
						});
						return;
					}

					window.setTimeout("location.href='/admin/plans'", 500);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			}
		});	
		return false;
	};
</script>
