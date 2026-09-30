{*
 * Invite link as a QR code: a friend sitting next to you scans it with the phone
 * camera and lands on the sign-up page with your code already attached.
 * Opened from the "QR code" button on the affiliate page's link card. The code is
 * drawn in the browser - no library, no CDN (the site sits behind an Iranian CDN
 * and public/assets is outside the updater's paths) - from the link in
 * #invitelink, so a reset link is what gets drawn.
 *}
{literal}
<style>
.aq-modal .modal-content { border: 0; border-radius: 20px; overflow: hidden; }
.aq-modal .modal-dialog { max-width: 380px; }
.aq-head {
	position: relative;
	padding: 18px 22px;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	color: #fff;
	overflow: hidden;
}
.aq-head::after {
	content: "";
	position: absolute;
	inset-block-start: -50px;
	inset-inline-end: -40px;
	width: 150px;
	height: 150px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .12);
}
.aq-title { position: relative; font-size: 14.5px; font-weight: 800; margin-bottom: 4px; }
.aq-note { position: relative; font-size: 11.5px; font-weight: 600; opacity: .9; line-height: 1.9; }
.aq-close {
	position: absolute;
	top: 14px;
	inset-inline-start: 16px;
	z-index: 3;
	border: 0;
	background: rgba(255, 255, 255, .2);
	color: #fff;
	width: 28px;
	height: 28px;
	border-radius: 50%;
	font-size: 15px;
	line-height: 1;
	cursor: pointer;
}
.aq-head .aq-title, .aq-head .aq-note { padding-inline-start: 36px; }
.aq-body { padding: 18px 20px 20px; }
/* a QR needs a light ground to stay scannable, dark mode included */
.aq-code {
	background: #fff;
	border-radius: 18px;
	padding: 10px;
	margin: 0 auto;
	width: 100%;
	max-width: 280px;
	box-shadow: inset 0 0 0 1.5px rgba(23, 32, 61, .1), 0 10px 26px -14px rgba(79, 70, 229, .45);
}
.aq-code canvas { display: block; width: 100%; height: auto; image-rendering: pixelated; }
.aq-link {
	margin: 12px 0 14px;
	text-align: center;
	direction: ltr;
	unicode-bidi: isolate;
	font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
	font-size: 11.5px;
	color: #4f46e5;
	word-break: break-all;
}
.aq-row { display: flex; gap: 8px; flex-wrap: wrap; }
.aq-btn {
	flex: 1 1 0;
	min-width: 0;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	border: 0;
	border-radius: 12px;
	padding: 11px 10px;
	font-family: inherit;
	font-size: 12.5px;
	font-weight: 700;
	line-height: 1.2;
	white-space: nowrap;
	cursor: pointer;
	color: #fff !important;
	text-decoration: none !important;
	transition: transform .14s ease, filter .14s ease;
}
.aq-btn:hover { transform: translateY(-1px); filter: brightness(1.05); }
.aq-btn[hidden] { display: none; }
.aq-save { background: linear-gradient(135deg, #4f46e5, #7c3aed); box-shadow: 0 7px 18px rgba(99, 102, 241, .3); }
.aq-share { background: linear-gradient(135deg, #2aabee, #229ed9); }
.aq-copy { background: rgba(23, 32, 61, .07); color: #16203d !important; }
.aq-copy.aq-done { background: #10b981; color: #fff !important; }

/* the button on the link card */
.af-btn-qr { background: rgba(255, 255, 255, .22); color: #fff !important; }

html[data-hs-theme="dark"] .aq-modal .modal-content { background: #18213a; }
html[data-hs-theme="dark"] .aq-link { color: #a5b4fc; }
html[data-hs-theme="dark"] .aq-copy { background: rgba(255, 255, 255, .09); color: #e7eaf3 !important; }
</style>
{/literal}

<div class="modal fade aq-modal" id="afQrModal" tabindex="-1" role="dialog" aria-labelledby="afQrTitle" aria-hidden="true">
	<div class="modal-dialog modal-dialog-centered" role="document">
		<div class="modal-content">
			<div class="aq-head">
				<button type="button" class="aq-close" data-bs-dismiss="modal" aria-label="Close">&times;</button>
				<div class="aq-title" id="afQrTitle">📱 {$translate->get('InviteQrTitle')}</div>
				<div class="aq-note">{$translate->get('InviteQrNote')}</div>
			</div>
			<div class="aq-body">
				<div class="aq-code"><canvas id="afQrCanvas" width="1" height="1" role="img" aria-label="{$translate->get('InviteQrTitle')|escape:'html'}"></canvas></div>
				<div class="aq-link" id="afQrLink"></div>
				<div class="aq-row">
					<button type="button" class="aq-btn aq-save" id="afQrSave">⬇️ {$translate->get('InviteQrSave')}</button>
					<button type="button" class="aq-btn aq-share" id="afQrShare" hidden>📤 {$translate->get('InviteQrShare')}</button>
					<button type="button" class="aq-btn aq-copy" id="afQrCopy" data-done="✅ {$translate->get('InviteShareCopied')|escape:'html'}">📋 {$translate->get('InviteShareCopy')}</button>
				</div>
			</div>
		</div>
	</div>
</div>

{literal}
<script>
(function () {
	/*
	 * Minimal QR encoder (byte mode, versions 1-40), after Project Nayuki's
	 * qrcodegen (MIT). Returns { size, dark(x, y) }.
	 */
	function dsQrEncode(text) {
		var ECC = [
			[-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
			[-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
			[-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
			[-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30]
		];
		var BLOCKS = [
			[-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
			[-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
			[-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
			[-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81]
		];
		var FORMAT = [1, 0, 3, 2]; // L M Q H

		function rawModules(ver) {
			var n = (16 * ver + 128) * ver + 64;
			if (ver >= 2) {
				var a = Math.floor(ver / 7) + 2;
				n -= (25 * a - 10) * a - 55;
				if (ver >= 7) { n -= 36; }
			}
			return n;
		}
		function dataCodewords(ver, ecl) {
			return Math.floor(rawModules(ver) / 8) - ECC[ecl][ver] * BLOCKS[ecl][ver];
		}
		function bit(x, i) { return ((x >>> i) & 1) !== 0; }
		function gfMul(x, y) {
			var z = 0;
			for (var i = 7; i >= 0; i--) {
				z = (z << 1) ^ ((z >>> 7) * 0x11D);
				z ^= ((y >>> i) & 1) * x;
			}
			return z;
		}

		// UTF-8 bytes - the link is ASCII, but the encoder must not care
		var bytes = [];
		var utf = unescape(encodeURIComponent(text));
		for (var b = 0; b < utf.length; b++) { bytes.push(utf.charCodeAt(b)); }

		// smallest version at medium correction, then as much correction as still fits
		var ver, ecl = 1, used;
		for (ver = 1; ; ver++) {
			if (ver > 40) { return null; }
			used = 4 + (ver < 10 ? 8 : 16) + bytes.length * 8;
			if (used <= dataCodewords(ver, ecl) * 8) { break; }
		}
		for (var e = 2; e <= 3; e++) {
			if (used <= dataCodewords(ver, e) * 8) { ecl = e; }
		}

		// data bits
		var bits = [];
		function put(val, len) { for (var i = len - 1; i >= 0; i--) { bits.push((val >>> i) & 1); } }
		put(4, 4);
		put(bytes.length, ver < 10 ? 8 : 16);
		for (var k = 0; k < bytes.length; k++) { put(bytes[k], 8); }
		var capacity = dataCodewords(ver, ecl) * 8;
		put(0, Math.min(4, capacity - bits.length));
		put(0, (8 - bits.length % 8) % 8);
		for (var pad = 0xEC; bits.length < capacity; pad ^= 0xEC ^ 0x11) { put(pad, 8); }
		var data = [];
		for (var d = 0; d < bits.length; d += 8) {
			var v = 0;
			for (var j = 0; j < 8; j++) { v = (v << 1) | bits[d + j]; }
			data.push(v);
		}

		// error correction, split into blocks and interleaved
		var numBlocks = BLOCKS[ecl][ver], eccLen = ECC[ecl][ver];
		var rawCodewords = Math.floor(rawModules(ver) / 8);
		var numShort = numBlocks - rawCodewords % numBlocks;
		var shortLen = Math.floor(rawCodewords / numBlocks);
		var divisor = [];
		for (var q = 0; q < eccLen - 1; q++) { divisor.push(0); }
		divisor.push(1);
		for (var root = 1, r = 0; r < eccLen; r++) {
			for (var s = 0; s < divisor.length; s++) {
				divisor[s] = gfMul(divisor[s], root);
				if (s + 1 < divisor.length) { divisor[s] ^= divisor[s + 1]; }
			}
			root = gfMul(root, 0x02);
		}
		var blocks = [];
		for (var bi = 0, at = 0; bi < numBlocks; bi++) {
			var chunk = data.slice(at, at + shortLen - eccLen + (bi < numShort ? 0 : 1));
			at += chunk.length;
			var rem = divisor.map(function () { return 0; });
			for (var c = 0; c < chunk.length; c++) {
				var factor = chunk[c] ^ rem.shift();
				rem.push(0);
				for (var t = 0; t < divisor.length; t++) { rem[t] ^= gfMul(divisor[t], factor); }
			}
			if (bi < numShort) { chunk.push(0); }
			blocks.push(chunk.concat(rem));
		}
		var codewords = [];
		for (var i2 = 0; i2 < blocks[0].length; i2++) {
			for (var j2 = 0; j2 < blocks.length; j2++) {
				if (i2 !== shortLen - eccLen || j2 >= numShort) { codewords.push(blocks[j2][i2]); }
			}
		}

		// the grid
		var size = ver * 4 + 17;
		var mod = [], fixed = [];
		for (var y0 = 0; y0 < size; y0++) {
			mod.push(new Array(size).fill(false));
			fixed.push(new Array(size).fill(false));
		}
		function setF(x, y, dark) { mod[y][x] = dark; fixed[y][x] = true; }

		for (var i3 = 0; i3 < size; i3++) { setF(6, i3, i3 % 2 === 0); setF(i3, 6, i3 % 2 === 0); }
		function finder(cx, cy) {
			for (var dy = -4; dy <= 4; dy++) {
				for (var dx = -4; dx <= 4; dx++) {
					var dist = Math.max(Math.abs(dx), Math.abs(dy)), x = cx + dx, y = cy + dy;
					if (x >= 0 && x < size && y >= 0 && y < size) { setF(x, y, dist !== 2 && dist !== 4); }
				}
			}
		}
		finder(3, 3); finder(size - 4, 3); finder(3, size - 4);
		if (ver > 1) {
			var na = Math.floor(ver / 7) + 2;
			var step = Math.floor((ver * 8 + na * 3 + 5) / (na * 4 - 4)) * 2;
			var pos = [6];
			for (var p = size - 7; pos.length < na; p -= step) { pos.splice(1, 0, p); }
			for (var ai = 0; ai < na; ai++) {
				for (var aj = 0; aj < na; aj++) {
					if ((ai === 0 && aj === 0) || (ai === 0 && aj === na - 1) || (ai === na - 1 && aj === 0)) { continue; }
					for (var ey = -2; ey <= 2; ey++) {
						for (var ex = -2; ex <= 2; ex++) {
							setF(pos[ai] + ex, pos[aj] + ey, Math.max(Math.abs(ex), Math.abs(ey)) !== 1);
						}
					}
				}
			}
		}
		function formatBits(mask) {
			var val = FORMAT[ecl] << 3 | mask, rm = val;
			for (var i = 0; i < 10; i++) { rm = (rm << 1) ^ ((rm >>> 9) * 0x537); }
			var fb = (val << 10 | rm) ^ 0x5412;
			for (var i4 = 0; i4 <= 5; i4++) { setF(8, i4, bit(fb, i4)); }
			setF(8, 7, bit(fb, 6)); setF(8, 8, bit(fb, 7)); setF(7, 8, bit(fb, 8));
			for (var i5 = 9; i5 < 15; i5++) { setF(14 - i5, 8, bit(fb, i5)); }
			for (var i6 = 0; i6 < 8; i6++) { setF(size - 1 - i6, 8, bit(fb, i6)); }
			for (var i7 = 8; i7 < 15; i7++) { setF(8, size - 15 + i7, bit(fb, i7)); }
			setF(8, size - 8, true);
		}
		formatBits(0);
		if (ver >= 7) {
			var vr = ver;
			for (var vi = 0; vi < 12; vi++) { vr = (vr << 1) ^ ((vr >>> 11) * 0x1F25); }
			var vb = ver << 12 | vr;
			for (var vk = 0; vk < 18; vk++) {
				var va = size - 11 + vk % 3, vbb = Math.floor(vk / 3);
				setF(va, vbb, bit(vb, vk)); setF(vbb, va, bit(vb, vk));
			}
		}

		// codewords in the zigzag
		for (var right = size - 1, n = 0; right >= 1; right -= 2) {
			if (right === 6) { right = 5; }
			for (var vert = 0; vert < size; vert++) {
				for (var jj = 0; jj < 2; jj++) {
					var x = right - jj, up = ((right + 1) & 2) === 0, y = up ? size - 1 - vert : vert;
					if (!fixed[y][x] && n < codewords.length * 8) {
						mod[y][x] = bit(codewords[n >>> 3], 7 - (n & 7));
						n++;
					}
				}
			}
		}

		function applyMask(m) {
			for (var y = 0; y < size; y++) {
				for (var x = 0; x < size; x++) {
					var inv;
					switch (m) {
						case 0: inv = (x + y) % 2 === 0; break;
						case 1: inv = y % 2 === 0; break;
						case 2: inv = x % 3 === 0; break;
						case 3: inv = (x + y) % 3 === 0; break;
						case 4: inv = (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0; break;
						case 5: inv = x * y % 2 + x * y % 3 === 0; break;
						case 6: inv = (x * y % 2 + x * y % 3) % 2 === 0; break;
						default: inv = ((x + y) % 2 + x * y % 3) % 2 === 0;
					}
					if (!fixed[y][x] && inv) { mod[y][x] = !mod[y][x]; }
				}
			}
		}

		function penalty() {
			var score = 0;
			function addHistory(len, h) { if (h[0] === 0) { len += size; } h.pop(); h.unshift(len); }
			function countPatterns(h) {
				var m = h[1], core = m > 0 && h[2] === m && h[3] === m * 3 && h[4] === m && h[5] === m;
				return (core && h[0] >= m * 4 && h[6] >= m ? 1 : 0) + (core && h[6] >= m * 4 && h[0] >= m ? 1 : 0);
			}
			function line(get) {
				var color = false, run = 0, h = [0, 0, 0, 0, 0, 0, 0];
				for (var i = 0; i < size; i++) {
					if (get(i) === color) {
						run++;
						if (run === 5) { score += 3; } else if (run > 5) { score++; }
					} else {
						addHistory(run, h);
						if (!color) { score += countPatterns(h) * 40; }
						color = get(i);
						run = 1;
					}
				}
				if (color) { addHistory(run, h); run = 0; }
				run += size;
				addHistory(run, h);
				score += countPatterns(h) * 40;
			}
			for (var a = 0; a < size; a++) {
				line(function (i) { return mod[a][i]; });
				line(function (i) { return mod[i][a]; });
			}
			var darkCount = 0;
			for (var y = 0; y < size; y++) {
				for (var x = 0; x < size; x++) {
					if (mod[y][x]) { darkCount++; }
					if (y < size - 1 && x < size - 1) {
						var cc = mod[y][x];
						if (cc === mod[y][x + 1] && cc === mod[y + 1][x] && cc === mod[y + 1][x + 1]) { score += 3; }
					}
				}
			}
			var total = size * size;
			score += (Math.ceil(Math.abs(darkCount * 20 - total * 10) / total) - 1) * 10;
			return score;
		}

		var best = 0, least = Infinity;
		for (var mk = 0; mk < 8; mk++) {
			applyMask(mk);
			formatBits(mk);
			var sc = penalty();
			if (sc < least) { least = sc; best = mk; }
			applyMask(mk);
		}
		applyMask(best);
		formatBits(best);

		return { size: size, dark: function (x, y) { return mod[y][x]; } };
	}

	var modal = document.getElementById('afQrModal');
	if (!modal) { return; }

	var canvas = document.getElementById('afQrCanvas');
	var linkBox = document.getElementById('afQrLink');
	var saveBtn = document.getElementById('afQrSave');
	var shareBtn = document.getElementById('afQrShare');
	var copyBtn = document.getElementById('afQrCopy');
	var FILE = 'digitsell-invite.png';
	var drawn = '';

	function currentLink() {
		var field = document.getElementById('invitelink');
		return field ? field.value.trim() : '';
	}

	// 4 modules of white margin all round - scanners need it to find the code
	function draw(link) {
		if (link === drawn) { return; }
		var qr = dsQrEncode(link);
		if (!qr) { return; }
		var quiet = 4, scale = Math.max(4, Math.floor(1000 / (qr.size + quiet * 2)));
		var dim = (qr.size + quiet * 2) * scale;
		canvas.width = dim;
		canvas.height = dim;
		var ctx = canvas.getContext('2d');
		ctx.fillStyle = '#ffffff';
		ctx.fillRect(0, 0, dim, dim);
		ctx.fillStyle = '#111827';
		for (var y = 0; y < qr.size; y++) {
			for (var x = 0; x < qr.size; x++) {
				if (qr.dark(x, y)) { ctx.fillRect((x + quiet) * scale, (y + quiet) * scale, scale, scale); }
			}
		}
		linkBox.textContent = link;
		drawn = link;
	}

	function withBlob(done) {
		if (canvas.toBlob) {
			canvas.toBlob(function (blob) { done(blob); }, 'image/png');
		} else {
			done(null);
		}
	}

	modal.addEventListener('show.bs.modal', function () { draw(currentLink()); });
	// the same, for a panel build whose modal does not raise Bootstrap events
	document.addEventListener('click', function (event) {
		if (event.target.closest('[data-bs-target="#afQrModal"]')) { draw(currentLink()); }
	});

	saveBtn.addEventListener('click', function () {
		withBlob(function (blob) {
			var a = document.createElement('a');
			a.download = FILE;
			a.href = blob ? URL.createObjectURL(blob) : canvas.toDataURL('image/png');
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
			if (blob) { window.setTimeout(function () { URL.revokeObjectURL(a.href); }, 4000); }
		});
	});

	// phones: hand the picture itself to Telegram, WhatsApp, Instagram...
	var canShareFiles = false;
	try {
		canShareFiles = !!(navigator.share && navigator.canShare && window.File &&
			navigator.canShare({ files: [new File([''], FILE, { type: 'image/png' })] }));
	} catch (e) {}
	if (canShareFiles) {
		shareBtn.hidden = false;
		shareBtn.addEventListener('click', function () {
			withBlob(function (blob) {
				if (!blob) { return; }
				navigator.share({
					files: [new File([blob], FILE, { type: 'image/png' })],
					text: drawn
				}).catch(function () {});
			});
		});
	}

	copyBtn.addEventListener('click', function () {
		var link = drawn || currentLink();
		function done() {
			var label = copyBtn.innerHTML;
			copyBtn.classList.add('aq-done');
			copyBtn.innerHTML = copyBtn.getAttribute('data-done');
			window.setTimeout(function () { copyBtn.classList.remove('aq-done'); copyBtn.innerHTML = label; }, 1800);
		}
		if (navigator.clipboard && window.isSecureContext) {
			navigator.clipboard.writeText(link).then(done, function () {});
			return;
		}
		var area = document.createElement('textarea');
		area.value = link;
		area.setAttribute('readonly', '');
		area.style.position = 'fixed';
		area.style.opacity = '0';
		document.body.appendChild(area);
		area.select();
		try { document.execCommand('copy'); } catch (e) {}
		document.body.removeChild(area);
		done();
	});
})();
</script>
{/literal}
