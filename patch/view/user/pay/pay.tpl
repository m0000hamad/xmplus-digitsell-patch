{include file='user/layout/header.tpl'}
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('Checkout')}</h1>
			</div>
        </div>
    </div>
	  
	<div class="row mb-3">
		<div class="col-xl-8 col-lg-8 col-md-12 col-sm-12">
			<div class="row mb-2">
				{include file='user/pay/cycle.tpl'}
			</div>
		</div>
		{include file='user/pay/summary.tpl'}
	</div>
	{include file='user/pay/card.tpl'}
	{include file='user/pay/qrcode.tpl'}
	
{include file='user/layout/footer.tpl'}
{include file='common/orderresult.tpl'}

<script src="/assets/js/mobile-detect.min.js"></script>

{if $stripecount > 0}
   <script async defer src="https://js.stripe.com/v3/"></script>
{/if} 

<script>
	window.PayWords = new Object();
	window.PayWords.paidTitle = "{$translate->get('PayDoneTitle')|escape:'javascript'}";
	window.PayWords.paidText  = "{$translate->get('PayDoneText')|escape:'javascript'}";
	window.PayWords.toPanel   = "{$translate->get('PayGoPanel')|escape:'javascript'}";
	window.PayWords.orderNo   = "{$translate->get('TransactionNo')|escape:'javascript'}";
	window.PayWords.plan      = "{$translate->get('Package')|escape:'javascript'}";
	window.PayWords.paid      = "{$translate->get('Total')|escape:'javascript'}";

	window.PayOrder = new Object();
	window.PayOrder.id    = "{$order->order_id|escape:'javascript'}";
	window.PayOrder.name  = "{$package->name|escape:'javascript'}";
	window.PayOrder.total = "{$currency->symbol_left} {number_format((float)$order->total_amount, (int){$currency->decimals})} {$currency->symbol_right}";

	{if $order->refund_amount > 0 || $order->refund_amount != "" && $order->upgrade == 1}
	Swal.fire({
		title: '',
		html: "{str_replace(['%currency%', '%money%'],[$Config['default_currency_symbol'], $order->refund_amount],$translate->get('RefundNote'))}",
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
	})
	{/if}	
			
{if $stripecount > 0}

	function stripConfirm(stripe_pk,stripe_sk){
		
		const stripe = Stripe(stripe_pk, {
			apiVersion: '2020-08-27',
		});
		
		if(HSThemeAppearance.getOriginalAppearance() == "dark"){
			var theme = "#fff";
		}else{
			var theme = "#132144";
		}
		
		const style = {
		  base: {
			color: theme,
		  },
		};		
		const elements = stripe.elements();
		
		var cardNumberElement = elements.create('cardNumber', {
			style
		});
		var cardExpiryElement = elements.create('cardExpiry',  {
			style
		});
		var cardCvcElement = elements.create('cardCvc', {
			style
		});
		var postalCodeElement = elements.create('postalCode', {
			style
		});
		
		cardNumberElement.mount('#cardNumber');
		cardExpiryElement.mount('#cardExpiry');
		cardCvcElement.mount('#cardCvc');
		postalCodeElement.mount('#postalCode');

		$('#CardModal').modal('show');
		layer.closeAll('loading');
		
		const button = document.querySelector('#submit');

		button.addEventListener('click', async (e) => {
			layer.load(2);
			e.preventDefault();
			
			setLoading(true);			
			
			//const name = $('#cardNameLabel').val();
			
			const {
				error: stripeError, 
				paymentIntent
			} = await stripe.confirmCardPayment(
				stripe_sk,
				{
					payment_method : {
						card: cardNumberElement,
						billing_details: {
						  email: '{$user->email}'
						}
					},
				}
			);

		  if (stripeError && (stripeError.type === "card_error" || stripeError.type === "validation_error" || stripeError.type === "invalid_request_error")) {
			setLoading(false);
			layer.closeAll('loading');
			//$('#CardModal').modal('hide');
			showMessage('error',stripeError.message);
		  }
		  
		  if (paymentIntent && (paymentIntent.type === "payment_intent.succeeded" || paymentIntent.status === "succeeded")) {
				layer.closeAll('loading');
				$('#CardModal').modal('hide');
				showSuccessMessage('success',"{$translate->get('PaymentSuccessful')}");
		  }
		  
		  setLoading(false);
		});

		function showMessage(icon, messageText) {
			Swal.fire({
				title: '',
				html: messageText,
				icon: icon,
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

		function showSuccessMessage(icon, messageText) {
			Swal.fire({
				title: '',
				html: messageText,
				icon: icon,
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
					window.setTimeout("location.href='/portal/orders'", 500);
				}
			});		
		}
		
		function setLoading(isLoading) {
		  if (isLoading == true) {
			document.querySelector("#submit").disabled = true;

		  } else {
			document.querySelector("#submit").disabled = false;

		  }
		}	
	}
{/if}
	var ci;
	
	var ti;
	
	var qi;
	
	var md = new MobileDetect(window.navigator.userAgent);
	
	{if $payments->count() > 0}
		Gatewayfee();
	{/if}
	
	function Gatewayfee(){
		var paymentid =  $("input[name='payments']:checked").val();
		$.ajax({
			type: "POST",
			url: "/portal/order/gateway_fee",
			dataType: "json",
			data: {
				method: paymentid,
				order_id : "{$order->order_id}",
			},
			success: (data) => {
				$("#total").html(data.total);
				$("#gateway_fee").html(data.gateway_fee);
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText);
			}
		});	
	}
	
	$('.btn-close').click(function(e) {
		document.getElementById("checkout").disabled = false;
	})
	
	$('.checkout').click(function(e) {
		e.preventDefault();
		clearTimeout(ci);
		clearTimeout(ti);
		clearTimeout(qi);
		layer.load(2);
		document.getElementById("checkout").disabled = true;
		var paymentid =  $("input[name='payments']:checked").val();
		$.ajax({
			type: "POST",
			url: "/portal/order/pay",
			dataType: "json",
			data: {
				order_id : "{$order->order_id}",
				method: paymentid,
				token: '',
			},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) {
					if(data.type == -1){
						layer.msg(data.msg, {
							time: 5000,
							offset:  '100px'
						});
						window.setTimeout("location.href='/portal/dashboard'", 1500);
					}else
					if(data.type == 6){
						$("#perfectmoney").html(data.data);
						document.forms['perfectmoney'].submit();  
					}else
					if(data.type == 1){
						window.location.href = data.data;
					}else
					if(data.type == 2){
						$order_id = data.orderid;
						{if $stripecount > 0}
							layer.load(2);
							stripConfirm(data.stripe_pk, data.data.client_secret);
						{/if}
					}else
					if(data.type == 0){	
					    $("#qrcode").html("");
						$('#mobile').html("");
						$order_id = data.orderid;
						document.getElementById('qrcode').innerHTML = '<img src="'+data.qrcode+'">';
						document.getElementById('amount').innerHTML =  data.amount;
						if (data.note){
							$('#_pay_note').html(data.note);
						}
						if (data.deeplink){
							if (md.os() == "AndroidOS" || md.is('iPhone') == "true" || md.is('iPhone') == true || md.phone() != null || md.mobile() != null) {
								$('#mobile').html('<a class="btn btn-sm btn-dark" href="'+data.deeplink+'" target="_blank">{$translate->get('mobile_link')}</a>');
							}
						}
						var id = data.orderid;
						Check(id);
						$('#_pay').modal('show');
					}else{
						$('#mobileid').html("");
						$('#pay_qrcode').html("");
						$order_id = data.orderid;
						$exp_time = data.expire;
						timer($exp_time);
						document.getElementById('pay_amount').innerHTML =  data.amount;
						document.getElementById('pay_qrcode').innerHTML = '<img src="'+data.qrcode+'">';
						if (data.note){
							$('#pay_note').html(data.note);
						}
						if (data.deeplink){
							if (md.os() == "AndroidOS" || md.is('iPhone') == "true" || md.is('iPhone') == true || md.phone() != null || md.mobile() != null) {
								$('#mobileid').html('<a class="btn btn-sm btn-dark" href="'+data.deeplink+'" target="_blank">{$translate->get('mobile_link')}</a>');
							}
						}
						var id = data.orderid;
						Check(id);
						$('#crypto').html('');
						if (data.crypto){
							$('#crypto').html(data.crypto);
						}
						$('#pay_').modal('show');
					}
					if (data.payment == "USDT"){
						Query(data.data, data.create);
					}
					if (data.payment == "TRX"){
						QueryTRX(data.data, data.create, data.expire);
					}
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					document.getElementById("checkout").disabled = false;
				}
			},
			error: (jqXHR) => {
			    layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
				document.getElementById("checkout").disabled = false;
			}
		});
	})
	
	function addZero(i) {
	  if (i < 10) {
		i = "0" + i;
	  }
	  return i;
	}
	
	function Check(id) {
	  $.ajax({
		type: "POST",
		url: "/portal/order/query",
		dataType: "json",
		data: {
		  id : id
		},
		success: (data) => {
			if (data.status == 1 ) {
				clearTimeout(ci);
				$('#CardModal').modal('hide');
				$('#_pay').modal('hide');
				$('#pay_').modal('hide');

				var verdict = {
					kind: 'ok',
					title: window.PayWords.paidTitle,
					text: window.PayWords.paidText,
					button: window.PayWords.toPanel,
					seconds: 6,
					meta: [
						[window.PayWords.orderNo, window.PayOrder.id],
						[window.PayWords.plan, window.PayOrder.name],
						[window.PayWords.paid, window.PayOrder.total]
					]
				};

				/* shown here, and again on the page the buyer lands on, so the
				   answer survives the redirect either way */
				window.OrderResult.carry(verdict);

				/* a copy with a shorter fuse for this page; note the round trip
				   rather than a brace literal, which Smarty would read as a tag */
				var here = JSON.parse(JSON.stringify(verdict));
				here.seconds = 4;
				here.then = function () { location.href = '/portal/dashboard'; };
				window.OrderResult.show(here);

				window.setTimeout(function () { location.href = '/portal/dashboard'; }, 4600);
			}
		},
		error: (jqXHR) => {
			clearTimeout(ci);
			layer.msg(jqXHR.responseText);
		}
	  });
	  ci = setTimeout(function () {
		Check(id);
	  }, 4000);
	}
	
	$('.cancel').click(function(e) {
		e.preventDefault();
		Swal.fire({
			title: '',
			html: "{$translate->get('ConfirmDeleteNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('CancelOrder')}",
			cancelButtonText: "{$translate->get('Close')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-danger ms-1',
				cancelButton: 'btn btn-secondary ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				$('#CardModal').modal('hide');
				$('#_pay').modal('hide');
				$('#pay_').modal('hide');
				clearTimeout(ci);
				clearTimeout(qi);
				clearTimeout(ti);
				setCancel();
			}
		});	
	})
	
	function timer(exp_time){
		var countDownDate = new Date(exp_time * 1000).getTime();
		var now = new Date().getTime();
		var distance = countDownDate - now;
		var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
		var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
		var seconds = Math.floor((distance % (1000 * 60)) / 1000);
		if (distance > 0) {
			document.getElementById("timeout").innerHTML = addZero(hours) + " : " + addZero(minutes) + " : " + addZero(seconds);
		}

		if (distance <= 0 ) {
			clearTimeout(ci);
			clearTimeout(ti);
			clearTimeout(qi);
			setExpired($order_id);
		}
		
		ti = setTimeout(function () {
			timer(exp_time);
		}, 1000);
	}
	
	function setExpired(id){
	  $.ajax({
		type: "POST",
		url: "/portal/order/timeout",
		dataType: "json",
		data: {
		  id : id,
		},
		success: (data) => {
			clearTimeout(ti);
			if (data.ret == 1) {
				layer.msg(data.msg);
				window.setTimeout("location.href='/portal/orders'", 2000);
			}else{
				layer.msg(data.msg);
			}
		},
		error: (jqXHR) => {
			clearTimeout(ti);
			layer.msg(jqXHR.responseText);
		},
		complete: () => {
			return;
		}
	  });
	}
	
	function setCancel(){
	  $.ajax({
		type: "POST",
		url: "/portal/order/cancel",
		dataType: "json",
		data: {
		  id : {$order->id},
		},
		success: (data) => {
			if (data.ret == 1) {
				layer.msg(data.msg, {
					time: 3000,
					offset:  '100px'
				});
				window.setTimeout("location.href='/portal/orders'", 2000);
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
	
	function Query(address, create) {
	  $.ajax({
		type: "POST",
		url: "/usdt",
		dataType: "json",
		data: {
		  address,
		  create
		},
		success: (data) => {},
	  });
	  qi = setTimeout(function () {
		Query(address, create);
	  }, 10000);
	}
	
    function QueryTRX(address, start, end) {
	  $.ajax({
		type: "POST",
		url: "/trx",
		dataType: "json",
		data: {
		  address,
		  start,
		  end
		},
		success: (data) => {},
	  });
	  qi = setTimeout(function () {
		QueryTRX(address, start, end);
	  }, 10000);
	}	
</script>
