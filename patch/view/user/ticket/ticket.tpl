{include file='user/layout/header.tpl'}

    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('Tickets')}</h1>
			</div>
			<div class="col-sm-auto">
				<button data-bs-toggle="modal" data-bs-target="#add_ticket" class="btn btn-sm btn-dark" >{$translate->get('OpenTicket')}</button>
			</div>
        </div>
    </div>
	  
	<div class="row match-height">
		{include file='user/ticket/datatables.tpl'}
	</div>
	{include file='common/ticketchat.tpl'}
	{include file='user/ticket/open.tpl'}
{include file='user/layout/footer.tpl'}
<script>
    {include file='table/table_storage.tpl'}
	{include file='table/table_desc.tpl'}

    function CloseTicket(id) {
        ticket = id;
		Swal.fire({
			title: "{$translate->get('ConfirmClose')}",
			text: "{$translate->get('ConfirmCloseTicket')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			allowOutsideClick: false,
			confirmButtonText: "{$translate->get('Continue')}",
			cancelButtonText: "{$translate->get('Cancel')}",
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
            url: "/portal/ticket/close",
            dataType: "json",
            data: {
                id: ticket
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
                    {include file='table/reload.tpl'}
                } else {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset: '100px'
				});
            }
        });
    }
	
	$('.sendTicket').click(function(e) {
		var me = $(this);
		e.preventDefault();
        $.ajax({
            type: "POST",
            url: "/portal/ticket",
			dataType: "json",
            data: {
				department : $("#department").val(),
				title: $("#title").val(),
				content: $("#message").val(),
			},
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
					$('#add_ticket').modal('hide');
                    {include file='table/reload.tpl'}
                } else {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset: '100px'
				});
            },
			complete: () => {
				me.data('requestRunning', false);
				return;
			}
        });
    })
</script>

<script>
	window.TicketChatI18n = new Object();
	window.TicketChatI18n.stickers = "{$translate->get('Stickers')|escape:'javascript'}";
	window.TicketChatI18n.emoji    = "{$translate->get('Emoji')|escape:'javascript'}";
	TicketChat.attachEmoji(document.getElementById('tkOpenEmojiBtn'), document.getElementById('message'));
</script>
{include file='common/ticketrowlink.tpl'}
