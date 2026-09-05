<script>localStorage.setItem('toggleID', ''); </script>	
{include file='admin/layout/header.tpl'} 
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('Settings')}</h1>
			</div>
        </div>
    </div>

      <div class="row">
        <div class="col-lg-3">
          <div class="navbar-expand-lg navbar-vertical mb-3 mb-lg-5">
            <div class="d-grid shadow-lg rounded">
              <button type="button" class="navbar-toggler btn btn-white mb-3" data-bs-toggle="collapse" data-bs-target="#navbarVerticalNavMenu" aria-label="Toggle navigation" aria-expanded="false" aria-controls="navbarVerticalNavMenu">
                <span class="d-flex justify-content-between align-items-center">
                  <span class="text-dark">{$translate->get('Settings')}</span>

                  <span class="navbar-toggler-default">
                    <i class="bi-list"></i>
                  </span>

                  <span class="navbar-toggler-toggled">
                    <i class="bi-x"></i>
                  </span>
                </span>
              </button>
            </div>
  
            <div id="navbarVerticalNavMenu" class="collapse navbar-collapse shadow-lg rounded">
              <ul id="navbarSettings" class="js-sticky-block js-scrollspy card card-navbar-nav nav nav-tabs nav-lg nav-vertical" 
			  data-hs-sticky-block-options='{
                     "parentSelector": "#navbarVerticalNavMenu",
                     "targetSelector": "#header",
                     "breakpoint": "lg",
                     "startPoint": "#navbarVerticalNavMenu",
                     "endPoint": "#stickyBlockEndPoint",
                     "stickyOffsetTop": 20
                   }'>
                <li class="nav-item">
                  <a class="nav-link active" href="#BasicSettings">
                    <i class="fa-duotone fa-user nav-icon"></i> {$translate->get('BasicSettings')}
                  </a>
                </li>
                
                <li class="nav-item">
                  <a class="nav-link" href="#GeneralSettings" data-scroll="GeneralSettings">
                    <i class="fa-solid fa-gear nav-icon"></i> {$translate->get('GeneralSettings')}
                  </a>
                </li>
				<li class="nav-item">
                  <a class="nav-link" href="#RegisterSettings" data-scroll="RegisterSettings">
                    <i class="fa-solid fa-user-plus nav-icon"></i> {$translate->get('RegisterSettings')}
                  </a>
                </li>
				<li class="nav-item">
                  <a class="nav-link" href="#MailSettings" data-scroll="MailSettings">
                    <i class="fa-solid fa-envelope nav-icon"></i> {$translate->get('MailSettings')}
                  </a>
                </li>
                <li class="nav-item">
                  <a class="nav-link" href="#TelegramSettings" data-scroll="TelegramSettings">
                    <i class="fa-brands fa-telegram nav-icon"></i> {$translate->get('TelegramSettings')}
                  </a>
                </li>
				<li class="nav-item">
                  <a class="nav-link" href="#CheckInSettings" data-scroll="CheckInSettings">
                    <i class="fa-solid fa-award nav-icon"></i> {$translate->get('CheckInSettings')}
                  </a>
                </li>
                <li class="nav-item">
                  <a class="nav-link" href="#APISettings"  data-scroll="APISettings">
                    <i class="fa-solid fa-screwdriver-wrench nav-icon"></i> {$translate->get('APISettings')}
                  </a>
                </li>

                <li class="nav-item">
                  <a class="nav-link" href="#NotificationSettings"  data-scroll="NotificationSettings">
                     <i class="fa-solid fa-bell nav-icon"></i> {$translate->get('NoticeSettings')}
                  </a>
                </li>
				
				<li class="nav-item">
                  <a class="nav-link" href="#ChatSettings"  data-scroll="ChatSettings">
                     <i class="fa-solid fa-messages nav-icon"></i> {$translate->get('ChatSettings')}
                  </a>
                </li>
				
				<li class="nav-item">
                  <a class="nav-link" href="#BackupSettings"  data-scroll="BackupSettings">
                    <i class="fa-solid fa-box-archive nav-icon"></i> {$translate->get('BackupSettings')}
                  </a>
                </li>
				
				<li class="nav-item">
                  <a class="nav-link" href="#CaptchaSettings"  data-scroll="CaptchaSettings">
                     <i class="fa-solid fa-badge-check nav-icon"></i> {$translate->get('CaptchaSettings')}
                  </a>
                </li>
				
				<li class="nav-item">
                  <a class="nav-link" href="#RestrictSettings"  data-scroll="RestrictSettings">
                     <i class="fa-solid fa-universal-access nav-icon"></i> {$translate->get('RestrictSettings')}
                  </a>
                </li>
				
				<li class="nav-item">
                  <a class="nav-link" href="#PatchSettings"  data-scroll="PatchSettings">
                     <i class="fa-solid fa-bandage nav-icon"></i> {$translate->get('PatchSettings')}
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div class="col-lg-9">
          <div class="d-grid gap-3 gap-lg-5 mb-5">
		    {include file='admin/settings/basicsettings.tpl'}
			{include file='admin/settings/generalsettings.tpl'}
			{include file='admin/settings/registersettings.tpl'}
			{include file='admin/settings/mailsettings.tpl'}
			{include file='admin/settings/telegramsettings.tpl'}
			{include file='admin/settings/checkinsettings.tpl'}
		    {include file='admin/settings/apisettings.tpl'}
			{include file='admin/settings/notificationsettings.tpl'}
			{include file='admin/settings/chatsettings.tpl'}
			{include file='admin/settings/backupsettings.tpl'}
			{include file='admin/settings/captchasettings.tpl'}
			{include file='admin/settings/restrictsettings.tpl'} 
			{include file='admin/settings/patchsettings.tpl'}
          </div>
          <div id="stickyBlockEndPoint"></div>
        </div>
		
      </div>
{include file='admin/layout/footer.tpl'}
<script>
    (function() {

        new HSStickyBlock('.js-sticky-block', {
          targetSelector: document.getElementById('header').classList.contains('navbar-fixed') ? '#header' : null
        })

        new bootstrap.ScrollSpy(document.body, {
          target: '#navbarSettings',
          offset: 100
        })
		
		new HSScrollspy('#navbarVerticalNavMenu', {
		  breakpoint: 'lg',
		  scrollOffset: -20
		})
    })()


	function Basic(){
		if ($("#default_currency").val() == "{$Config['default_currency']}"){	
			saveBasic();
		}else{
			Swal.fire({
				title: '',
				html:  "{$translate->get('UpdateCurrency')}",
				icon: 'warning',
				showCancelButton: true,
				showConfirmButton:true,
				confirmButtonText: '{$translate->get('Continue')}',
				cancelButtonText: '{$translate->get('Cancel')}',
				allowOutsideClick: false,
				width: '500px',
				height: '250px',
				padding: '1em',
				customClass: {
					confirmButton: 'btn btn-sm btn-secondary ms-1',
					cancelButton: 'btn btn-sm  btn-danger ms-1'
				},
				buttonsStyling: false
			}).then(function (result) {
				if (result.isConfirmed) {
					saveBasic();
				}	
			});
		}	
	}

	function saveBasic(){
		if (document.getElementById('loginbind').checked) {
			var loginbind = 1;
		} else {
			var loginbind = 0;
		}

		if (document.getElementById('loginverify').checked) {
			var loginverify = 1;
		} else {
			var loginverify = 0;
		}

		if (document.getElementById('maintenance').checked) {
			var maintenance = 1;
		} else {
			var maintenance = 0;
		}	
		
		if (document.getElementById('allow_coupon_use').checked) {
			var allow_coupon_use = 1;
		} else {
			var allow_coupon_use = 0;
		}

		if (document.getElementById('language_selector').checked) {
			var language_selector = 1;
		} else {
			var language_selector = 0;
		}
		
		if (document.getElementById('verify').checked) {
			var verify = 1;
		} else {
			var verify = 0;
		}
		
		if (document.getElementById('disconnect_unverified').checked) {
			var disconnect_unverified = 1;
		} else {
			var disconnect_unverified = 0;
		}
		
		if (document.getElementById('disable_trafficlog').checked) {
			var disable_trafficlog = 1;
		} else {
			var disable_trafficlog = 0;
		}
		
		var languages = $.trim($("#languages").val());
		
		var rtlanguages = $.trim($("#rtlanguages").val());
		
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/basic",
			 dataType: "json",
			 data: {
				maintenance_note:  $('#maintenance_note').val(),
				ticket_signature: $('#ticket_signature').val(),
				ideal_logout_seconds:$('#ideal_logout_seconds').val(),
				language_selector:language_selector,
				verify : verify,
				disconnect_unverified:disconnect_unverified,
				allow_coupon_use:allow_coupon_use,
				loginbind:loginbind,
				loginverify:loginverify,
				disable_trafficlog,
				maintenance,
				default_currency: $('#default_currency').val(),
				languages: languages,
				rtlanguages: rtlanguages,
				sameGroup: $('#sameGroup').val(),
				licenseKey: $('#licenseKey').val(),
				accounts: $('#accounts').val(),
				latest_notice: $('#latest_notice').val(),
				exchange_rate:$('#exchange_rate').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}

	function saveCheckin(){
		layer.load(2);
		var CheckInGroup = $.trim($("#CheckInGroup").val());
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/checkin",
			 dataType: "json",
			 data: {
				
				CheckIn: $('#CheckIn').val(),
				checkinDataMin: $('#checkinDataMin').val(),
				checkinDataMax: $('#checkinDataMax').val(),
				checkinType: $('#checkinType').val(),
				checkinDaysMax: $('#checkinDaysMax').val(),
				checkinDaysMin: $('#checkinDaysMin').val(),
				CheckInGroup:CheckInGroup,
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}
	
	function saveGeneral(){
		if ($("#salt").val() != "{$Config['salt']}"){
			Swal.fire({
				title: '',
				html:  "{$translate->get('SaltChange')}",
				icon: 'warning',
				showCancelButton: true,
				showConfirmButton:true,
				confirmButtonText: '{$translate->get('Continue')}',
				cancelButtonText: '{$translate->get('Cancel')}',
				allowOutsideClick: false,
				width: '500px',
				height: '250px',
				padding: '1em',
				customClass: {
					confirmButton: 'btn btn-sm btn-secondary ms-1',
					cancelButton: 'btn btn-sm  btn-danger ms-1'
				},
				buttonsStyling: false
			}).then(function (result) {
				if (result.isConfirmed) {
					General();
				}	
			});
		}else
		if ($("#algo").val() != "{$Config['algo']}"){
			Swal.fire({
				title: '',
				html:  "{$translate->get('HashingChange')}",
				icon: 'warning',
				showCancelButton: true,
				showConfirmButton:true,
				confirmButtonText: '{$translate->get('Continue')}',
				cancelButtonText: '{$translate->get('Cancel')}',
				allowOutsideClick: false,
				width: '500px',
				height: '250px',
				padding: '1em',
				customClass: {
					confirmButton: 'btn btn-sm btn-secondary ms-1',
					cancelButton: 'btn btn-sm  btn-danger ms-1'
				},
				buttonsStyling: false
			}).then(function (result) {
				if (result.isConfirmed) {
					General();
				}	
			});
		}else{
			General();
		}	
	}
	
	function General(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/general",
			 dataType: "json",
			 data: {
				appName: $('#appName').val(),
				SubName: $('#SubName').val(),
				logo_path: $('#logo_path').val(),
				darkthemelogo: $('#darkthemelogo').val(),
				lightthemelogo: $('#lightthemelogo').val(),
				algo: $('#algo').val(),
				passwordmode: $('#passwordmode').val(),
				salt:  $('#salt').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
	
	function saveRegister(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/register",
			 dataType: "json",
			 data: {
				enable_register: $('#enable_register').val(),
				invitation_only: $('#invitation_only').val(),
				enable_restrict_email_list: $('#enable_restrict_email_list').val(),
				restrict_email_list: $('#restrict_email_list').val(),
				default_expire: $('#default_expire').val(),
				default_traffic: $('#default_traffic').val(),
				default_level: $('#default_level').val(),
				default_group: $('#default_group').val(),
				default_speedlimit: $('#default_speedlimit').val(),
				default_connector: $('#default_connector').val(),
				SendNotices: $('#SendNotices').val(),
				DataUsed: $('#DataUsed').val(),
				DataExpire: $('#DataExpire').val(),
				LoginNotify: $('#LoginNotify').val(),
				SameServerGroup:  $('#SameServerGroup').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
	
	function saveMail(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/mail",
			 dataType: "json",
			 data: {
				maildriver: $('#maildriver').val(),
				enablestmpssl: $('#enablestmpssl').val(),
				smtphost: $('#smtphost').val(),
				smtpport: $('#smtpport').val(),
				smtpusername: $('#smtpusername').val(),
				smtppassword: $('#smtppassword').val(),
				smtpsender: $('#smtpsender').val(),
				smtpsendername: $('#smtpsendername').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
	
	function saveTelegram(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/telegram",
			 dataType: "json",
			 data: {
				telegram: $('#telegram').val(),
				telegrambind:$('#telegrambind').val(),
				telegramchatid: $('#telegramchatid').val(),
				telegrambot: $('#telegrambot').val(),
				telegramtoken: $('#telegramtoken').val(),
				telegramgroupid:  $('#telegramgroupid').val(),
				tgnewMemberBan: $('#tgnewMemberBan').val(),
				telegram_url: $('#telegram_url').val(),
				tg_grouplink: $('#tg_grouplink').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
	
	function saveAPI(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/api",
			 dataType: "json",
			 data: {
				webapikey: $('#webapikey').val(),
				enablewebapi: $('#enablewebapi').val(),
				enableclientapi: $('#enableclientapi').val()
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
	
	function generate(){
		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/admin/settings/generateapi",
			dataType: "json",
			data: {},
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) { 
					$('#webapikey').val(data.code);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			}
		});	
	}

	function saveNotification(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/notification",
			 dataType: "json",
			 data: {
				enablenotifications: $('#enablenotifications').val(),
				enableinvoice: $('#enableinvoice').val(),
				dataexpirenotify: $('#dataexpirenotify').val(),
				dataexpirewarn: $('#dataexpirewarn').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}

	function saveChat(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/chat",
			 dataType: "json",
			 data: {
				tawkid: $('#tawkid').val(),
				tawkapi: $('#tawkapi').val(),
				crispid: $('#crispid').val(),
				chatdriver: $('#chatdriver').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}

	function saveBackUp(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/backup",
			 dataType: "json",
			 data: {
			    backup: $('#backup').val(),
				backuppass: $('#backuppass').val(),
				backupemail: $('#backupemail').val(),
				backtoemail: $('#backtoemail').val(),
				backtotelegram: $('#backtotelegram').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}
	
	function saveCaptcha(){
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/captcha",
			 dataType: "json",
			 data: {
				enable_captcha: $('#enable_captcha').val(),
				hcaptcha_key : $('#hcaptcha_key').val(),
				hcaptcha_secrete : $('#hcaptcha_secrete').val(),
				turnstile_key : $('#turnstile_key').val(),
				turnstile_secrete : $('#turnstile_secrete').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret == 1) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	

	$("#denyaccess").click(function () {
	   if (document.getElementById('denyaccess').checked) {
		  document.getElementById('allowaccess').checked = false;
		  document.getElementById('denyaccess').checked = true;
	   } else {
		  document.getElementById('denyaccess').checked = false;
	   }
	});
	$("#allowaccess").click(function () {
	   if (document.getElementById('allowaccess').checked) {
		  document.getElementById('denyaccess').checked = false;
		  document.getElementById('allowaccess').checked = true;
	   } else {
		  document.getElementById('allowaccess').checked = false;
	   }
	});
	
	function saveAccess(){
		if (document.getElementById('denyaccess').checked) {
			var denyaccess = 1;
		} else {
			var denyaccess = 0;
		}
		if (document.getElementById('allowaccess').checked) {
			var allowaccess = 1;
		} else {
			var allowaccess = 0;
		}
		var country = $.trim($("#country").val());
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/access",
			 dataType: "json",
			 data: {
				country: country,
				denyaccess: denyaccess,
				allowaccess: allowaccess,
				accessrestriction: $('#accessrestriction').val(),
				access_restriction_ip_list: $('#access_restriction_ip_list').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}
	
	function saveTask(){
		var token_enabled = (document.getElementById('token_enabled').checked == true ? 1 : 0);
		var server_enabled = (document.getElementById('server_enabled').checked == true ? 1 : 0);
		var datareset_enabled = (document.getElementById('datareset_enabled').checked == true ? 1 : 0);
		var clearlogs_enabled = (document.getElementById('clearlogs_enabled').checked == true ? 1 : 0);
		var backup_enabled = (document.getElementById('backup_enabled').checked == true ? 1 : 0);
		var userstatus_enabled = (document.getElementById('userstatus_enabled').checked == true ? 1 : 0);
		var queue_enabled = (document.getElementById('queue_enabled').checked == true ? 1 : 0);
		var update_enabled = (document.getElementById('update_enabled').checked == true ? 1 : 0);
	
		layer.load(2);
		$.ajax({
			 type: "POST",
			 url: "/admin/settings/task",
			 dataType: "json",
			 data: {
				token_enabled,
				server_enabled,
				datareset_enabled,
				clearlogs_enabled,
				backup_enabled,
				queue_enabled,
				userstatus_enabled,
				update_enabled,
				token_schedule: $('#token_schedule').val(),
				server_schedule: $('#server_schedule').val(),
				datareset_schedule: $('#datareset_schedule').val(),
				clearlogs_schedule: $('#clearlogs_schedule').val(),
				backup_schedule: $('#backup_schedule').val(),
				userstatus_schedule: $('#userstatus_schedule').val(),
				queue_schedule: $('#queue_schedule').val(),
				update_schedule: $('#update_schedule').val(),
			 },
			 success: data => {
				layer.closeAll('loading');
				if (data.ret) {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				} else {
				   layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			 },
			 error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			 }
		});
	}	
</script> 
