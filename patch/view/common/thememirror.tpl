{literal}
<script>
/* The theme library uses data-hs-appearance on stylesheet links. */
(function () {
	var root = document.documentElement;
	var query = window.matchMedia('(prefers-color-scheme: dark)');
	var preference;

	function stamp(event) {
		var theme = event && event.detail;
		if (typeof theme !== 'string') {
			try { theme = localStorage.getItem('hs_theme'); } catch (error) { /* storage unavailable */ }
		}
		var config = window.hs_config && window.hs_config.themeAppearance;
		preference = theme || preference || (config && config.layoutSkin) || 'default';
		var active = preference === 'auto' ? (query.matches ? 'dark' : 'default') : preference;
		if (root.getAttribute('data-hs-theme') !== active) {
			root.setAttribute('data-hs-theme', active);
		}
	}

	stamp();
	window.addEventListener('on-hs-appearance-change', stamp);
	if (query.addEventListener) { query.addEventListener('change', stamp); }
})();
</script>
{/literal}
