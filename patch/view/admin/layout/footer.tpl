 	
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

  {* Announcements card — only ever mounted on the admin notices list page.
     new Object(), not a brace literal: Smarty reads a brace as a tag. *}
  <script>
    window.DSAnnounce = new Object();
    window.DSAnnounce.endpoint = '/xmplus-patch.php';
    window.DSAnnounce.i18n = new Object();
    window.DSAnnounce.i18n.title    = "{$translate->get('AnnouncementsTitle')|escape:'javascript'}";
    window.DSAnnounce.i18n.hint     = "{$translate->get('AnnouncementsHint')|escape:'javascript'}";
    window.DSAnnounce.i18n.c1       = "{$translate->get('AnnounceCampaign1')|escape:'javascript'}";
    window.DSAnnounce.i18n.c2       = "{$translate->get('AnnounceCampaign2')|escape:'javascript'}";
    window.DSAnnounce.i18n.tg       = "{$translate->get('PromoAnnounceTelegram')|escape:'javascript'}";
    window.DSAnnounce.i18n.mail     = "{$translate->get('PromoAnnounceEmail')|escape:'javascript'}";
    window.DSAnnounce.i18n.grp      = "{$translate->get('AnnounceGroup')|escape:'javascript'}";
    window.DSAnnounce.i18n.popup    = "{$translate->get('AnnouncePopup')|escape:'javascript'}";
    window.DSAnnounce.i18n.textHint = "{$translate->get('AnnounceInviteText')|escape:'javascript'}";
    window.DSAnnounce.i18n.group    = "{$translate->get('AnnounceGroupId')|escape:'javascript'}";
    window.DSAnnounce.i18n.send     = "{$translate->get('AnnounceSendNow')|escape:'javascript'}";
    window.DSAnnounce.i18n.save     = "{$translate->get('Save')|escape:'javascript'}";
    window.DSAnnounce.i18n.saved    = "{$translate->get('AnnounceSaved')|escape:'javascript'}";
    window.DSAnnounce.i18n.sent     = "{$translate->get('AnnounceSent')|escape:'javascript'}";
    window.DSAnnounce.i18n.failed   = "{$translate->get('AnnounceFailed')|escape:'javascript'}";
    window.DSAnnounce.i18n.aud      = "{$translate->get('AnnounceAudience')|escape:'javascript'}";
    window.DSAnnounce.i18n.last     = "{$translate->get('AnnounceLast')|escape:'javascript'}";
    window.DSAnnounce.i18n.never    = "{$translate->get('AnnounceNever')|escape:'javascript'}";
  </script>

{literal}
<style>
.dsan-card {
  border-radius: 16px;
  background: #fff;
  border: 1.5px solid rgba(23, 32, 61, .09);
  box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
  padding: 16px 18px;
  margin-bottom: 20px;
}
.dsan-head { display: flex; align-items: center; flex-wrap: wrap; gap: 10px; margin-bottom: 14px; }
.dsan-title { font-size: 15px; font-weight: 800; color: #16203d; }
.dsan-hint { font-size: 11.5px; font-weight: 600; color: #8c98ab; }
.dsan-aud { margin-inline-start: auto; font-size: 12px; font-weight: 700; color: #4f46e5; background: rgba(99,102,241,.1); border-radius: 999px; padding: 4px 12px; }
.dsan-grid { display: grid; grid-template-columns: 1fr; gap: 14px; }
@media (min-width: 992px) { .dsan-grid { grid-template-columns: 1fr 1fr; } }
.dsan-camp { border: 1.5px solid rgba(23,32,61,.08); border-radius: 13px; padding: 13px 14px; }
.dsan-camp h6 { margin: 0 0 10px; font-size: 13.5px; font-weight: 800; color: #16203d; }
.dsan-switches { display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 10px; }
.dsan-sw { font-size: 12.5px; font-weight: 600; color: #3f4a63; cursor: pointer; margin: 0; }
.dsan-sw input { cursor: pointer; }
.dsan-popup { margin-bottom: 10px; }
.dsan-camp textarea { width: 100%; border: 1.5px solid rgba(23,32,61,.12); border-radius: 10px; padding: 8px 10px; font-size: 12.5px; margin-bottom: 10px; font-family: inherit; }
.dsan-meta { font-size: 11.5px; font-weight: 600; color: #8c98ab; margin-bottom: 10px; }
.dsan-btns { display: flex; gap: 8px; }
.dsan-foot { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; margin-top: 14px; padding-top: 13px; border-top: 1px dashed rgba(23,32,61,.12); }
.dsan-foot label { font-size: 12px; font-weight: 700; color: #56617a; margin: 0; }
.dsan-foot input { flex: 1 1 220px; min-width: 160px; border: 1.5px solid rgba(23,32,61,.12); border-radius: 10px; padding: 7px 10px; font-size: 12.5px; }
html[data-hs-theme="dark"] .dsan-card { background: #1c2536; border-color: rgba(255,255,255,.09); }
html[data-hs-theme="dark"] .dsan-title, html[data-hs-theme="dark"] .dsan-camp h6 { color: #e7eaf3; }
html[data-hs-theme="dark"] .dsan-camp { border-color: rgba(255,255,255,.1); }
html[data-hs-theme="dark"] .dsan-sw, html[data-hs-theme="dark"] .dsan-foot label { color: #b9c2d4; }
html[data-hs-theme="dark"] .dsan-camp textarea, html[data-hs-theme="dark"] .dsan-foot input { background: #131b2a; color: #e7eaf3; border-color: rgba(255,255,255,.12); }
html[data-hs-theme="dark"] .dsan-foot { border-top-color: rgba(255,255,255,.12); }
</style>
{/literal}

{literal}
<script>
(function () {
  var cfg = window.DSAnnounce;
  if (!cfg) { return; }
  if (location.pathname.replace(/\/+$/, '') !== '/admin/notices') { return; }

  function say(text) {
    if (window.layer && layer.msg) { layer.msg(text, { time: 5000, offset: '100px' }); }
    else { window.alert(text); }
  }
  function esc(s) {
    var d = document.createElement('div');
    d.textContent = (s === null || s === undefined) ? '' : String(s);
    return d.innerHTML;
  }
  function sw(camp, ch, label) {
    return '<label class="dsan-sw form-check form-switch"><input type="checkbox" class="form-check-input" data-camp="' + camp + '" data-ch="' + ch + '"> ' + esc(label) + '</label>';
  }

  var card = document.createElement('div');
  card.className = 'dsan-card';
  card.innerHTML =
    '<div class="dsan-head"><span class="dsan-title">\uD83D\uDCE3 ' + esc(cfg.i18n.title) + '</span>'
    + '<span class="dsan-hint">' + esc(cfg.i18n.hint) + '</span>'
    + '<span class="dsan-aud">' + esc(cfg.i18n.aud) + ': <b id="dsanAud">\u2014</b></span></div>'
    + '<div class="dsan-grid">'
    + '<div class="dsan-camp" data-camp="c1"><h6>' + esc(cfg.i18n.c1) + '</h6>'
    + '<div class="dsan-switches">' + sw('c1', 'tg', cfg.i18n.tg) + sw('c1', 'mail', cfg.i18n.mail) + sw('c1', 'grp', cfg.i18n.grp) + '</div>'
    + '<div class="dsan-meta" id="dsanC1Meta"></div>'
    + '<div class="dsan-btns">'
    + '<button type="button" class="btn btn-sm btn-outline-primary" data-act="save" data-camp="c1">' + esc(cfg.i18n.save) + '</button>'
    + '<button type="button" class="btn btn-sm btn-primary" data-act="send" data-camp="c1">' + esc(cfg.i18n.send) + '</button>'
    + '</div></div>'
    + '<div class="dsan-camp" data-camp="c2"><h6>' + esc(cfg.i18n.c2) + '</h6>'
    + '<label class="dsan-sw dsan-popup form-check form-switch"><input type="checkbox" class="form-check-input" id="dsanPopup"> ' + esc(cfg.i18n.popup) + '</label>'
    + '<div class="dsan-switches">' + sw('c2', 'tg', cfg.i18n.tg) + sw('c2', 'mail', cfg.i18n.mail) + sw('c2', 'grp', cfg.i18n.grp) + '</div>'
    + '<textarea id="dsanC2Text" rows="4" placeholder="' + esc(cfg.i18n.textHint) + '"></textarea>'
    + '<div class="dsan-meta" id="dsanC2Meta"></div>'
    + '<div class="dsan-btns">'
    + '<button type="button" class="btn btn-sm btn-outline-primary" data-act="save" data-camp="c2">' + esc(cfg.i18n.save) + '</button>'
    + '<button type="button" class="btn btn-sm btn-primary" data-act="send" data-camp="c2">' + esc(cfg.i18n.send) + '</button>'
    + '</div></div></div>'
    + '<div class="dsan-foot"><label>' + esc(cfg.i18n.group) + '</label>'
    + '<input type="text" id="dsanGroup" dir="ltr" placeholder="-1001234567890"></div>';

  var anchor = document.querySelector('.page-header');
  if (anchor && anchor.parentNode) { anchor.parentNode.insertBefore(card, anchor.nextSibling); }
  else { (document.querySelector('main') || document.body).insertBefore(card, (document.querySelector('main') || document.body).firstChild); }

  function each(sel, fn) { Array.prototype.forEach.call(card.querySelectorAll(sel), fn); }

  function fmt(stamp) {
    if (!stamp) { return cfg.i18n.never; }
    try { return new Date(stamp * 1000).toLocaleString('fa-IR'); } catch (e) { return ''; }
  }

  function apply(data) {
    if (data.token) { cfg.token = data.token; }
    var a = card.querySelector('#dsanAud'); if (a) { a.textContent = data.audience; }
    ['c1', 'c2'].forEach(function (camp) {
      var e = data[camp] || {};
      each('[data-camp="' + camp + '"][data-ch]', function (cb) {
        cb.checked = parseInt(e[cb.getAttribute('data-ch')] || 0, 10) === 1;
      });
      var meta = card.querySelector('#dsan' + camp.toUpperCase() + 'Meta');
      if (meta) {
        var when = parseInt(e.sent_stamp || 0, 10) > 0 ? fmt(e.sent_at) : cfg.i18n.never;
        var n = parseInt(e.sent_users || 0, 10);
        meta.textContent = cfg.i18n.last + ': ' + when + (n > 0 ? ' \u00b7 ' + n : '');
      }
    });
    var pop = card.querySelector('#dsanPopup'); if (pop) { pop.checked = parseInt(data.popup || 0, 10) === 1; }
    var ta = card.querySelector('#dsanC2Text');
    if (ta && ta.value === '') { ta.value = data.invite || ''; }
    var g = card.querySelector('#dsanGroup'); if (g && g.value === '') { g.value = data.group || ''; }
  }

  function load() {
    fetch(cfg.endpoint + '?do=announce.state', { credentials: 'same-origin' })
      .then(function (r) { return r.json(); })
      .then(function (data) { if (data && data.ok) { apply(data); } })
      .catch(function () {});
  }

  function values(camp) {
    var body = new FormData();
    body.append('campaign', camp);
    ['tg', 'mail', 'grp'].forEach(function (ch) {
      var cb = card.querySelector('[data-camp="' + camp + '"][data-ch="' + ch + '"]');
      body.append(ch, cb && cb.checked ? '1' : '0');
    });
    if (camp === 'c2') {
      var pop = card.querySelector('#dsanPopup');
      var ta = card.querySelector('#dsanC2Text');
      body.append('popup', pop && pop.checked ? '1' : '0');
      body.append('text', ta ? ta.value : '');
    }
    var g = card.querySelector('#dsanGroup');
    if (g) { body.append('group', g.value); }
    return body;
  }

  card.addEventListener('click', function (ev) {
    var btn = ev.target.closest('button[data-act]');
    if (!btn) { return; }
    var camp = btn.getAttribute('data-camp');
    var act = btn.getAttribute('data-act');
    var body = values(camp);
    body.append('token', cfg.token || '');
    fetch(cfg.endpoint + '?do=' + (act === 'send' ? 'announce.send' : 'announce.save'),
      { method: 'POST', credentials: 'same-origin', body: body })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data && data.ok) { say(act === 'send' ? cfg.i18n.sent : cfg.i18n.saved); load(); }
        else { say((data && data.error) || cfg.i18n.failed); }
      })
      .catch(function () { say(cfg.i18n.failed); });
  });

  load();
})();
</script>
{/literal}
</body>
</html>
{include file='common/copy.tpl'}
{include file='common/ovpnicon.tpl'}
{include file='common/wgicon.tpl'}
