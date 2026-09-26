
{include file='admin/layout/header.tpl'} 
	<script>localStorage.setItem('toggleID', 'transactionMenu'); </script>	
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('AddPlan')}</h1>
			</div>
        </div>
    </div>
	<div class="row match-height">
		<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
			<div class="card card-shadow shadow-lg rounded">
				<div class="card-header card-header-content-sm-between border-bottom">
					<h3 class="card-header-title mb-2 mb-sm-0">{$translate->get('AddNewPlan')}</h3>
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
									<option value="0" >{$translate->get('Disable')}</option>
									<option value="1" >{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="type">{$translate->get('Type')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="type" name="type" onchange="pricring()" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="1" >{$translate->get('TopupPlan')}</option>
									<option value="2" selected>{$translate->get('DataPlan')}</option>
									<option value="3" >{$translate->get('TimePlan')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="name">{$translate->get('PackageName')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="name" name="name" value="Plan 1">	
							</div>
						</div>
						<span id="datafields">
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="bandwidth">{$translate->get('Bandwidth')} (GB)</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="bandwidth" name="bandwidth" value="100">	
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="stocks">{$translate->get('EnableStock')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="stocks" name="stocks" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" >{$translate->get('Disable')}</option>
									<option value="1" >{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="stockcount">{$translate->get('StockCount')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="stockcount" name="stockcount" value="100">
							</div>
						</div>
						</span>

						<span id="fullpack">
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="speedlimit">{$translate->get('Speedlimit')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="speedlimit" name="speedlimit" value="1024">	
								</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="iplimit">{$translate->get('IPLimit')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="iplimit" name="iplimit" value="2">	
								</div>
							</div>
							<div class="row mb-2">
									<label class="col-sm-3 col-form-label form-label" for="server_group">{$translate->get('ServerGroup')}</label>
									<div class="col-sm-9 tom-select-custom">
										<select class="js-select form-select shadow-lg" id="server_group" name="server_group" data-hs-tom-select-options='{
										  "hideSearch": false
										}'>
											{foreach $group as $server_group}
												<option value="{$server_group->id}" >{$server_group->name}</option>
											{/foreach}
										</select>
									</div>
							</div>
							<div class="row mb-2" id="plantype" >
								<label class="col-sm-3 col-form-label form-label" for="renew_type">{$translate->get('PlanType')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<select class="js-select form-select shadow-lg" id="renew_type" name="renew_type" data-hs-tom-select-options='{
										"hideSearch": true
									}'>
										<option value="0" selected>{$translate->get('Disable')}</option>
										<option value="1" selected>{$translate->get('ResetPlan')}</option>
										<option value="4" >{$translate->get('ExtendPlan')}</option>
										<option value="2" >{$translate->get('ResetPlanData')}</option>
										<option value="3" >{$translate->get('ResetPlanExpire')}</option>
										<option value="5" >{$translate->get('ExtendExpire')}</option>
										<option value="6" >{$translate->get('ExtendData')}</option>
									</select>
								</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="sort">{$translate->get('Sorting')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="sort" name="sort" value="0">	
								</div>
							</div>
							<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="reset_days">{$translate->get('ResetDays')}</label>
								<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
									<input type="text" class="form-control shadow-lg" id="reset_days" name="reset_days" value="0">	
								</div>
							</div>
							
							<h4>{$translate->get('Pricing')}</h4>
							
							<div class="row mb-2" id="sub">
								<label for="sub" class="col-sm-3 col-form-label form-label"></label>
								<div class="col-sm-9">
									<div class="row">
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Onetime')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="onetime[price]" >
											</div>
										</div>
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Monthly')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="month[price]" >				
											</div>
										</div>			
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Quaterly')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="quater[price]" >				
											</div>
										</div>	
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('SemiAnnually')}</label> 
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="semiannual[price]" >				
											</div>
										</div>	
										<div class="col-lg-3 col-xl-3 col-md-6 col-sm-6 mb-2">
											<label class="form-label text-center">{$translate->get('Annually')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="annual[price]" >				
											</div>
										</div>	
										<div class="col-lg-6 col-xl-6 col-md-12 col-sm-12 mb-2">
											<label class="form-label text-center">{$translate->get('Custom')}</label>
											<div class="input-group">
												<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
												<input type="text" class="form-control shadow-lg" name="custom[price]" >
												<a class="btn btn-dark text-center"><i class="fa-duotone fa-calendar-days"></i></a>
												<input type="text" class="form-control shadow-lg" name="custom[expire]" value="15">
											</div>
										</div>
									</div>
								</div>
							</div>
						</span>
						<div class="row mb-3" id="top" hidden>
							<label class="col-sm-3 col-form-label form-label" for="topup_price"></label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<label class="form-label text-center">{$translate->get('TopupPrice')}</label>
								<div class="input-group">
									<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
									<input type="text" class="form-control shadow-lg" name="topup[price]" value="0.00" >
								</div>
							</div>
						</div>

						{include file='admin/plans/topupscopeform.tpl'}

						{include file='admin/plans/timeplanform.tpl'}

						{include file='admin/plans/promoform.tpl'}

						<div class="row mb-2" id="packnote">
							<label for="" class="col-sm-3 col-form-label form-label">{$translate->get('OrderNote')}</label> 
							<div class="col-sm-9 tom-select-custom">
							<div class="accordion shadow-lg rounded" id="accordion">
							{$c = 0}
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
										<textarea  id="order_note_{$lang[1]}" class="display mb-2 shadow-lg" name="order_note[{$lang[1]}]"></textarea>
									  </div>
									</div>
								</div>
							{/foreach}
							</div>
							</div>
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
                <a type="button" href="/admin/plans" class="btn btn-ghost-light">{$translate->get('Discard')}</a>
              </div>
              <div class="col-auto">
                <div class="d-flex gap-3">
                  <button type="submit" onClick="submit()" class="btn btn-dark">{$translate->get('Save')}</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>	
{include file='admin/layout/footer.tpl'}
{include file='admin/plans/timeplanjs.tpl'}
{include file='admin/plans/promojs.tpl'}
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

		timeplanBoot([], null, null, null, null, null, null, null, null, 0, []);
	});
	
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

		// a subscription plan can carry a promotion
		promoApply();
	}

	function submit(){
		// a time plan is not something /admin/plan/save knows how to store
		if($("#type").val() == 3){
			timeplanSave(0, function () {
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
						timeplanSaveTopupScope(0, function () {
							window.setTimeout("location.href='/admin/plans'", 1200);
						});
						return;
					}

					// the promotion is saved after the list prices, see promojs.tpl;
					// a new plan has no id yet, so the endpoint finds it by name
					promoSave(0, function () {
						location.href = '/admin/plans';
					});
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
