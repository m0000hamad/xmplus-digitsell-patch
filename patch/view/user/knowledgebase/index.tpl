{include file='user/layout/knwhead.tpl'}

	<div class="bg-dark">
		<div class="content container-fluid" style="height: 20rem;">
			<div class="page-header page-header-light">
				<div class="row align-items-end">
					<div class="col-sm mb-2 mb-sm-0">
						<h1 class="page-header-title">{$translate->get('Knowledgebase')}</h1>
					</div>
				</div>
			</div>
		</div>
	</div>	
	
	<div class="content container-fluid" style="margin-top: -12rem;">
			<div class="col-9 col-sm-offset-3 col-md-9 col-lg-offset-3 col-lg-9 mx-auto mb-3">
				<div class="row mb-3 d-flex flex-wrap">
				  <div class="col-xl-4 col-lg-4 col-sm-4 col-md-4 mb-3">
					<div class="card card-lg border border-white form-check form-check-select-stretched h-100 zi-1 active" >
					  <div class="card-header text-center rounded">
						<input type="radio" class="form-check-input" name="Knowledgebase" id="faqs" checked value="faqs" onClick="knw()">
						<label class="form-check-label" for="faqs"></label>
						<h2 class="card-title display-5 text-dark"><i class="fa-duotone fa-book-open"></i><br>{$translate->get('FAQs')}</h2>
					  </div>
					</div>
				  </div>

				  <div class="col-xl-4 col-lg-4 col-sm-4 col-md-4 mb-3">
					<div class="card card-lg border border-white form-check form-check-select-stretched h-100 zi-1">
					  <div class="card-header text-center rounded">
						<input type="radio" class="form-check-input" name="Knowledgebase" id="apps" value="apps" onClick="knw()">
						<label class="form-check-label" for="apps"></label>

						<h2 class="card-title display-5 text-dark"><i class="fa-duotone fa-screwdriver-wrench"></i><br>{$translate->get('HowTo')}</h2>
					  </div>      
					</div>
				  </div>

				  <div class="col-xl-4 col-lg-4 col-sm-4 col-md-4 mb-3">
					<div class="card card-lg border border-white form-check form-check-select-stretched h-100 zi-1">
					  <div class="card-header text-center rounded" href="#others">
						<input type="radio" class="form-check-input" name="Knowledgebase" id="others" value="others" onClick="knw()">
						<label class="form-check-label" for="others"></label>
						<h2 class="card-title display-5 text-dark"><i class="fa-duotone fa-book-open-cover"></i><br>{$translate->get('Others')}</h2>
					  </div>
					</div>
				  </div>
				</div>
			</div>	
			<div>
				<div id="faqstab">
					<!-- Accordion -->
					<div class="accordion shadow-lg rounded" id="accordionFAQ">
					  {foreach $knw as $knowledgebase}
					  {if $knowledgebase->type == 'faq'}
						<div class="accordion-item">
							<div class="accordion-header" id="heading{$knowledgebase->id}">
							  <a class="accordion-button text-dark fs-8" role="button" data-bs-toggle="collapse" data-bs-target="#collapse{$knowledgebase->id}" aria-expanded="true" aria-controls="collapse{$knowledgebase->id}">
								{$knowledgebase->title}
							  </a>
							</div>
							<div id="collapse{$knowledgebase->id}" class="accordion-collapse collapse" aria-labelledby="heading{$knowledgebase->id}" data-bs-parent="#accordionFAQ">
							  <div class="accordion-body">
							    {$content = json_decode($knowledgebase->content,true)}
								{assign var=lang value="_"|explode:$session->get('locale')}
								<p>{if isset($content[$lang[1]])}{$content[$lang[1]]}{/if}</p>
							  </div>
							</div>
						</div>
					  {/if}
					  {/foreach}
					</div>
					<!-- End Accordion -->
				</div>
				<div id="appstab" hidden>
					<!-- Accordion -->
					<div class="accordion shadow-lg rounded" id="accordionApp">
					  {foreach $knw as $knowledgebase}
					  {if $knowledgebase->type == 'app'}
						<div class="accordion-item">
							<div class="accordion-header" id="heading{$knowledgebase->id}">
							  <a class="accordion-button text-dark fs-8" href="/portal/knowledgebase/{$knowledgebase->uuid}"  aria-controls="collapse{$knowledgebase->id}">
								{$knowledgebase->title}
							  </a>
							</div>
						</div>
					  {/if}
					  {/foreach}
					</div>
					<!-- End Accordion -->
				</div>
				<div class="rounded" id="otherstab" hidden>
					<!-- Accordion -->
					<div class="accordion shadow-lg rounded" id="accordionOthers">
					  {foreach $knw as $knowledgebase}
					  {if $knowledgebase->type == 'others'}
						<div class="accordion-item">
							<div class="accordion-header" id="heading{$knowledgebase->id}">
							  <a class="accordion-button text-dark fs-8" href="/portal/knowledgebase/{$knowledgebase->uuid}"  aria-controls="collapse{$knowledgebase->id}">
								{$knowledgebase->title}
							  </a>
							</div>
						</div>
					  {/if}
					  {/foreach}
					</div>
					<!-- End Accordion -->
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
	
	knw();
	
	function knw(){
		var knw = $("input[name='Knowledgebase']:checked").val();
		if(knw == 'faqs'){
			document.getElementById('faqstab').hidden = false;
			document.getElementById('appstab').hidden = true;
			document.getElementById('otherstab').hidden = true;
		}
		if(knw == 'apps'){
			document.getElementById('faqstab').hidden = true;
			document.getElementById('appstab').hidden = false;
			document.getElementById('otherstab').hidden = true;
		}
		if(knw == 'others'){
			document.getElementById('faqstab').hidden = true;
			document.getElementById('appstab').hidden = true;
			document.getElementById('otherstab').hidden = false;
		}
	}
	
	
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
