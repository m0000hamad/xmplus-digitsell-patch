{include file='user/layout/header.tpl'}

{literal}
<style>
/* ================================================================== *
 * Account settings.
 *
 * The stock page was a plain white sidebar of Bootstrap tabs next to
 * a stack of bordered cards. Every field sat in a three/nine column
 * split that collapsed badly on a phone, the section nav never marked
 * where you were, and none of it followed the panel's dark theme.
 *
 * It is now a gradient hero, a glass section rail with a colour per
 * section and the current one lit, and cards that carry that same
 * colour as a top accent. Every input id, button class and section
 * anchor the encoded controller and the page JS rely on is kept.
 * ================================================================== */

.set-wrap { --set: #6366f1; }
.set-wrap [id$="Section"], .set-wrap #content { scroll-margin-top: 90px; }

/* ---------- hero ---------- */
.set-hero {
	position: relative;
	border: 0;
	border-radius: 20px;
	padding: 22px 24px;
	margin-bottom: 22px;
	overflow: hidden;
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
	color: #fff;
	box-shadow: 0 14px 34px rgba(79, 70, 229, .3);
}
.set-hero h1 {
	font-size: 21px;
	font-weight: 800;
	margin: 0 0 6px;
	color: #fff;
	display: flex;
	align-items: center;
	gap: 10px;
}
.set-hero p {
	font-size: 12.5px;
	font-weight: 500;
	margin: 0;
	color: rgba(255, 255, 255, .88);
	line-height: 1.8;
	max-width: 620px;
}

/* ---------- section rail ---------- */
.set-rail {
	position: sticky;
	top: 20px;
	border-radius: 18px;
	padding: 10px;
	background: linear-gradient(180deg, rgba(255, 255, 255, .96), rgba(244, 247, 252, .97));
	border: 1.5px solid rgba(23, 32, 61, .09);
	box-shadow: 0 12px 30px rgba(23, 32, 61, .08);
}
.set-rail-title {
	font-size: 10.5px;
	font-weight: 800;
	letter-spacing: .7px;
	text-transform: uppercase;
	color: rgba(23, 32, 61, .42);
	padding: 8px 12px 6px;
}
.set-rail .nav { display: block; }
.set-rail .nav-item { display: block; }
.set-rail .nav-link {
	--sc: #6366f1;
	--sc-soft: rgba(99, 102, 241, .12);
	--sc-mid: rgba(99, 102, 241, .24);
	display: flex;
	align-items: center;
	gap: 10px;
	margin: 5px 3px;
	padding: 9px 11px;
	border-radius: 13px;
	background: var(--sc-soft);
	border: 1px solid transparent;
	color: #16203d;
	font-size: 13px;
	font-weight: 700;
	transition: background .16s ease, border-color .16s ease, transform .16s ease, box-shadow .16s ease;
}
.set-rail .nav-link:hover {
	background: var(--sc-mid);
	border-color: var(--sc);
	transform: translateY(-1px);
}
.set-rail .nav-link.active {
	background: var(--sc);
	border-color: var(--sc);
	color: #fff;
	box-shadow: 0 8px 18px var(--sc-mid);
}
.set-rail-ico {
	flex: 0 0 auto;
	width: 30px;
	height: 30px;
	border-radius: 10px;
	background: rgba(255, 255, 255, .72);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
	line-height: 1;
	box-shadow: 0 2px 6px var(--sc-soft);
}
.set-rail .nav-link.active .set-rail-ico { background: rgba(255, 255, 255, .24); }

.set-c-info   { --sc: #6366f1; --sc-soft: rgba(99, 102, 241, .12); --sc-mid: rgba(99, 102, 241, .24); }
.set-c-tg     { --sc: #0ea5e9; --sc-soft: rgba(14, 165, 233, .12); --sc-mid: rgba(14, 165, 233, .24); }
.set-c-pass   { --sc: #8b5cf6; --sc-soft: rgba(139, 92, 246, .12); --sc-mid: rgba(139, 92, 246, .24); }
.set-c-mail   { --sc: #f59e0b; --sc-soft: rgba(245, 158, 11, .13); --sc-mid: rgba(245, 158, 11, .26); }
.set-c-2fa    { --sc: #10b981; --sc-soft: rgba(16, 185, 129, .12); --sc-mid: rgba(16, 185, 129, .24); }
.set-c-notif  { --sc: #ec4899; --sc-soft: rgba(236, 72, 153, .12); --sc-mid: rgba(236, 72, 153, .24); }
.set-c-danger { --sc: #f43f5e; --sc-soft: rgba(244, 63, 94, .12); --sc-mid: rgba(244, 63, 94, .24); }

/* ---------- cards ---------- */
.set-card {
	--sc: #6366f1;
	--sc-soft: rgba(99, 102, 241, .12);
	position: relative;
	border-radius: 18px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .09);
	overflow: hidden;
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
}
.set-card::before {
	content: "";
	position: absolute;
	top: 0;
	inset-inline: 0;
	height: 4px;
	background: var(--sc);
}
.set-card-head {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 18px 20px 14px;
}
.set-card-ico {
	flex: 0 0 auto;
	width: 40px;
	height: 40px;
	border-radius: 13px;
	background: var(--sc-soft);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
	line-height: 1;
}
.set-card-title {
	font-size: 15.5px;
	font-weight: 800;
	color: #16203d;
	margin: 0;
	display: flex;
	align-items: center;
	gap: 8px;
	flex-wrap: wrap;
}
.set-card-sub {
	font-size: 11.5px;
	font-weight: 600;
	color: #8c98ab;
	margin: 2px 0 0;
}
.set-card-body { padding: 4px 20px 20px; }

/* ---------- fields ---------- */
.set-field { margin-bottom: 15px; }
.set-field:last-child { margin-bottom: 0; }
.set-label {
	display: block;
	font-size: 12px;
	font-weight: 700;
	color: #56617a;
	margin-bottom: 6px;
}
.set-wrap .form-control,
.set-input {
	width: 100%;
	border: 1.5px solid rgba(23, 32, 61, .12) !important;
	border-radius: 13px !important;
	padding: 10px 13px !important;
	font-size: 13px;
	font-weight: 600;
	color: #16203d;
	background: #fff !important;
	outline: none;
	box-shadow: none !important;
	transition: border-color .15s ease, box-shadow .15s ease;
}
.set-wrap .form-control:focus,
.set-input:focus {
	border-color: var(--set) !important;
	box-shadow: 0 0 0 4px var(--sc-soft, rgba(99, 102, 241, .13)) !important;
}
.set-hint {
	display: block;
	font-size: 11px;
	font-weight: 600;
	color: #9aa4b6;
	margin-top: 5px;
}
.set-current {
	font-size: 12.5px;
	font-weight: 600;
	color: #56617a;
	margin: 0 0 14px;
}
.set-current b { color: #16203d; direction: ltr; unicode-bidi: isolate; }

/* input + button on one line (email code) */
.set-inline { display: flex; gap: 8px; flex-wrap: wrap; }
.set-inline .form-control,
.set-inline .set-input { flex: 1 1 160px; min-width: 0; }

/* ---------- buttons ---------- */
.set-actions {
	display: flex;
	justify-content: flex-end;
	gap: 10px;
	margin-top: 18px;
}
.set-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 7px;
	min-height: 40px;
	padding: 9px 18px;
	border: 0;
	border-radius: 13px;
	font-size: 12.5px;
	font-weight: 800;
	cursor: pointer;
	white-space: nowrap;
	transition: transform .14s ease, box-shadow .14s ease, background .14s ease;
}
.set-btn:active { transform: scale(.97); }
.set-btn-primary {
	color: #fff;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 6px 16px rgba(99, 102, 241, .32);
}
.set-btn-primary:hover { box-shadow: 0 9px 22px rgba(99, 102, 241, .44); color: #fff; }
.set-btn-danger {
	color: #fff;
	background: linear-gradient(135deg, #e11d48, #db2777);
	box-shadow: 0 6px 16px rgba(225, 29, 72, .3);
}
.set-btn-danger:hover { box-shadow: 0 9px 22px rgba(225, 29, 72, .42); color: #fff; }
.set-btn-ghost {
	color: #4f46e5;
	background: rgba(99, 102, 241, .12);
	border: 1.5px solid rgba(99, 102, 241, .32);
}
.set-btn-ghost:hover { background: rgba(99, 102, 241, .2); color: #4f46e5; }
.set-btn[disabled] { opacity: .55; cursor: not-allowed; }

/* ---------- badges ---------- */
.set-badge {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 10.5px;
	font-weight: 800;
	padding: 3px 10px;
	border-radius: 999px;
}
.set-badge-on  { color: #047857; background: rgba(16, 185, 129, .14); }
.set-badge-off { color: #b91c1c; background: rgba(239, 68, 68, .13); }

/* ---------- profile card ---------- */
.set-profile {
	position: relative;
	border-radius: 18px;
	background: #fff;
	border: 1.5px solid rgba(23, 32, 61, .09);
	overflow: hidden;
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
	text-align: center;
}
.set-profile-cover {
	position: relative;
	height: 120px;
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #db2777);
}
.set-profile-cover img {
	width: 100%;
	height: 100%;
	object-fit: cover;
	opacity: .35;
	mix-blend-mode: overlay;
}
.set-profile-cover .js-file-attach { position: absolute; inset: 0; opacity: 0; cursor: pointer; }
.set-profile-avatar {
	display: block;
	width: 92px;
	height: 92px;
	margin: -46px auto 0;
	border-radius: 50%;
	border: 4px solid #fff;
	background: #fff;
	overflow: hidden;
	box-shadow: 0 8px 22px rgba(23, 32, 61, .22);
	cursor: pointer;
}
.set-profile-avatar img { width: 100%; height: 100%; object-fit: cover; display: block; }
.set-profile-name {
	font-size: 17px;
	font-weight: 800;
	color: #16203d;
	margin: 12px 0 4px;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
}
.set-profile-meta {
	font-size: 11.5px;
	font-weight: 600;
	color: #8c98ab;
	margin: 0 0 18px;
	display: inline-flex;
	align-items: center;
	gap: 6px;
}

/* ---------- notifications ---------- */
.set-note-intro {
	font-size: 12px;
	font-weight: 600;
	color: #56617a;
	background: rgba(236, 72, 153, .08);
	border: 1px solid rgba(236, 72, 153, .18);
	border-radius: 12px;
	padding: 11px 14px;
	margin-bottom: 14px;
}
.set-toggle-row {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12px;
	padding: 12px 14px;
	border: 1.5px solid rgba(23, 32, 61, .09);
	border-radius: 14px;
	margin-bottom: 9px;
}
.set-toggle-row:last-of-type { margin-bottom: 0; }
.set-toggle-label {
	font-size: 12.5px;
	font-weight: 700;
	color: #16203d;
	display: flex;
	align-items: center;
	gap: 9px;
}
.set-toggle-emoji { font-size: 16px; line-height: 1; }
.set-wrap .form-check-input {
	width: 42px;
	height: 24px;
	margin: 0;
	cursor: pointer;
	background-color: rgba(23, 32, 61, .16);
	border: 0;
	box-shadow: none !important;
}
.set-wrap .form-check-input:checked {
	background-color: var(--set);
}
.set-wrap .set-toggle-row .form-check { padding: 0; margin: 0; min-height: 0; }

/* ---------- 2FA modal ---------- */
.set-2fa-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 22px;
}
.set-2fa-qr {
	text-align: center;
	padding: 14px;
	background: #fff;
	border-radius: 14px;
	box-shadow: inset 0 0 0 1.5px rgba(23, 32, 61, .1);
}
.set-2fa-qr img { max-width: 100%; height: auto; }
.set-2fa-secret {
	display: block;
	font-family: monospace;
	font-size: 13px;
	font-weight: 700;
	color: #e11d48;
	word-break: break-all;
	direction: ltr;
	margin-bottom: 10px;
}
.set-2fa-store { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin: 10px 0 16px; }
.set-2fa-store img { width: 148px; }

/* ---------- dark ---------- */
html[data-hs-theme="dark"] .set-rail {
	background: linear-gradient(180deg, rgba(28, 37, 54, .97), rgba(22, 30, 46, .98));
	border-color: rgba(255, 255, 255, .09);
	box-shadow: 0 12px 30px rgba(0, 0, 0, .4);
}
html[data-hs-theme="dark"] .set-rail-title { color: rgba(255, 255, 255, .42); }
html[data-hs-theme="dark"] .set-rail .nav-link { color: #e7eaf3; }
html[data-hs-theme="dark"] .set-rail .nav-link.active { color: #fff; }
html[data-hs-theme="dark"] .set-rail-ico { background: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .set-rail .nav-link.active .set-rail-ico { background: rgba(255, 255, 255, .22); }

html[data-hs-theme="dark"] .set-card,
html[data-hs-theme="dark"] .set-profile {
	background: #1c2536;
	border-color: rgba(255, 255, 255, .09);
	box-shadow: 0 10px 26px rgba(0, 0, 0, .4);
}
html[data-hs-theme="dark"] .set-card-title,
html[data-hs-theme="dark"] .set-profile-name,
html[data-hs-theme="dark"] .set-toggle-label,
html[data-hs-theme="dark"] .set-current b { color: #e7eaf3; }
html[data-hs-theme="dark"] .set-card-sub,
html[data-hs-theme="dark"] .set-profile-meta,
html[data-hs-theme="dark"] .set-label,
html[data-hs-theme="dark"] .set-current,
html[data-hs-theme="dark"] .set-note-intro { color: #b9c2d4; }
html[data-hs-theme="dark"] .set-wrap .form-control,
html[data-hs-theme="dark"] .set-input {
	background: rgba(255, 255, 255, .06) !important;
	border-color: rgba(255, 255, 255, .12) !important;
	color: #e7eaf3;
}
html[data-hs-theme="dark"] .set-toggle-row { border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .set-profile-avatar { border-color: #1c2536; background: #1c2536; }
html[data-hs-theme="dark"] .set-badge-on  { color: #6ee7b7; background: rgba(16, 185, 129, .18); }
html[data-hs-theme="dark"] .set-badge-off { color: #fca5a5; background: rgba(239, 68, 68, .18); }
html[data-hs-theme="dark"] .set-2fa-qr { background: #fff; }
html[data-hs-theme="dark"] .set-note-intro { background: rgba(236, 72, 153, .12); border-color: rgba(236, 72, 153, .24); }

/* ---------- small screens ---------- */
@media (max-width: 991.98px) {
	.set-rail { position: static; margin-bottom: 18px; }
	.set-rail .nav { display: flex; flex-wrap: wrap; gap: 6px; }
	.set-rail .nav-item { flex: 1 1 auto; }
	.set-rail .nav-link { margin: 0; justify-content: center; }
	.set-rail-title { width: 100%; }
}
@media (max-width: 575.98px) {
	.set-hero { padding: 18px; }
	.set-hero h1 { font-size: 18px; }
	.set-card-body { padding: 4px 15px 16px; }
	.set-actions .set-btn { flex: 1 1 100%; }
	.set-2fa-grid { grid-template-columns: 1fr; gap: 16px; }
}
</style>
{/literal}

<div class="set-wrap">

	<div class="page-header set-hero">
		<h1>🛠️ {$translate->get('AccSettings')}</h1>
		<p>{$translate->get('SettingsSubtitle')}</p>
	</div>

	<div class="row">
		<div class="col-lg-3">
			<div class="set-rail">
				<div class="set-rail-title">{$translate->get('AccSettings')}</div>
				<ul id="navbarSettings" class="js-scrollspy nav">
					<li class="nav-item">
						<a class="nav-link set-c-info active" href="#content">
							<span class="set-rail-ico">👤</span>{$translate->get('BasicInfo')}
						</a>
					</li>
					{if $Config['telegram'] == 1 && $Config['telegrambind'] == 1 && $Config['telegrambot'] != ""}
					<li class="nav-item">
						<a class="nav-link set-c-tg" href="#telegramSection" data-scroll="telegramSection">
							<span class="set-rail-ico">✈️</span>Telegram
						</a>
					</li>
					{/if}
					<li class="nav-item">
						<a class="nav-link set-c-pass" href="#passwordSection" data-scroll="passwordSection">
							<span class="set-rail-ico">🔑</span>{$translate->get('AccPassword')}
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link set-c-mail" href="#emailSection" data-scroll="emailSection">
							<span class="set-rail-ico">✉️</span>{$translate->get('AccEmail')}
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link set-c-2fa" href="#twoStepVerificationSection" data-scroll="twoStepVerificationSection">
							<span class="set-rail-ico">🛡️</span>{$translate->get('TwoStep')}
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link set-c-notif" href="#notificationsSection" data-scroll="notificationsSection">
							<span class="set-rail-ico">🔔</span>{$translate->get('Notifications')}
						</a>
					</li>
					<li class="nav-item">
						<a class="nav-link set-c-danger" href="#deleteAccountSection" data-scroll="deleteAccountSection">
							<span class="set-rail-ico">🗑️</span>{$translate->get('DeleteAcc')}
						</a>
					</li>
				</ul>
			</div>
		</div>

		<div class="col-lg-9">
			<div class="d-grid gap-3 gap-lg-4 mb-5">
				{include file='user/settings/info.tpl'}
				{include file='user/settings/telegram.tpl'}
				{include file='user/settings/password.tpl'}
				{include file='user/settings/email.tpl'}
				{include file='user/settings/verification.tpl'}
				{include file='user/settings/notifications.tpl'}
				{include file='user/settings/account.tpl'}
			</div>
			<div id="stickyBlockEndPoint"></div>
		</div>
	</div>

</div>

{include file='user/layout/footer.tpl'}
<script>
	layui.use('layer', function(){});

	(function() {
		new bootstrap.ScrollSpy(document.body, {
		  target: '#navbarSettings',
		  offset: 120
		})
	})()


	$('.setNotifications').click(function(e) {
		e.preventDefault();
		if(document.getElementById('Notices').checked){
			var SendNotices = 1;
		}else{
			var SendNotices = 0;
		};
		if(document.getElementById('DataUsed').checked){
			var DataUsed = 1;
		}else{
			var DataUsed = 0;
		};
		if(document.getElementById('DataExpire').checked){
			var DataExpire = 1;
		}else{
			var DataExpire = 0;
		};
		if(document.getElementById('Login').checked){
			var LoginNotify = 1;
		}else{
			var LoginNotify = 0;
		};

		$.ajax({
			type: "POST",
			url: "/portal/settings/notifications",
			dataType: "json",
			data: {
				SendNotices,
				DataUsed,
				DataExpire,
				LoginNotify
			},
			success: data => {
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
					time: 8000,
					offset:  '100px'
				});
			}
		});
	})

	$('.DeleteAccount').click(function(e) {
		e.preventDefault();
		if(!document.getElementById('deleteAccountCheckbox').checked){
			layer.msg("{$translate->get('ConfDeleteAcc')}", {
				time: 5000,
				offset:  '100px'
			});
			return;
		}

		$.ajax({
			type: "POST",
			url: "/portal/settings/deleteacc",
			dataType: "json",
			data: {
				password: $("#login_password").val(),
			},
			success: data => {
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
					time: 8000,
					offset:  '100px'
				});
			}
		});
	})

	var wait = 100;
	function time(o) {
		if (wait == 0) {
			o.removeAttr("disabled");
			o.text("{$translate->get('GetCode')}");
			wait = 100;
		} else {
			o.attr("disabled", "disabled");
			o.text(wait);
			wait--;
			setTimeout(function () {
				time(o)
			},1000)
		}
	}

	$("#email_verify").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/verify",
			dataType: "json",
			data: {
				email: $('#email').val()
			},
			success: data => {
				if (data.ret == 1) {
					time($("#email_verify"));
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
					time: 8000,
					offset:  '100px'
				});
			}
		});
	});

	$(".UpdateEmail").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/updatemail",
			dataType: "json",
			data: {
				email: $('#email').val(){if $Config['maildriver'] == 1 },
				code: $('#code').val(){/if}
			},
			success: data => {
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/portal/settings'", 2000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		})
	})

	$(".updatePassword").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/updatepass",
			dataType: "json",
			data: {
				password: $("#currentpassword").val(),
				newpassword: $("#newpassword").val(),
				confirmpassword: $("#confirmnewpassword").val()
			},
			success: data => {
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/'", 1000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		})
	})

	$(".confirmpasswd").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/confirmpasswd",
			dataType: "json",
			data: {
				password: $("#confirmpasswd").val(),
			},
			success: data => {
				if (data.ret == 1) {
					$('#_auth').modal('show');
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 800,
					offset:  '100px'
				});
			}
		})
	})

	$(".gaSet").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/enablega",
			dataType: "json",
			data: {
				code : $('#ga_code').val(),
				status: {if $user->ga_status == 0}1{else}0{/if}
			},
			success: data => {
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/portal/settings'", 2000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		})
	})

	$(".gaReset").click(function (e) {
		e.preventDefault();
		$.ajax({
			type: "POST",
			url: "/portal/settings/resetga",
			dataType: "json",
			data: {},
			success: data => {
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/portal/settings'", 2000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		})
	})

	$(".unbind").click(function (e) {
		e.preventDefault();
		Swal.fire({
			title: "{$translate->get('ConfirmResetTG')}",
			html: "{$translate->get('ConfirmResetTGN')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('UnlinkTG')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-dark ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				ConfirmResetTG();
			}
		});
	});

	function ConfirmResetTG(){
		$.ajax({
			type: "POST",
			url: "/portal/settings/reset_tg",
			dataType: "json",
			data: {},
			success: data => {
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/portal/settings'", 1500);
				} else {
					layer.msg(data.msg, {
						time: 8000,
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
