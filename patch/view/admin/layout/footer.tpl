 	
	</div>
    <div class="footer text-center"> 
      <div class="row justify-content-between align-items-center">
        <div class="col">
          <p class="fs-6 mb-0"><script type="text/javascript">document.write(new Date().getFullYear());</script> &copy; {$Config['appName']} <br>XMPlus 1.0 - {$Config['version']}</p>
        </div>
        <!-- End Col -->

      </div>
    </div>
  </main>
   <!--<style>
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
  </a>-->
  
  <script src="/assets/js/vendor.min.js"></script>
  <script src="/assets/js/theme.min.js"></script>
  <script src="/assets/js/clipboard.js"></script>
  <script src="/assets/plugins/layui/layui.js"></script>
  <script src="/assets/plugins/table/jquery.dataTables.min.js"></script>
  <script src="/assets/plugins/table/dataTables.bootstrap5.min.js"></script>
  <script src="/assets/js/Chart.bundle.js"></script>
  <script src="/assets/js/sweetalert2.all.min.js"></script>
  <script src="/assets/js/fancybox.min.js"></script>
  
  
  <script>
	window.addEventListener('load', () => {  
		var collapseElementList = [].slice.call(document.querySelectorAll('.nav-collapse'));
		this.collapseList = collapseElementList.map(function (collapseEl) {
		   return new bootstrap.Collapse(collapseEl, {         
				toggle: false
		   });    
		})
		
		this.collapseList.forEach(function (collapse) {
			var trigeredEl = collapse._element;
			if(trigeredEl.id == localStorage.getItem('toggleID')){
				trigeredEl.setAttribute('aria-expanded', true);
				trigeredEl.classList.add('show');
			}
		}) 
	});	
	
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
        //new HSGoTo('.js-go-to')
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
{include file='common/copy.tpl'}
