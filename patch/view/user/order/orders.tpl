{include file='user/layout/header.tpl'}

    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('Orders')}</h1>
			</div>
        </div>
    </div>
	  
	<div class="row match-height">
		{include file='user/order/datatables.tpl'}
	</div>
	{include file='user/order/invoice.tpl'}
{include file='user/layout/footer.tpl'}
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