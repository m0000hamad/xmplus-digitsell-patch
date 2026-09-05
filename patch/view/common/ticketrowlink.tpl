{literal}
<style>
#pagination tbody tr.tk-rowlink { cursor: pointer; }
#pagination tbody tr.tk-rowlink:hover { background: rgba(99, 102, 241, .06); }
#pagination tbody tr.tk-rowlink td:first-child,
#pagination tbody tr.tk-rowlink td.tk-title { font-weight: 600; }
html[data-hs-theme="dark"] #pagination tbody tr.tk-rowlink:hover { background: rgba(255, 255, 255, .05); }
</style>
<script>
/*
 * The ticket list only exposed the thread behind a small action button. Rows carry
 * that link already, so reuse it and let the whole row - the subject included - open
 * the ticket. Clicks on real controls inside the row are left alone.
 */
(function () {
	function ticketHref(row) {
		var link = row.querySelector('a[href*="/ticket/"]');
		if (link) { return link.getAttribute('href'); }

		var attrs = row.innerHTML.match(/\/(?:portal|admin)\/ticket\/(\d+)/);
		return attrs ? attrs[0] : null;
	}

	function wire() {
		var rows = document.querySelectorAll('#pagination tbody tr');

		for (var i = 0; i < rows.length; i++) {
			var row = rows[i];
			if (row.getAttribute('data-tk-linked') === '1') { continue; }

			var href = ticketHref(row);
			if (!href) { continue; }

			row.setAttribute('data-tk-linked', '1');
			row.setAttribute('data-tk-href', href);
			row.classList.add('tk-rowlink');

			row.addEventListener('click', function (event) {
				if (event.target.closest('a, button, input, select, label, .dropdown')) { return; }
				window.location.href = this.getAttribute('data-tk-href');
			});
		}
	}

	if (window.table_1 && typeof window.table_1.on === 'function') {
		window.table_1.on('draw', wire);
	}
	document.addEventListener('DOMContentLoaded', wire);
	wire();
})();
</script>
{/literal}
