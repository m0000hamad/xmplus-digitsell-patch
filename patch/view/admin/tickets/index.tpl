<script>localStorage.setItem('toggleID', ''); </script>	
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
				<h1 class="page-header-title">{$translate->get('Tickets')}</h1>
			</div>
        </div>
    </div>

	<div class="row match-height">
		{include file='admin/tickets/datatable.tpl'}
	</div>	  
{include file='admin/layout/footer.tpl'}

<script>

    {include file='table/table_storage.tpl'}
	{include file='table/table_desc.tpl'}

    function CloseTicket(id) {
        ticket = id;
		Swal.fire({
			title: "{$translate->get('ConfirmClose')}",
			text: "{$translate->get('ConfirmCloseTickets')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Continue')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				close_ticket();
			}
		});
    }

	function close_ticket() {
        $.ajax({
            type: "POST",
            url: "/admin/ticket/close",
            dataType: "json",
            data: {
                id: ticket
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
</script>
{include file='common/ticketrowlink.tpl'}
