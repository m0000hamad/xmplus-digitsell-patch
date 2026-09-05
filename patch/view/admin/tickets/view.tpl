<script>localStorage.setItem('toggleID', ''); </script>
{include file='admin/layout/header.tpl'}
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
							<img class="avatar avatar-circle avatar-lg" src="{$findUser->user($ticket_main->userid)->image()}"> {$findUser->user($ticket_main->userid)->username}
						</h4>
					</div>

					<div class="card-body">
						{$rtl = explode(',',$Config['rtlanguages'])}
						<div class="tk-thread{if in_array($session->get('locale'), $rtl)} tk-rtl{/if}" id="tkThread">
							{foreach $ticketset as $ticket}
								<div class="tk-msg {if $ticket->isStaff()}tk-mine{else}tk-theirs{/if}">
									<div class="tk-meta">
										<span class="tk-who">{if $ticket->isStaff()}{$ticket->username}{else}{$translate->get('Customer')}{/if}</span>
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
								{if $Config['ticket_signature'] != ""}
									<button type="button" class="tk-tool" id="tkSignBtn">✍️ {$translate->get('InsertSignature')}</button>
									<button type="button" class="tk-tool" id="tkAutoSignBtn">{$translate->get('AutoSignature')}</button>
								{/if}
								<span class="tk-hint">{$translate->get('NewLineHint')}</span>
							</div>
						</div>
						<input type="text" class="form-control" name="files" id="files" hidden>
						<div class="d-grid mt-3">
							<button class="btn btn-dark btn-space mb-0" onClick="replyTicket()">{$translate->get('Submit')}</button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

{include file='admin/layout/footer.tpl'}
<script>
	window.TicketChatI18n = new Object();
	window.TicketChatI18n.stickers = "{$translate->get('Stickers')|escape:'javascript'}";
	window.TicketChatI18n.emoji    = "{$translate->get('Emoji')|escape:'javascript'}";
	window.TicketSignature = "{$Config['ticket_signature']|escape:'javascript'}";
{literal}
	(function () {
		var textarea = document.getElementById('message');
		var signBtn = document.getElementById('tkSignBtn');
		var autoBtn = document.getElementById('tkAutoSignBtn');
		var AUTO_KEY = 'tk_auto_signature';

		TicketChat.attachEmoji(document.getElementById('tkEmojiBtn'), textarea);
		TicketChat.scrollToBottom(document.getElementById('tkThread'));

		function signature() {
			return (window.TicketSignature || '').replace(/\r\n/g, '\n');
		}

		function hasSignature() {
			return signature() !== '' && textarea.value.indexOf(signature()) !== -1;
		}

		function appendSignature() {
			if (signature() === '' || hasSignature()) { return; }
			var body = textarea.value.replace(/\s+$/, '');
			textarea.value = (body === '' ? '' : body + '\n\n') + signature();
		}

		if (signBtn) {
			signBtn.addEventListener('click', function () {
				appendSignature();
				textarea.focus();
			});
		}

		function autoOn() {
			try { return localStorage.getItem(AUTO_KEY) === '1'; } catch (e) { return false; }
		}

		if (autoBtn) {
			var paint = function () { autoBtn.classList.toggle('tk-on', autoOn()); };
			paint();

			autoBtn.addEventListener('click', function () {
				try { localStorage.setItem(AUTO_KEY, autoOn() ? '0' : '1'); } catch (e) {}
				paint();
			});
		}

		// exposed so the send handler below can use it
		window.TicketApplyAutoSignature = function () {
			if (autoOn()) { appendSignature(); }
		};
	})();
{/literal}

	function replyTicket() {
		if (window.TicketApplyAutoSignature) { window.TicketApplyAutoSignature(); }

        $.ajax({
            type: "PUT",
            url: "/admin/ticket/{$id}",
			dataType: "json",
            data: {
				files: $("#files").val(),
				content: $("#message").val(),
				status: 1,
			},
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
					window.setTimeout("location.href='/admin/tickets'", 1500);
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
</script>
