<script>localStorage.setItem('toggleID', 'transactionMenu'); </script>	
{include file='admin/layout/header.tpl'}
	<style>
		.nav-pills .nav-item .nav-link.active {
			background-color: var(--bs-dark);
			color:var(--bs-body-bg);
		}
	</style>
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('Orders')}</h1>
			</div>
        </div>
    </div>

	<div class="row match-height">
			<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
				<div class="card card-shadow shadow-lg rounded">
					<div class="card-header card-header-content-between border-bottom">						
						<h3><b>{$translate->get('List')}</b></h3>
						<div class="col-xl-2">
							<div class="mb-2 mb-md-0">
								<form>
									<div class="input-group input-group-merge input-group-flush">
										<div class="input-group-prepend input-group-text">
											<i class="bi-search"></i>
										</div>
										<input id="tableSearch" type="search" class="form-control" placeholder="{$translate->get('sSearch')}" aria-label="{$translate->get('sSearch')}">
									</div>
								</form>
							</div>
						</div>
					</div>
					<div class="card-body mb-3">
						<span class="mb-4">{include file='table/columns.tpl'}</span>
						<div class="table-responsive zi-2">
							{include file='table/datatable.tpl'}								
						</div>
					</div>
				</div>
			</div>					
	</div>	  
	{include file='admin/orders/invoice.tpl'}
	{include file='admin/orders/edit.tpl'}
	
	
<script>window.DigitsellInvoiceAdmin = true;</script>
{include file='common/invoices.tpl'}
{include file='admin/layout/footer.tpl'}

<script>

    {include file='table/table_storage.tpl'}
	{include file='table/table_desc.tpl'}

    function CancelOrderModal(id) {
        deleteid = id;
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
        $.ajax({
            type: "DELETE",
            url: "/admin/order/delete",
            dataType: "json",
            data: {
                id: deleteid
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    {include file='table/reload.tpl'}
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

    function ConfirmModal(id) {
        orderid = id;
		Swal.fire({
			title: "{$translate->get('ConfirmOrder')}",
			text: "{$translate->get('ConfirmOrderNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Confirm')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				ConfirmOrder();
			}
		});
    }
	
    function ConfirmOrder() {
        $.ajax({
            type: "PUT",
            url: "/admin/order/notify",
            dataType: "json",
            data: {
                id: orderid
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    {include file='table/reload.tpl'}
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

	function InvoiceModal(id) {
        $.ajax({
            type: "POST",
            url: "/admin/order/view",
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

	function editOrderModal(id) {
        $.ajax({
            type: "POST",
            url: "/admin/order/edit",
            dataType: "json",
            data: {
                id: id
            },
            success: data => {
                if (data.ret) {
					$('#orderid').val(data.orderid);
					$('#id').val(data.id);
					$('#username').val(data.username);
					$('#email').val(data.email);
					$('#reset_days').val(data.reset_days);
					$('#packagename').val(data.packagename);
					$('#status').val(data.status).change();
					$('#orderedit').modal('show');
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

	$('#formsubmit').submit(function(){
		$.ajax({
			type: "POST",
			url: "/admin/order/update",
			data : $('#formsubmit').serialize(),
			success: function(data){
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					$('#orderedit').modal('hide');
					{include file='table/reload.tpl'}
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: function(jqXHR) {
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			}
		});	
		 return false;
	});	
</script>	
