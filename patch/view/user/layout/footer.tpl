         <div class="modal fade" id="lock-screen" tabindex="-1" role="dialog" aria-labelledby="lockModalCenterTitle" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
            <div class="modal-dialog modal-dialog-centered" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h6 class="modal-title">{$translate->get('Warning')}</h6><button aria-label="Close" class="btn-close"
                            data-bs-dismiss="modal" type="button"><span aria-hidden="true">×</span></button>
                    </div>
                    <div class="modal-body">
                        <div class="text-center">
							{$translate->get('idealNotice')}
						</div>
                    </div>
                </div>
            </div>
        </div>	
	</div> 
	
	<style>	
	.list-separator .list-inline-item {
		position: relative;
		margin-left: 0;
		margin-right: -.25rem
	}

	.list-separator .list-inline-item:not(:last-child) {
		padding-right: 2rem
	}

	.list-separator .list-inline-item:not(:last-child)::after {
		position: absolute;
		top: 50%;
		right: .8rem;
		-webkit-transform: translateY(-50%);
		transform: translateY(-50%);
		content: "/";
		opacity: .4
	}
	</style>
    <div class="footer text-center" dir='ltr'>
		<div class="col">
          <p class="fs-6 mb-0"><script type="text/javascript">document.write(new Date().getFullYear());</script> &copy; {$Config['appName']}</p>
        </div>
		<ul class="list-inline list-separator">
			<li class="list-inline-item">
			  <a class="list-separator-link" href="/privacy" target="_blank">{$translate->get('PrivacyPolicy')}</a>
			</li>

			<li class="list-inline-item">
			  <a class="list-separator-link" href="/terms" target="_blank">{$translate->get('TermsofService')}</a>
			</li>
		</ul>
    </div>	
  </main>
   <style>
  .go-to:focus:hover,.go-to:hover{
	color: #fff;
	background-color: var(--bs-gray-900);
	opacity:1
  }
  </style>
  <a class="js-go-to go-to position-fixed" href="javascript:;" style="visibility: hidden;"  data-hs-go-to-options='{
       "offsetTop": 700,
       "position": {
         "init": {
           "right": "2rem"
         },
         "show": {
           "bottom": "2rem"
         },
         "hide": {
           "bottom": "-2rem"
         }
       }
     }'>
    <i class="bi-chevron-up"></i>
  </a>
  <script src="/assets/js/vendor.min.js"></script>
  <script src="/assets/js/theme.min.js"></script>
  <script src="/assets/js/clipboard.js"></script>
  <script src="/assets/plugins/layui/layui.js"></script>
  <script src="/assets/plugins/table/jquery.dataTables.min.js"></script>
  <script src="/assets/plugins/table/dataTables.bootstrap5.min.js"></script>
  <script src="/assets/js/Chart.bundle.js"></script>
  <script src="/assets/js/sweetalert2.all.min.js"></script>
  <script>
	function WeChat() {
		var ua = window.navigator.userAgent.toLowerCase();
		return ua.match(/MicroMessenger/i) == 'micromessenger';
	}
	
	if(WeChat()){
		$('body').html('<h5 style="margin:20px">{$translate->get("alert")}</h5>');
	}
	
	layui.use('layer', function(){});
  
	// copying is handled by common/copy.tpl, which works on browsers where
	// ClipboardJS could not fire at all (the fields it targeted are disabled)
	window.CopyText = new Object();
	window.CopyText.message = "{$translate->get('copied')}";
	window.CopyText.manual  = "{$translate->get('CopyManual')}";
	
	function switchLang(lang){
		$.ajax({
			type: "POST",
			url: "/language",
			dataType: "json",
			data: {
				lang: lang,
			},
			success: (data) => {
				if(data.ret){ 
					location.reload();
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});	
	}	
 </script>
  <script>
    (function() {
      window.onload = function () {
        new HSGoTo('.js-go-to')
        new HSSideNav('.js-navbar-vertical-aside').init()
        HSBsDropdown.init()
        HSCore.components.HSTomSelect.init('.js-select')
      }
    })()
  </script>

  <script>
    $('.theme-mode').on("click", function(e) {
	    if(HSThemeAppearance.getAppearance() == 'dark'){
			HSThemeAppearance.setAppearance('default');
		}else{
			HSThemeAppearance.setAppearance('dark');
		}
    })
  </script>
  <script>
      (function () {
        const $dropdownBtn = document.getElementById('selectLanguageDropdown') 
        const $var = document.querySelectorAll(`[aria-labelledby="selectLanguageDropdown"] [data-lang]`)
        const setActiveLang = function () {
          $var.forEach($item => {
		    {assign var=lang value="_"|explode:$session->get('locale')}
			if ($item.getAttribute('data-lang') === "{$lang[1]|lower|escape}") {
			  $dropdownBtn.innerHTML = '<img style="margin-left:7px;font-size:18px" class="avatar avatar-xss avatar-circle me-2" src="/assets/vendor/flag-icon-css/flags/1x1/'+ $item.getAttribute('data-lang') + '.svg">'
              return $item.classList.add('active')
            }
            $item.classList.remove('active')
          })
        }
        setActiveLang()
      })()
    </script>	
</body>
</html>
{include file='chat/crisp.tpl'}
{include file='chat/tawk.tpl'}
{if $Config['ideal_logout_seconds'] > 0}
<script type="text/javascript">
    var IdealTimeOut = {$Config['ideal_logout_seconds']};
    var idleSecondsTimer = null;
    var idleSecondsCounter = 0;
    
	document.onclick = function () { 
		if($('#lock-screen').hasClass('show')){
			$('#lock-screen').modal('hide');
		}
		idleSecondsCounter = 0; 
	};
	
    document.onmousemove = function () {
		if($('#lock-screen').hasClass('show')){
			$('#lock-screen').modal('hide');
		}
		idleSecondsCounter = 0; 
	};
	
    document.onkeypress = function () { 
		if($('#lock-screen').hasClass('show')){
			$('#lock-screen').modal('hide');
		}
		idleSecondsCounter = 0; 
	};
	
    idleSecondsTimer = window.setInterval(CheckIdleTime, 1000);
 
    function CheckIdleTime() {
        idleSecondsCounter++;
        var oPanel = document.getElementById("ideal-timeout");
        if (oPanel) {
            oPanel.innerHTML = (IdealTimeOut - idleSecondsCounter);
        }
		var time = IdealTimeOut - idleSecondsCounter;
        if (time <= 30) {
            $('#lock-screen').modal('show');
        }
		if (time <= 0) {
			window.clearInterval(idleSecondsTimer);
			window.setTimeout("location.href='/portal/logout'", 1000);
		}
    }
</script>
{/if}

{if $Config['loginverify'] == 1 && $user->ga_status == 0}
 <script> 
	if(window.location.pathname != "/portal/settings"){
		Swal.fire({
			title: '',
			html:  "{$translate->get('Enable2Step')}",
			icon: 'info',
			showCancelButton: false,
			showConfirmButton:true,
			confirmButtonText: '{$translate->get('Continue')}',
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-sm btn-secondary ms-1',
				cancelButton: 'btn btn-sm  btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				window.setTimeout("location.href='/portal/settings'", 100);
			}	
		});
	}
 </script>
{/if}
{include file='common/copy.tpl'}
