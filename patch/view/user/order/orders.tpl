{include file='user/layout/header.tpl'}

{literal}
<style>
.od-head { border: 0; padding: 0; margin-bottom: 18px; }
.od-head-inner {
	border-radius: 20px;
	padding: 20px 22px;
	background: linear-gradient(135deg, #0f766e, #14b8a6 55%, #0ea5e9);
	color: #fff;
	box-shadow: 0 14px 34px rgba(20, 184, 166, .28);
}
.od-head-title { font-size: 20px; font-weight: 800; margin: 0 0 5px; color: #fff; }
.od-head-sub { font-size: 12.5px; margin: 0; color: rgba(255, 255, 255, .86); line-height: 1.8; }
@media (max-width: 575.98px) {
	.od-head-inner { padding: 17px; }
	.od-head-title { font-size: 17.5px; }
}
</style>
{/literal}

	<div class="page-header od-head">
		<div class="od-head-inner">
			<h1 class="od-head-title">🧾 {$translate->get('Orders')}</h1>
			<p class="od-head-sub">{$translate->get('OrdersSubtitle')}</p>
		</div>
	</div>
	  
	<div class="row match-height">
		{include file='user/order/datatables.tpl'}
	</div>
	{include file='user/order/invoice.tpl'}
{include file='user/layout/footer.tpl'}
{include file='common/orderresult.tpl'}
<script>
    {include file='table/table_storage.tpl'}
	{include file='table/table_desc.tpl'}

    function CancelOrder(id) {
        deleteid = id;
		Swal.fire({
			title: "{$translate->get('ConfirmCancel')}",
			text: "{$translate->get('ConfirmDeleteNote')}",
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
				delete_id();
			}
		});
    }

	function delete_id() {
        $.ajax({
            type: "DELETE",
            url: "/portal/order/cancel",
            dataType: "json",
            data: {
                id: deleteid
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg);
                    {include file='table/reload.tpl'}
                } else {
					layer.msg(data.msg);
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText);
            }
        });
    }
	
	function InvoiceModal(id) {
        $.ajax({
            type: "POST",
            url: "/portal/order/details",
            dataType: "json",
            data: {
                id: id
            },
            success: data => {
                if (data.ret) {
					$('#order_id').html(data.orderid);
					$('#order_status').html(data.status);
					$('#order_date').html(data.pay_time);
					$('#order_method').html(data.pay_method);
					$('#order_fee').html(data.gateway_fee);
					$('#order_price').html(data.subtotal);
					$('#order_discount').html(data.discount);
					$('#order_total').html(data.total);
					$('#order_name').html(data.packagename);
					$('#InvoiceModal').modal('show');
                } else {
					layer.msg(data.msg);
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText);
            }
        });
    }	
</script>	