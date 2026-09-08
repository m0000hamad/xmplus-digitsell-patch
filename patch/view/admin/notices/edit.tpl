{include file='admin/layout/header.tpl'}
	<script>localStorage.setItem('toggleID', ''); </script>

{literal}
<style>
/* Edit a notice — same shell as add.tpl: RTL Persian editor, ready-made
 * snippets and a live preview of the user's popup. Save contract kept:
 * #title #status #sendmail #content + the record id. */
.nadm-grid { display: grid; grid-template-columns: 1fr; gap: 18px; }
@media (min-width: 1200px) { .nadm-grid { grid-template-columns: 1.55fr 1fr; align-items: start; } }

.nadm-card {
	border-radius: 18px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .09);
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
	overflow: hidden;
}
.nadm-card-head {
	display: flex;
	align-items: center;
	gap: 11px;
	padding: 16px 18px 12px;
	border-bottom: 1px solid rgba(23, 32, 61, .07);
}
.nadm-card-ico {
	width: 38px;
	height: 38px;
	border-radius: 12px;
	background: rgba(99, 102, 241, .12);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 19px;
}
.nadm-card-title { font-size: 14.5px; font-weight: 800; color: #16203d; margin: 0; }
.nadm-card-sub { font-size: 11px; font-weight: 600; color: #8c98ab; margin: 2px 0 0; }
.nadm-card-body { padding: 16px 18px 18px; }

.nadm-field { margin-bottom: 15px; }
.nadm-field:last-child { margin-bottom: 0; }
.nadm-label { display: block; font-size: 12px; font-weight: 700; color: #56617a; margin-bottom: 6px; }
.nadm-row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
@media (max-width: 575.98px) { .nadm-row2 { grid-template-columns: 1fr; } }

.nadm-snips { display: flex; flex-wrap: wrap; gap: 7px; margin-bottom: 12px; }
.nadm-snip {
	border: 1.5px solid rgba(99, 102, 241, .3);
	background: rgba(99, 102, 241, .1);
	color: #4f46e5;
	border-radius: 999px;
	padding: 6px 13px;
	font-size: 12px;
	font-weight: 700;
	cursor: pointer;
	transition: background .14s ease, transform .14s ease;
}
.nadm-snip:hover { background: rgba(99, 102, 241, .2); transform: translateY(-1px); }
.nadm-snip:active { transform: scale(.96); }

.nadm-prev { position: sticky; top: 20px; }
.nadm-prev-shell {
	border-radius: 16px;
	border: 1.5px solid rgba(23, 32, 61, .09);
	background: linear-gradient(180deg, rgba(244, 247, 252, .7), #fff);
	padding: 16px;
}
.nadm-prev-note {
	border-radius: 14px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .1);
	box-shadow: 0 12px 30px rgba(23, 32, 61, .1);
	overflow: hidden;
}
.nadm-prev-bar {
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
	color: #fff;
	font-size: 12.5px;
	font-weight: 800;
	padding: 11px 15px;
	display: flex;
	align-items: center;
	gap: 8px;
}
.nadm-prev-inner { padding: 15px 16px; }
.nadm-prev-title { font-size: 14px; font-weight: 800; color: #16203d; margin: 0 0 8px; line-height: 1.6; }
.nadm-prev-body {
	font-size: 13px;
	font-weight: 500;
	color: #3f4a63;
	line-height: 2;
	word-break: break-word;
	font-family: 'IRANSans', Tahoma, sans-serif;
	min-height: 60px;
}
.nadm-prev-body p:last-child { margin-bottom: 0; }
.nadm-prev-body img { max-width: 100%; height: auto; border-radius: 9px; }
.nadm-prev-empty { color: #9aa4b6; font-weight: 600; }

html[data-hs-theme="dark"] .nadm-card,
html[data-hs-theme="dark"] .nadm-prev-note { background: #1c2536; border-color: rgba(255, 255, 255, .09); }
html[data-hs-theme="dark"] .nadm-card-head { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .nadm-card-title,
html[data-hs-theme="dark"] .nadm-prev-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .nadm-prev-body { color: #b9c2d4; }
html[data-hs-theme="dark"] .nadm-prev-shell { background: rgba(255, 255, 255, .03); border-color: rgba(255, 255, 255, .09); }
html[data-hs-theme="dark"] .nadm-label { color: #b9c2d4; }
</style>
{/literal}

	<div class="page-header">
		<div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">📝 {$translate->get('EditNotice')}</h1>
			</div>
		</div>
	</div>

	<div class="nadm-grid">

		<div class="nadm-card">
			<div class="nadm-card-head">
				<span class="nadm-card-ico">✍️</span>
				<div>
					<h4 class="nadm-card-title">{$translate->get('Notice')}</h4>
					<p class="nadm-card-sub">{$translate->get('NoticeWriteHint')}</p>
				</div>
			</div>
			<div class="nadm-card-body">
				<div class="nadm-row2 nadm-field">
					<div>
						<label class="nadm-label" for="status">{$translate->get('Status')}</label>
						<div class="tom-select-custom">
							<select class="js-select form-select shadow-lg" id="status" name="status" data-hs-tom-select-options='{literal}{"hideSearch": true}{/literal}'>
								<option value="0" {if $notice->status == "0"}selected{/if}>{$translate->get('Disable')}</option>
								<option value="1" {if $notice->status == "1"}selected{/if}>{$translate->get('Enable')}</option>
							</select>
						</div>
					</div>
					<div>
						<label class="nadm-label" for="sendmail">{$translate->get('SendNotice')}</label>
						<div class="tom-select-custom">
							<select class="js-select form-select shadow-lg" id="sendmail" name="sendmail" data-hs-tom-select-options='{literal}{"hideSearch": true}{/literal}'>
								<option value="0">{$translate->get('Disable')}</option>
								<option value="1">{$translate->get('Enable')}</option>
							</select>
						</div>
					</div>
				</div>

				<div class="nadm-field">
					<label class="nadm-label" for="title">{$translate->get('Title')}</label>
					<input type="text" class="form-control shadow-lg" value="{$notice->title|escape:'html'}" id="title" placeholder="{$translate->get('Title')}">
				</div>

				<div class="nadm-field">
					<label class="nadm-label">{$translate->get('NoticeSnippets')}</label>
					<div class="nadm-snips" id="nadmSnips">
						<button type="button" class="nadm-snip" data-snip="welcome">👋 {$translate->get('SnipWelcome')}</button>
						<button type="button" class="nadm-snip" data-snip="maintenance">🛠️ {$translate->get('SnipMaintenance')}</button>
						<button type="button" class="nadm-snip" data-snip="price">💰 {$translate->get('SnipPrice')}</button>
						<button type="button" class="nadm-snip" data-snip="server">🚀 {$translate->get('SnipServer')}</button>
						<button type="button" class="nadm-snip" data-snip="outage">⚠️ {$translate->get('SnipOutage')}</button>
					</div>
				</div>

				<div class="nadm-field">
					<label class="nadm-label" for="content">{$translate->get('Notice')}</label>
					<textarea id="content" class="display shadow-lg">{$notice->content}</textarea>
				</div>
			</div>
		</div>

		<div class="nadm-prev">
			<div class="nadm-card">
				<div class="nadm-card-head">
					<span class="nadm-card-ico">👁️</span>
					<div>
						<h4 class="nadm-card-title">{$translate->get('NoticePreviewTitle')}</h4>
						<p class="nadm-card-sub">{$translate->get('NoticePreviewHint')}</p>
					</div>
				</div>
				<div class="nadm-card-body">
					<div class="nadm-prev-shell">
						<div class="nadm-prev-note">
							<div class="nadm-prev-bar">📢 {$translate->get('LatestNotice')}</div>
							<div class="nadm-prev-inner">
								<h5 class="nadm-prev-title" id="prevTitle" hidden></h5>
								<div class="nadm-prev-body" id="prevBody"><span class="nadm-prev-empty">{$translate->get('NoticePreviewEmpty')}</span></div>
							</div>
						</div>
					</div>
				</div>
			</div>
		</div>

	</div>

	<div class="position-fixed start-50 bottom-0 translate-middle-x w-100 zi-99 mb-3" style="max-width: 40rem;">
		<div class="card card-sm bg-dark border-dark mx-2">
			<div class="card-body">
				<div class="row justify-content-center justify-content-sm-between">
					<div class="col">
						<a type="button" onClick="deleteNoticeModal()" class="btn btn-ghost-danger">{$translate->get('Delete')}</a>
					</div>
					<div class="col-auto">
						<div class="d-flex gap-3">
							<a type="button" href="/admin/notices" class="btn btn-ghost-light">{$translate->get('Discard')}</a>
							<button type="submit" onClick="saveNotice()" class="btn btn-dark">{$translate->get('Save')}</button>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

{include file='admin/layout/footer.tpl'}
<script src="/assets/plugins/tinymce/tinymce.min.js"></script>
<script>
	window.NADM_RTL = {if $session->get('locale') == "fa_IR"}true{else}false{/if};
	window.NADM_LANG = {if $session->get('locale') == "zh_CN"}"zh_CN"{else}null{/if};
	window.NADM_ID = "{$notice->id|escape:'javascript'}";
	window.NADM_I18N_ConfirmDelete     = "{$translate->get('ConfirmDelete')|escape:'javascript'}";
	window.NADM_I18N_ConfirmDeleteNote = "{$translate->get('ConfirmDeleteNote')|escape:'javascript'}";
	window.NADM_I18N_Delete            = "{$translate->get('Delete')|escape:'javascript'}";
	window.NADM_I18N_Cancel            = "{$translate->get('Cancel')|escape:'javascript'}";
</script>
{literal}
<script>
	var NADM_SNIPPETS = {
		welcome:     '<p><strong>کاربر گرامی، به پنل ما خوش آمدید.</strong></p><p>در صورت داشتن هرگونه سوال از بخش تیکت با پشتیبانی در ارتباط باشید.</p>',
		maintenance: '<p><strong>اطلاعیه تعمیرات برنامه‌ریزی‌شده</strong></p><p>در تاریخ ____ ساعت ____ به مدت حدود ____ سرویس جهت به‌روزرسانی زیرساخت در دسترس نخواهد بود. از شکیبایی شما سپاسگزاریم.</p>',
		price:       '<p><strong>تغییر تعرفه پلن‌ها</strong></p><p>از تاریخ ____ قیمت پلن‌ها به‌روزرسانی می‌شود. پلن‌های فعال فعلی تا پایان دوره با همان نرخ ادامه می‌یابند.</p>',
		server:      '<p><strong>افزوده شدن سرور جدید</strong></p><p>یک لوکیشن جدید به مجموعه سرورها اضافه شد. برای استفاده، کانفیگ خود را از صفحه سرورها دریافت یا لینک اشتراک را یک بار به‌روزرسانی کنید.</p>',
		outage:      '<p><strong>قطعی موقت سرویس</strong></p><p>به دلیل اختلال در مسیر شبکه، برخی کاربران بین ساعات ____ تا ____ با کندی مواجه شدند. مشکل برطرف شده است و در صورت تداوم، لینک اشتراک را به‌روزرسانی کنید.</p>'
	};

	function nadmRefreshPreview() {
		var t = (document.getElementById('title') || {}).value || '';
		var pt = document.getElementById('prevTitle');
		if (pt) {
			pt.textContent = t.trim();
			pt.hidden = t.trim() === '';
		}
		var pb = document.getElementById('prevBody');
		var html = '';
		try { html = (window.tinymce && tinymce.get('content')) ? tinymce.get('content').getContent() : ''; } catch (e) {}
		if (pb) {
			if (html && html.replace(/<[^>]*>/g, '').trim() !== '') {
				pb.innerHTML = html;
			} else {
				pb.innerHTML = '<span class="nadm-prev-empty">' + (pb.getAttribute('data-empty') || '') + '</span>';
			}
		}
	}

	$(document).ready(function () {
		var pb = document.getElementById('prevBody');
		if (pb) { pb.setAttribute('data-empty', pb.textContent.trim()); }

		var isSmallScreen = window.matchMedia('(max-width: 1023.5px)').matches;
		tinymce.init({
			selector: '.display',
			language: window.NADM_LANG ? window.NADM_LANG : undefined,
			directionality: window.NADM_RTL ? 'rtl' : 'ltr',
			plugins: 'preview importcss searchreplace directionality code visualblocks visualchars fullscreen link template codesample table charmap nonbreaking insertdatetime advlist lists charmap quickbars emoticons',
			editimage_cors_hosts: ['picsum.photos'],
			menubar: 'edit view insert format tools table',
			toolbar: 'undo redo | bold italic underline | fontfamily fontsize blocks | forecolor backcolor | alignright aligncenter alignleft | bullist numlist | link template emoticons | removeformat | rtl ltr | fullscreen preview code',
			toolbar_sticky: false,
			toolbar_sticky_offset: isSmallScreen ? 102 : 108,
			importcss_append: true,
			mobile: { menubar: true },
			height: 430,
			branding: false,
			quickbars_selection_toolbar: 'bold italic | quicklink h3 blockquote',
			quickbars_insert_toolbar: false,
			toolbar_mode: 'sliding',
			contextmenu: 'link table',
			content_css: '/assets/css/iransans.css',
			font_family_formats: 'IRANSans=IRANSans,Tahoma,sans-serif; Tahoma=Tahoma,sans-serif; Arial=arial,helvetica,sans-serif; Times=times new roman,times,serif',
			content_style: "@font-face{font-family:'IRANSans';src:local('IRANSans')} body{font-family:'IRANSans',Tahoma,sans-serif;font-size:15px;line-height:2;direction:" + (window.NADM_RTL ? 'rtl' : 'ltr') + "}",
			templates: [
				{ title: 'خوش‌آمدگویی', description: 'پیام خوش‌آمد به کاربر تازه', content: NADM_SNIPPETS.welcome },
				{ title: 'تعمیرات', description: 'اطلاع‌رسانی قطعی برنامه‌ریزی‌شده', content: NADM_SNIPPETS.maintenance },
				{ title: 'تغییر قیمت', description: 'اعلام تعرفه جدید', content: NADM_SNIPPETS.price },
				{ title: 'سرور جدید', description: 'افزوده شدن لوکیشن', content: NADM_SNIPPETS.server },
				{ title: 'قطعی موقت', description: 'گزارش اختلال رفع‌شده', content: NADM_SNIPPETS.outage }
			],
			relative_urls: false,
			remove_script_host: true,
			document_base_url: '/',
			convert_urls: true,
			setup: function (editor) {
				editor.on('init input keyup change SetContent ExecCommand Undo Redo', function () {
					nadmRefreshPreview();
				});
			}
		});

		$('#title').on('input', nadmRefreshPreview);

		document.getElementById('nadmSnips').addEventListener('click', function (e) {
			var b = e.target.closest('.nadm-snip');
			if (!b) { return; }
			var html = NADM_SNIPPETS[b.getAttribute('data-snip')];
			if (html && window.tinymce && tinymce.get('content')) {
				tinymce.get('content').execCommand('mceInsertContent', false, html);
				nadmRefreshPreview();
			}
		});
	});

	function deleteNoticeModal() {
		Swal.fire({
			title: window.NADM_I18N_ConfirmDelete,
			text: window.NADM_I18N_ConfirmDeleteNote,
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton: true,
			confirmButtonText: window.NADM_I18N_Delete,
			cancelButtonText: window.NADM_I18N_Cancel,
			allowOutsideClick: false,
			customClass: { confirmButton: 'btn btn-secondary ms-1', cancelButton: 'btn btn-danger ms-1' },
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) { delete_id(); }
		});
	}

	function delete_id() {
		$.ajax({
			type: 'DELETE',
			url: '/admin/notice/delete',
			dataType: 'json',
			data: { id: window.NADM_ID },
			success: function (data) {
				layer.msg(data.msg, { time: 5000, offset: '100px' });
				if (data.ret) { window.setTimeout("location.href='/admin/notices'", 1500); }
			},
			error: function (jqXHR) {
				layer.msg(jqXHR.responseText, { time: 5000, offset: '100px' });
			}
		});
	}

	function saveNotice() {
		layer.load(2);
		var content = tinymce.get('content').getContent();
		var markdown = tinymce.get('content').getContent({ format: 'text' });
		$.ajax({
			type: 'POST',
			url: '/admin/notice/save',
			dataType: 'json',
			data: {
				id: window.NADM_ID,
				content: content,
				markdown: markdown,
				status: $('#status').val(),
				sendmail: $('#sendmail').val(),
				title: $('#title').val()
			},
			success: function (data) {
				layer.closeAll('loading');
				layer.msg(data.msg, { time: 5000, offset: '100px' });
				if (data.ret == 1) { window.setTimeout("location.href='/admin/notices'", 1500); }
			},
			error: function (jqXHR) {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, { time: 5000, offset: '100px' });
			}
		});
	}
</script>
{/literal}
