<!DOCTYPE html> 
<html lang="en">  
<head>
  <meta charset="utf-8">
  <meta name="viewport" content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no shrink-to-fit=no'>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>{$Config['appName']}</title>
  <link rel="shortcut icon" type="image/x-icon" href="{$Config['logo_path']}">
  <link rel="stylesheet" href="/assets/css/theme6.css?v=1.0">
  {$rtlanguage = explode(',',$Config['rtlanguages'])}
  {if in_array($session->get('locale'), $rtlanguage)}
  <link as="style" rel="stylesheet preload" href="/assets/css/iransans.css?family=IRANSans:wght@300;500">
  <link as="style" rel="preload" href="/assets/css/default.rtl.css" data-hs-appearance="default">
  <link as="style" rel="preload" href="/assets/css/dark.rtl.css" data-hs-appearance="dark">
  {else}
  <link as="style" rel="stylesheet preload" href="/assets/css/inter.css?family=Inter:wght@400;600&amp;display=swap">
  <link as="style" rel="preload" href="/assets/css/default.css" data-hs-appearance="default">
  <link as="style" rel="preload" href="/assets/css/dark.css" data-hs-appearance="dark">
  {/if}
  <link as="style" rel="stylesheet preload"  href="/assets/fonts/fontawesome/css/all.css">
  <link rel="stylesheet" href="/assets/css/sweetalert2.min.css">
  <link rel="stylesheet" href="/assets/fonts/xmplus/css/xmplusfonts.css" >
  <link rel="stylesheet" href="/assets/plugins/table/dataTables.bootstrap5.min.css">
  <link rel="stylesheet" href="/assets/css/vendor.min.css">
  <link rel="stylesheet" href="/assets/css/style.css">
  <link rel="stylesheet" href="/assets/fonts/crypto/crypto.css">
  <style data-hs-appearance-onload-styles>
    *
    {
      transition: unset !important; 
    }

    body
    {
      opacity: 0;  
    }
  </style>  
  <style>
	.form-check-select-stretched .form-check-label::before {
		position: absolute;
		top: .75rem;
		left: .75rem;
		width: 1.25rem;
		height: 1.25rem;
		background-image: url("data:image/svg+xml,%3csvg width='18' height='18' viewBox='0 0 18 18' fill='none' xmlns='http://www.w3.org/2000/svg'%3e%3crect width='18' height='18' rx='9' fill='%23e7eaf3'/%3e%3cpath d='M12.0603 5.78792C12.2511 5.56349 12.5876 5.5362 12.8121 5.72697C13.0365 5.91774 13.0638 6.25432 12.873 6.47875L8.3397 11.8121C8.14594 12.04 7.80261 12.064 7.57901 11.8653L5.17901 9.73195C4.95886 9.53626 4.93903 9.19915 5.13472 8.979C5.33041 8.75885 5.66751 8.73902 5.88766 8.93471L7.88011 10.7058L12.0603 5.78792Z' fill='%23fff'/%3e%3c/svg%3e");
		background-repeat: no-repeat;
		background-position: left center;
		background-size: 1.25rem 1.25rem;
		content: ""
	}
    </style>
  <script>	
    window.hs_config = {
		"previewMode":false,
		"startPath":"/",
		"vars":{
			"themeFont":"/assets/css/inter.css?family=Inter:wght@400;600&amp;display=swap",
			"version":"?v=1.0"
		},
		"layoutBuilder":{
			"header":{
				"layoutMode":"default",
				"containerMode":"container-fluid"
			},
			"sidebarLayout":"default"
		},
		"themeAppearance":{
			"layoutSkin":"default",
			"sidebarSkin":"default",
			"styles":{
				"colors":{
					"primary":"#132144",
					"transparent":"transparent",
					"white":"#fff",
					"dark":"132144",
					"gray":{
						"100":"#f9fafc",
						"900":"#1e2022"
					}
				},
				"font":"Inter"
			}
		}
	}
</script>
<script type="text/javascript">
	{if $user->plan != "onetime"}
		window.addEventListener('load', () => {
			display_expt();
		});
	{/if}
	
	function Zero(i) {
		if (i < 10) {
			i = "0" + i;
		}
		return i;
	}
	
	function display_shw(){
		var refresh=1000;
		mytime = setTimeout('display_expt()',refresh);
	}
	
    function display_expt()
    {
		var countDownDate = new Date("{date("M d, Y H:i:s",strtotime($user->expire_in))} {$gmt}").getTime();
		var now = new Date().getTime();
		var distance = countDownDate - now;
		var days = Math.floor(distance / (1000 * 60 * 60 * 24));
		var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
		var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
		var seconds = Math.floor((distance % (1000 * 60)) / 1000);
		{if $session->get('locale') == "zh_CN"}
			if (distance > 0) {
				document.getElementById("countdown").innerHTML = Zero(days) + "天 " + Zero(hours) + "小时 "
				+ Zero(minutes) + "分 " ; //+ Zero(seconds) + "秒 ";
			}
			if (distance < 0) {
				document.getElementById("countdown").innerHTML = "过期了";
			}
		{else}
			if (distance > 0) {
				document.getElementById("countdown").innerHTML = Zero(days) + "D " + Zero(hours) + "H "
				+ Zero(minutes) + "M "; // + Zero(seconds) + "S "
			}
			if (distance < 0) {
				document.getElementById("countdown").innerHTML = "Expired";
			}
		{/if}
		display_shw();
	}
</script>
</head>
{include file='user/layout/style.tpl'}
<body class="has-navbar-vertical-aside navbar-vertical-aside-show-xl footer-offset">
  <script src="/assets/js/hs.theme-appearance.js"></script>
{literal}
<script>
/*
 * hs.theme-appearance.js swaps stylesheets but leaves no mark on the document,
 * so page-level CSS had no way to ask which theme is on. Mirror it here.
 * The attribute is data-hs-theme, not data-hs-appearance: that one is what the
 * theme script uses to find its <link> nodes.
 */
(function () {
	/* HSThemeMirror */
	function resolved() {
		var theme = null;

		try {
			theme = localStorage.getItem('hs_theme');
		} catch (error) { /* private mode */ }

		if (!theme && window.hs_config && window.hs_config.themeAppearance) {
			theme = window.hs_config.themeAppearance.layoutSkin;
		}
		if (!theme) { theme = 'default'; }

		if (theme === 'auto') {
			theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default';
		}
		return theme;
	}

	function stamp(theme) {
		document.documentElement.setAttribute('data-hs-theme', theme || resolved());
	}

	stamp();

	window.addEventListener('on-hs-appearance-change', function (event) {
		stamp(event.detail);
	});

	var query = window.matchMedia('(prefers-color-scheme: dark)');
	if (query.addEventListener) {
		query.addEventListener('change', function () { stamp(); });
	}
})();
</script>
{/literal}
  <script src="/assets/vendor/hs-navbar-vertical-aside/dist/hs-navbar-vertical-aside-mini-cache.js"></script>
  <header  id="header" class="navbar navbar-expand-lg navbar-fixed navbar-height navbar-container navbar-bordered bg-white">
    <div class="navbar-nav-wrap">
      <a class="navbar-brand" href="/" >
        <img class="navbar-brand-logo" src="{$Config['darkthemelogo']}"  data-hs-theme-appearance="default" style="min-width: 7rem; max-width: 9rem;">
        <img class="navbar-brand-logo" src="{$Config['darkthemelogo']}"  data-hs-theme-appearance="dark" style="min-width: 7rem; max-width: 9rem;">
      </a>

      <div class="navbar-nav-wrap-content-start">
        <button type="button" class="js-navbar-vertical-aside-toggle-invoker navbar-aside-toggler menu-glass-top">
          <span class="navbar-aside-toggler-label">{$translate->get('Menu')}</span>
          <span class="navbar-aside-toggler-label toggler-label-close">{$translate->get('CloseMenu')}</span>
        </button>
      </div>

      <div class="navbar-nav-wrap-content-end">
        <ul class="navbar-nav fw-bold countdown-pill" id="countdown"></ul>
      </div>
    </div>
  </header>
 {include file='user/layout/usermenu.tpl'}  