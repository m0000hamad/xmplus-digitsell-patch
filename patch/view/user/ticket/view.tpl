{include file='user/layout/header.tpl'}
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('ReplyTicket')}</h1>
			</div>
        </div>
    </div>

{include file='common/ticketchat.tpl'}

    <div class="row justify-content-lg-center">
        <div class="col-lg-10">
          <div class="d-grid gap-3 gap-lg-5">
				<div class="card card-shadow shadow-lg rounded">
					<div class="card-header card-header-content-between border-bottom">
						<h4 class="card-header-title">
							<img class="avatar avatar-circle avatar-lg" src="{$user->image()}"> {$user->username}
						</h4>
					</div>

					<div class="card-body">
						{$rtl = explode(',',$Config['rtlanguages'])}
						<div class="tk-thread{if in_array($session->get('locale'), $rtl)} tk-rtl{/if}" id="tkThread">
							{foreach $ticketset as $ticket}
								<div class="tk-msg {if $ticket->isStaff()}tk-theirs{else}tk-mine{/if}">
									<div class="tk-meta">
										<span class="tk-who">{if $ticket->isStaff()}{$translate->get('Support')}{else}{$translate->get('You')}{/if}</span>
										<time>{date('Y-m-d H:i',$ticket->datetime)}</time>
									</div>
									<div class="tk-bubble{if $ticket->isSticker()} tk-sticker{/if}">{$ticket->html() nofilter}</div>
									{if $ticket->files != ""}
										<a class="tk-file" href="/uploads/tickets/{$ticket->files}" target="_blank" rel="noopener">
											<i class="fa fa-image"></i>
											<span>{$ticket->files}</span>
										</a>
									{/if}
								</div>
							{/foreach}
						</div>
					</div>

					<div class="card-footer">
						<div class="tk-composer">
							<textarea rows="3" class="form-control" name="message" id="message" placeholder="{$translate->get('TypeHere')}"></textarea>
							<div class="tk-tools">
								<button type="button" class="tk-tool" id="tkEmojiBtn">😊 {$translate->get('Emoji')}</button>
								<span class="tk-hint">{$translate->get('NewLineHint')}</span>
							</div>
						</div>
						<input type="text" class="form-control" name="files" id="files" hidden>
						<div class="d-grid mt-3">
							<button class="btn btn-dark btn-space mb-0 replyTicket">{$translate->get('Submit')}</button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

{include file='user/layout/footer.tpl'}
<script>
	window.TicketChatI18n = new Object();
	window.TicketChatI18n.stickers = "{$translate->get('Stickers')|escape:'javascript'}";
	window.TicketChatI18n.emoji    = "{$translate->get('Emoji')|escape:'javascript'}";
</script>
<script>
	TicketChat.attachEmoji(document.getElementById('tkEmojiBtn'), document.getElementById('message'));
	TicketChat.scrollToBottom(document.getElementById('tkThread'));

	$('.replyTicket').click(function(e) {
		var me = $(this);
		e.preventDefault();
        $.ajax({
            type: "PUT",
            url: "/portal/ticket/{$id}",
			dataType: "json",
            data: {
				content: $("#message").val(),
				status: 0,
			},
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
					window.setTimeout("location.href='/portal/tickets'", 1500);
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
