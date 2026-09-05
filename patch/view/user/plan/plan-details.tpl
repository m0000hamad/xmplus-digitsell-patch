{include file='user/layout/header.tpl'}

    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('PlanDetails')}</h1>
			</div>
        </div>
    </div>
	  
	<div class="row mb-3">
		<div class="col-xl-8 col-lg-8 col-md-12 col-sm-12">
			<div class="row mb-2">
				<div class="col-xl-12 col-lg-12 col-md-12 col-sm-12 mb-3">
					<div class="card card-lg card-shadow shadow-lg rounded">
						<div class="card-header card-header-content-between border-bottom">	
							<h3><b><i class="fa-duotone fa-cart-shopping"></i> {$package->name}</b></h3>
						</div>
						<div class="card-body">
							<i class="fa-duotone fa-circle-check m-1"></i> <strong>{$translate->get('Bandwidth')} : </strong>{if $package->bandwidth < 10000}{$package->bandwidth} GB{else}{$translate->get('Unlimited')}{/if} <br>
							<i class="fa-duotone fa-circle-check m-1"></i> <strong>{$translate->get('PortSpeed')} : </strong>{$helpers->PortSpd($package->speedlimit)}<br>
							<i class="fa-duotone fa-circle-check m-1"></i> <strong>{$translate->get('ConnLimit')} : </strong>{$package->iplimit}<br>
							<i class="fa-duotone fa-circle-check m-1"></i> <strong>{$translate->get('ServerGroup')} : </strong>{str_replace([' | '],[''],$helpers->serveGroup($package->server_group))}<br>
							{if $package->reset_days > 0}
								<i class="fa-duotone fa-circle-check m-1"></i> <strong> {$translate->get('AllowReset')} : </strong> {$translate->get('Every')}{$package->reset_days} {$translate->get('Days')}
							{else}
								<i class="fa-duotone fa-circle-xmark m-1"></i> <strong> {$translate->get('AllowReset')} : </strong> {$translate->get('None')}
							{/if}
							
							{if $package->order_note != null}<br><br><br>
								<h3><b><i class="fa-duotone fa-ballot-check"></i> {$translate->get('OrderNote')}</b></h3><hr>
								{$content = json_decode($package->order_note,true)}
								{assign var=lang value="_"|explode:$session->get('locale')}
								{if isset($content[$lang[1]])}{$content[$lang[1]]}{else}{$package->order_note}{/if}
							{/if} 
						</div>
					</div>
				</div>
				<style>
				.form-check-select-stretched .form-check-input:checked[type=checkbox]~.form-check-label,.form-check-select-stretched .form-check-input:checked[type=radio]~.form-check-label {
					border-color: var(--bs-dark)
				}
				</style>
				<div class="col-xl-12 col-lg-12 col-md-12 col-sm-12 mb-3">
					<h3><b><i class="fa-duotone fa-calendar-days"></i> {$translate->get('BillingCycle')}</b></h3>
				<div class="row mb-2">	
					{$options = json_decode($package->price_option,true)}
					{$p = 0}
					{foreach $options as $option => $value}
					{if $option != "topup" }
					{if isset($value['price']) && $value['price'] !== ""}
					{$p = $p + 1}
					<div class="col-xl-4 col-lg-6 col-sm-12 col-md-6 mb-3">
						<div class="card card-lg border form-check form-check-dark form-check-select-stretched shadow-lg">
							<div class="card-header text-center rounded">
								<input type="radio" class="form-check-input form-check-dark" name="plan" id="{$option}" {if $p == 1}checked{/if} value="{$option}" onClick="Billing('{$option}')">
								<label class="form-check-label" for="{$option}"></label>
								<p class="card-title text-dark"><b style="font-size:16px">{$currency->symbol_left} {number_format((float)$value['price'], (int){$currency->decimals})} {$currency->symbol_right}</b><br>
									{if isset($value['price']) && $option == "onetime"}
										<span> {$translate->get('Onetime')}<br> {$translate->get('NotExpire')}</span>
									{/if}
									{if isset($value['price']) && $option == "month"}
										<span> {$translate->get('Monthly')} <br> 30 {$translate->get('Days')}</span>
									{/if}
									{if isset($value['price']) && $option == "quater"}
										<span>{$translate->get('Quaterly')} <br>90 {$translate->get('Days')}</span>
									{/if}
									{if isset($value['price']) && $option == "semiannual" }
										<span>{$translate->get('SemiAnnually')}<br> 180 {$translate->get('Days')}</span>
									{/if}
									{if isset($value['price']) && $option == "annual"}
										<span>{$translate->get('Annually')} <br> 360 {$translate->get('Days')}</span>
									{/if}
									{if isset($value['price']) && $option == "custom"}
										<span>{$translate->get('Custom')} <br> {$value['expire']} {$translate->get('Days')}</span>
									{/if}
								</p>
							</div>
						</div>
					</div>
					{/if}
					{/if}		
					{/foreach} 
				</div>	
				</div>
			</div>
		</div>
		<div class="col-xl-4 col-lg-4 col-md-12 col-sm-12">
			<div class="row">
				<div class="col-xl-12 col-lg-12 col-md-12 col-sm-12 mb-2">
					<div class="card card-lg card-shadow shadow-lg rounded">
						<div class="card-header border-bottom">	
							<div class="row mb-3">
								<div class="col-8">
									<input id="coupon" type="text" class="form-control" placeholder="{$translate->get('InputCoupon')}" />
								</div>
								<div class="d-grid col-4 text-start">
									<a class="btn btn-dark redeem" id="redeem">
										{$translate->get('Redeem')}
									</a>
									<a class="btn btn-danger remove" id="remove" onClick="Remove()" hidden>
										{$translate->get('Remove')}
									</a>
								</div>
							</div>
						</div>
					</div>
				</div>
				<div class="col-xl-12 col-lg-12 col-md-12 col-sm-12 mb-2">
					<div class="card card-shadow shadow-lg rounded">
						<div class="card-body">
							<div class="row">
								<div class="col-12">
									<style>
					#disableactive {
						width: 3em;
						height: 1.5em;
						cursor: pointer;
						background-color: #dfe3ec;
						border: 1px solid #8f9bb3;
						background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='3' fill='%23515f7d'/%3e%3c/svg%3e");
					}
					#disableactive:checked {
						background-color: #132144;
						border-color: #132144;
						background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='-4 -4 8 8'%3e%3ccircle r='3' fill='%23ffffff'/%3e%3c/svg%3e");
					}
					#disableactive:focus {
						border-color: #132144;
						box-shadow: 0 0 0 0.2rem rgba(19, 33, 68, 0.25);
					}
					label[for="disableactive"] {
						cursor: pointer;
						font-weight: 600;
						color: #132144;
					}
					</style>
					<div class="form-check form-check-dark form-switch">
									  <input type="checkbox" class="form-check-input" id="disableactive" onClick="DisableActive()">
									  <label class="form-check-label" for="disableactive">{$translate->get('DisableActive')}</label>
									</div>
								</div>	
							</div>
						</div>
					</div>
				</div>
				<div class="col-xl-12 col-lg-12 col-md-12 col-sm-12 mb-3">
					<div class="card card-lg card-shadow shadow-lg rounded">
						<div class="card-header card-header-content-between border-bottom">	
							<h4 class="card-header-title">{$translate->get('Summary')}</h4>
						</div>
						<div class="card-body">
							<div class="mb-3 d-flex justify-content-between">
								{$translate->get('SubTotal')} :
								<span>{$currency->symbol_left} <span id="subtotal">{$price} </span> {$currency->symbol_right}</span>
							</div>
							<div class="mb-3 d-flex justify-content-between">
								{$translate->get('Discount')} :
								<span style="color:red">- {$currency->symbol_left} <span id="discount">{number_format((float)0, (int){$currency->decimals})} </span> {$currency->symbol_right}</span>
							</div>
							<div class="mb-3 d-flex justify-content-between">
								<h3><b>{$translate->get('Total')} :</b></h3>
								<h4><b>{$currency->symbol_left} <span id="total"> {$price} </span> {$currency->symbol_right}</b></h4>
							</div>	
							<div class="d-grid text-center">
								<button class="btn btn-dark rounded-pill" onClick="Checkout()">
									<span>{$translate->get('Checkout')}</span>
								</button>
							</div>	
						</div>
					</div>
				</div>					
			</div>		
		</div>
	</div>
{include file='user/layout/footer.tpl'}
<script>
	checkBill();
	
	{if $Config['allow_coupon_use'] == 1}
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			localStorage.removeItem('coupon');
		}
	{/if}
	
	function DisableActive(){
		if(document.getElementById('disableactive').checked == 1){
			Swal.fire({
				title: '',
				html: "{$translate->get('DisableActiveNote')}",
				icon: 'warning',
				showCancelButton: false,
				showConfirmButton:true,
				confirmButtonText: "{$translate->get('ok')}",
				allowOutsideClick: false,
				customClass: {
					confirmButton: 'btn btn-secondary ms-1',
					cancelButton: 'btn btn-danger ms-1'
				},
				buttonsStyling: false
			})
		}
	}
	
	function Remove(){
		document.getElementById("coupon").disabled = false;
		document.getElementById("remove").setAttribute("hidden", true);
		document.getElementById("redeem").removeAttribute("hidden");
		localStorage.removeItem('coupon');
		$("#coupon").val("");
		location.reload();
	}	
	
	function checkBill(){
		var type = $("input[name='plan']:checked").val();
		Billing(type);
	}
	
	function Billing(type){
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			var code = coupon;
		}else{
			var code = "";
		}
		$.ajax({
			type: "POST",
			url: "/portal/checkout/billing",
			dataType: "json",
			data: {
				packageid : {$package->id},
				type: type,
				code: code,
			},
			success: (data) => {
				if (data.ret) {
					$("#total").html(data.total);
					$("#subtotal").html(data.subtotal);
					$("#discount").html(data.discount);
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}	

	
	{if $Config['allow_coupon_use'] == 1}
	$('#redeem').click(function (){
		var plan =  $("input[name='plan']:checked").val();
		localStorage.setItem('coupon', $("#coupon").val());
		$.ajax({
			type: "POST",
			url: "/portal/checkout/redeem",
			dataType: "json",
			data: {
				packageid : {$package->id},
				plan: plan,
				code: localStorage.getItem('coupon'),
			},
			success: (data) => {
				if (data.ret) {
					$("#total").html(data.total);
					$("#subtotal").html(data.subtotal);
					$("#discount").html(data.discount);
					document.getElementById("coupon").disabled = true;
					document.getElementById("redeem").setAttribute("hidden", true);
					document.getElementById("remove").removeAttribute("hidden");
				}else{
				    localStorage.removeItem('coupon');
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	});
	{/if}
	
	function Checkout(){
		var plan =  $("input[name='plan']:checked").val();
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			var code = coupon;
		}else{
			var code = "";
		}
		if (document.getElementById('disableactive').checked) {
			var disableactive = 1;
		} else {
			var disableactive = 0;
		}
		$.ajax({
			type: "POST",
			url: "/portal/order/create",
			dataType: "json",
			data: {
				packageid : {$package->id},
				plan: plan,
				code: code,
				renew: 0,
				upgrade: 0,
				disableactive: disableactive
			},
			success: (data) => {
				localStorage.removeItem('coupon');
				if (data.ret == -4) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'error',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.setTimeout("location.href='/portal/dashboard'", 100);
						}
					});
				}else
				if (data.ret == 1) {
					window.location.href = data.url;
				}else
				if (data.ret == -1) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'info',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.location.href = data.url;
						}
					});
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}	
</script>
	
	