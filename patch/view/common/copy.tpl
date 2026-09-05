{literal}
<style>
.copy-text { cursor: pointer; }
.copy-flash {
	animation: copyFlash .9s ease;
}
@keyframes copyFlash {
	0%   { box-shadow: 0 0 0 0 rgba(16, 185, 129, .55); }
	100% { box-shadow: 0 0 0 10px rgba(16, 185, 129, 0); }
}
.copy-toast {
	position: fixed;
	inset-block-end: 24px;
	inset-inline-start: 50%;
	transform: translateX(50%) translateY(14px);
	z-index: 20000;
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 11px 18px;
	border-radius: 999px;
	background: linear-gradient(135deg, #059669, #10b981);
	color: #fff;
	font-size: 13px;
	font-weight: 700;
	box-shadow: 0 10px 30px rgba(16, 185, 129, .4);
	opacity: 0;
	pointer-events: none;
	transition: opacity .2s ease, transform .2s ease;
}
.copy-toast.copy-show { opacity: 1; transform: translateX(50%) translateY(0); }
.copy-toast.copy-warn {
	background: linear-gradient(135deg, #d97706, #f59e0b);
	box-shadow: 0 10px 30px rgba(245, 158, 11, .4);
}
</style>

<script>
/*
 * One copy routine for the whole panel.
 *
 * The old setup leaned on ClipboardJS bound to `.copy-text`, which failed for most
 * visitors: the fields carrying that class are `disabled`, so the browser never
 * dispatches a click on them and the delegated handler never fired. On top of that
 * execCommand('copy') is unreliable on iOS Safari and inside in-app browsers.
 *
 * This handles the click on the wrapper too, prefers the async Clipboard API, and
 * degrades to execCommand and finally to "we selected it, press copy".
 */
window.CopyText = (function () {
	var config = window.CopyText || {};

	function message(kind) {
		if (kind === 'manual') {
			return config.manual || 'Press Ctrl+C / long press to copy';
		}
		return config.message || 'Copied';
	}

	function toast(text, warn) {
		var box = document.getElementById('copyToast');
		if (!box) {
			box = document.createElement('div');
			box.id = 'copyToast';
			box.className = 'copy-toast';
			document.body.appendChild(box);
		}

		box.textContent = (warn ? '⚠️ ' : '✅ ') + text;
		box.classList.toggle('copy-warn', !!warn);

		// reflow so the transition replays when clicked twice in a row
		void box.offsetWidth;
		box.classList.add('copy-show');

		clearTimeout(box.hideTimer);
		box.hideTimer = setTimeout(function () {
			box.classList.remove('copy-show');
		}, warn ? 4000 : 2200);
	}

	function textOf(element) {
		var attr = element.getAttribute('data-clipboard-text');
		if (attr) { return attr; }
		if (typeof element.value === 'string' && element.value !== '') { return element.value; }
		return (element.textContent || '').trim();
	}

	function legacyCopy(text, element) {
		var helper = document.createElement('textarea');
		helper.value = text;
		helper.setAttribute('readonly', '');
		helper.style.position = 'fixed';
		helper.style.top = '0';
		helper.style.left = '-9999px';
		helper.style.opacity = '0';
		document.body.appendChild(helper);

		var ok = false;
		try {
			// iOS refuses select() on a plain textarea, it wants a range
			if (/ipad|iphone|ipod/i.test(navigator.userAgent)) {
				helper.contentEditable = 'true';
				var range = document.createRange();
				range.selectNodeContents(helper);
				var selection = window.getSelection();
				selection.removeAllRanges();
				selection.addRange(range);
				helper.setSelectionRange(0, text.length);
			} else {
				helper.select();
			}
			ok = document.execCommand('copy');
		} catch (error) {
			ok = false;
		}

		document.body.removeChild(helper);

		if (!ok && element && typeof element.select === 'function') {
			// last resort: leave it selected so the visitor can copy by hand
			try {
				element.removeAttribute('disabled');
				element.setAttribute('readonly', '');
				element.focus();
				element.select();
				element.setSelectionRange(0, 99999);
			} catch (error) { /* nothing else to try */ }
		}

		return ok;
	}

	function flash(element) {
		if (!element || !element.classList) { return; }
		element.classList.remove('copy-flash');
		void element.offsetWidth;
		element.classList.add('copy-flash');
		setTimeout(function () { element.classList.remove('copy-flash'); }, 900);
	}

	function copy(text, element) {
		if (!text) { return; }

		if (navigator.clipboard && window.isSecureContext) {
			navigator.clipboard.writeText(text).then(function () {
				flash(element);
				toast(message());
			}, function () {
				if (legacyCopy(text, element)) {
					flash(element);
					toast(message());
				} else {
					toast(message('manual'), true);
				}
			});
			return;
		}

		if (legacyCopy(text, element)) {
			flash(element);
			toast(message());
		} else {
			toast(message('manual'), true);
		}
	}

	function pick(event) {
		var direct = event.target.closest ? event.target.closest('.copy-text') : null;
		if (direct) { return direct; }

		// a disabled input swallows its own clicks, the event lands on the wrapper
		if (event.target.closest('a, button, [role="button"], select, textarea, label')) {
			return null;
		}

		var wrapper = event.target.closest('.input-group, .copy-wrap');
		if (!wrapper) { return null; }

		var inside = wrapper.querySelectorAll('.copy-text');
		return inside.length === 1 ? inside[0] : null;
	}

	document.addEventListener('click', function (event) {
		var element = pick(event);
		if (!element) { return; }

		event.preventDefault();
		copy(textOf(element), element);
	});

	return {
		message: config.message,
		manual: config.manual,
		copy: copy,
		toast: toast
	};
})();
</script>
{/literal}
