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
				<h1 class="page-header-title">{$translate->get('Plans')}</h1>
			</div>
			<div class="col-sm-auto">
				<a href="plan/add" class="btn btn-sm btn-dark" >{$translate->get('AddPlan')}</a>
			</div>
        </div>
    </div>

	<div class="row match-height">
		{include file='admin/plans/datatable.tpl'}
	</div>	  
{include file='admin/layout/footer.tpl'}
{include file='admin/plans/timeplanjs.tpl'}

<script>

	// the rows a per-day time plan leaves behind are not plans; hide them
	$(document).ready(function () {
		timeplanBoot([], null, null, null, null, null, null, null, null, 0, []);
	});
</script>

<script>

    {include file='table/table_storage.tpl'}
	{include file='table/table_asc.tpl'}

    function deletePlan(id) {
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
            url: "/admin/plan/delete",
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

	function PlanStatus(id) {
		if (document.getElementById('status_'+id).checked) {
			var status = 1;
		} else  {
			var status = 0;
		}
		$.ajax({
			type: "POST",
			url: "/admin/plan/status",
			dataType: "json",
			data: {
				id: id,
				status : status
			},
			success: (data) => {
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}else{
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