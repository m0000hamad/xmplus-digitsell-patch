<aside class="js-navbar-vertical-aside navbar navbar-vertical-aside navbar-vertical navbar-vertical-fixed navbar-expand-xl navbar-dark bg-dark">
    <div class="navbar-vertical-container">
      <div class="navbar-vertical-footer-offset">
  
        <a class="navbar-brand" href="javascript:void(0)" >
          <img class="navbar-brand-logo" src="{$Config['darkthemelogo']}"  data-hs-theme-appearance="default" style="min-width: 7rem; max-width: 10rem;">
          <img class="navbar-brand-logo" src="{$Config['darkthemelogo']}" data-hs-theme-appearance="dark" style="min-width: 7rem; max-width: 10rem;">
        </a>
     


        <div class="navbar-vertical-content">
          <div id="navbarVerticalMenu" class="nav nav-pills nav-vertical card-navbar-nav">
			<!--<div class="avatar avatar-xxl avatar-circle profile-cover-avatar" style="margin-top:0px">
				<img  class="avatar-img" src="{if $user->image == ""}/assets/img/160x160/img6.jpg{else}/assets/avatars/{$user->image}{/if}">
		    </div>-->
			<span class="dropdown-header mt-4">{$translate->get('MenuMain')}</span>
			<small class="bi-three-dots nav-subtitle-replacer"></small>
			
			<div class="nav-item" style="--mc:#6366f1;--mcs:rgba(99, 102, 241,.12);--mch:rgba(99, 102, 241,.26);--mcd:#4338ca">
              <a class="nav-link " href="/portal/dashboard" data-placement="left">
                <span class="nav-icon nav-sticker">🏠</span>
				<span class="nav-link-title">{$translate->get('Dashboard')}</span>
              </a>
            </div>
			
			<div class="nav-item" style="--mc:#0ea5e9;--mcs:rgba(14, 165, 233,.12);--mch:rgba(14, 165, 233,.26);--mcd:#0369a1">
              <a class="nav-link " href="/portal/settings" data-placement="left">
                <span class="nav-icon nav-sticker">⚙️</span>
				<span class="nav-link-title">{$translate->get('AccSettings')}</span>
              </a>
            </div>
			
			<div class="nav-item" style="--mc:#f59e0b;--mcs:rgba(245, 158, 11,.12);--mch:rgba(245, 158, 11,.26);--mcd:#b45309">
              <a class="nav-link " href="/portal/notices" data-placement="left">
                <span class="nav-icon nav-sticker">📣</span>
				<span class="nav-link-title">{$translate->get('Notices')}</span>
              </a>
            </div>
			{if $Config['rebate'] == 1}
			<div class="nav-item" style="--mc:#ec4899;--mcs:rgba(236, 72, 153,.12);--mch:rgba(236, 72, 153,.26);--mcd:#be185d">
              <a class="nav-link " href="/portal/affiliate#invite" data-placement="left">
                <span class="nav-icon nav-sticker">🤝</span>
				<span class="nav-link-title">{$translate->get('Invitation')}</span>
              </a>
            </div>
			{/if}
			<div class="nav-item" style="--mc:#06b6d4;--mcs:rgba(6, 182, 212,.12);--mch:rgba(6, 182, 212,.26);--mcd:#0e7490">
              <a class="nav-link " href="/portal/servers" data-placement="left">
                <span class="nav-icon nav-sticker">🌍</span>
				<span class="nav-link-title">{$translate->get('Servers')}</span>
              </a>
            </div>
			{if $Config['accounts'] == 1}
			<div class="nav-item" style="--mc:#8b5cf6;--mcs:rgba(139, 92, 246,.12);--mch:rgba(139, 92, 246,.26);--mcd:#6d28d9">
              <a class="nav-link " href="/portal/accounts" data-placement="left">
                <span class="nav-icon nav-sticker">🔗</span>
				<span class="nav-link-title">{$translate->get('SharedAccount')}</span>
              </a>
            </div>
			{/if}

            <span class="dropdown-header mt-4">{$translate->get('Transaction')}</span>
            <small class="bi-three-dots nav-subtitle-replacer"></small>

            <div class="nav-item" style="--mc:#10b981;--mcs:rgba(16, 185, 129,.12);--mch:rgba(16, 185, 129,.26);--mcd:#047857">
              <a class="nav-link " href="/portal/plans" data-placement="left">
                <span class="nav-icon nav-sticker">🛒</span>
                <span class="nav-link-title">{$translate->get('Plans')}</span>
              </a>
            </div>

            <div class="nav-item" style="--mc:#14b8a6;--mcs:rgba(20, 184, 166,.12);--mch:rgba(20, 184, 166,.26);--mcd:#0f766e">
              <a class="nav-link " href="/portal/orders" data-placement="left">
                <span class="nav-icon nav-sticker">🧾</span>
                <span class="nav-link-title">{$translate->get('Orders')}</span>
              </a>
            </div>

            <span class="dropdown-header mt-4">{$translate->get('Support')}</span>
            <small class="bi-three-dots nav-subtitle-replacer"></small>

            <div class="nav-item" style="--mc:#f43f5e;--mcs:rgba(244, 63, 94,.12);--mch:rgba(244, 63, 94,.26);--mcd:#be123c">
              <a class="nav-link " href="/portal/tickets" data-placement="left">
                <span class="nav-icon nav-sticker">💬</span> 
                <span class="nav-link-title">{$translate->get('Tickets')}</span>
              </a>
            </div>

            <div class="nav-item" style="--mc:#fb923c;--mcs:rgba(251, 146, 60,.12);--mch:rgba(251, 146, 60,.26);--mcd:#c2410c">
              <a class="nav-link " href="/portal/knowledgebase" data-placement="left">
                <span class="nav-icon nav-sticker">📚</span>
                <span class="nav-link-title">{$translate->get('Knowledgebase')}</span>
              </a>
            </div>
			{if $Config['tg_grouplink'] != ""}
			<div class="nav-item" style="--mc:#3b82f6;--mcs:rgba(59,130,246,.12);--mch:rgba(59,130,246,.26);--mcd:#1d4ed8">
			  <a class="nav-link" type="button" href="{$Config['tg_grouplink']}" target="_blank" data-placement="left">
                <span class="nav-icon nav-sticker"><i class="fa-brands fa-telegram"></i></span>
                <span class="nav-link-title">Telegram Group Link</span>
              </a>
			</div>
			{/if}
          </div>

        </div>

        <div class="navbar-vertical-footer">
          <ul class="navbar-vertical-footer-list">
            
			<li class="navbar-vertical-footer-list-item">
              <div class="theme-mode">
				<button class="btn btn-ghost-secondary text-white btn-icon rounded-circle default" data-hs-theme-appearance="default"><i class="fa-duotone fa-sun" style="font-size:18px"></i></button>
				<button class="btn btn-ghost-secondary text-white btn-icon rounded-circle dark" data-hs-theme-appearance="dark"><i class="fa-duotone fa-moon" style="font-size:18px"></i></button>
              </div>
            </li>

            <li class="navbar-vertical-footer-list-item">
              <div class="dropdown dropup">
                <button type="button" class="btn btn-ghost-secondary text-white btn-icon rounded-circle" id="otherLinksDropdown" data-bs-toggle="dropdown" aria-expanded="false" data-bs-dropdown-animation>
                  <i class="fa-solid fa-right-to-bracket" style="font-size:18px"></i> 
                </button>

                <div class="dropdown-menu navbar-dropdown-menu-borderless" aria-labelledby="otherLinksDropdown">
                  <a class="dropdown-item" href="/logout">
					<i class="fa-duotone fa-right-from-bracket dropdown-item-icon"></i>
                    <span class="text-truncate" >{$translate->get('SignOut')}</span>
                  </a>
				  
				  {if isset($session->get('adminview')) && $session->get('adminview') == true}
				  <a class="dropdown-item" href="/portal/switch">
                    <i class="fa-duotone fa-user-secret dropdown-item-icon"></i>
                    <span class="text-truncate" >{$translate->get('Return')}</span>
                  </a>
				  {elseif $user->role != 0}
                  <a class="dropdown-item" href="/admin">
					<i class="fa-duotone fa-user-secret dropdown-item-icon"></i>
                    <span class="text-truncate" >{$translate->get('AdminP')}</span>
                  </a>
				  {/if}
                </div>
              </div>
            </li>
			{if $Config['language_selector'] == 1}
            <li class="navbar-vertical-footer-list-item">
              <!-- Language -->
              <div class="dropdown dropup">
                <button type="button" class="btn btn-ghost-secondary text-white btn-icon rounded-circle" id="selectLanguageDropdown" data-bs-toggle="dropdown" aria-expanded="false" data-bs-dropdown-animation>
                </button>

                <div class="dropdown-menu navbar-dropdown-menu-borderless" aria-labelledby="selectLanguageDropdown">
                  <span class="dropdown-header">Select language</span>
                  {$language = explode(',',$Config['languages'])}
				  {foreach $language as $locale}
				  {assign var=lang value="_"|explode:$locale}
				  <a class="dropdown-item" href="javascript:void(0)"  onClick="switchLang('{$locale}')">
                    <img class="avatar avatar-xss avatar-circle me-2" data-lang="{$lang[1]|lower|escape}" src="/assets/vendor/flag-icon-css/flags/1x1/{$lang[1]|lower|escape}.svg" alt="Flag">
                    <span class="text-truncate" >{$translate->get({$locale})}</span>
                  </a>
				  {/foreach}
                </div>
              </div>
            </li>
			{/if}
          </ul>
        </div>
      </div>
    </div>
  </aside>
 


{literal}
<script>
(function () {
	var here = window.location.pathname.replace(/\/+$/, '') || '/portal/dashboard';
	var links = document.querySelectorAll('#navbarVerticalMenu .nav-link');

	for (var i = 0; i < links.length; i++) {
		var href = links[i].getAttribute('href') || '';
		if (href.charAt(0) !== '/') { continue; }

		var path = href.split('#')[0].split('?')[0].replace(/\/+$/, '');
		if (path && here.indexOf(path) === 0) {
			links[i].classList.add('nav-here');
		}
	}
})();
</script>
{/literal}

  <main id="content" class="main">
    <div class="content container-fluid">