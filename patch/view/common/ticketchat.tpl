{literal}
<style>
.tk-thread {
	height: 26rem;
	overflow-y: auto;
	overscroll-behavior: contain;
	padding-inline-end: 6px;
}
.tk-thread::-webkit-scrollbar { width: 6px; }
.tk-thread::-webkit-scrollbar-thumb {
	background: rgba(23, 32, 61, .18);
	border-radius: 999px;
}
.tk-msg {
	display: flex;
	flex-direction: column;
	margin-bottom: 14px;
	max-width: 100%;
}
/* the sender's own messages sit on the right in both directions, the way a
   chat app does it - in an RTL page the start edge is already the right one */
.tk-msg.tk-mine { align-items: flex-end; }
.tk-msg.tk-theirs { align-items: flex-start; }
.tk-rtl .tk-msg.tk-mine { align-items: flex-start; }
.tk-rtl .tk-msg.tk-theirs { align-items: flex-end; }
.tk-meta {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	font-size: 11px;
	font-weight: 600;
	color: #5c6b8a;
	margin-bottom: 5px;
	padding: 0 4px;
}
.tk-meta time {
	direction: ltr;
	unicode-bidi: isolate;
	font-weight: 500;
	opacity: .78;
}
.tk-who {
	display: inline-flex;
	align-items: center;
	gap: 4px;
}
.tk-who::before {
	content: "";
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: currentColor;
}
.tk-mine .tk-who { color: #4f46e5; }
.tk-theirs .tk-who { color: #0f9d8c; }
.tk-msg.tk-theirs .tk-meta { text-align: start; }
.tk-bubble {
	position: relative;
	width: fit-content;
	min-width: 92px;
	max-width: min(85%, 640px);
	padding: 11px 15px;
	border-radius: 16px;
	font-size: 13.5px;
	line-height: 1.85;
	/* the whole point: keep the line breaks and the spacing the sender typed */
	white-space: pre-wrap;
	overflow-wrap: anywhere;
	word-break: break-word;
}
.tk-mine .tk-bubble {
	background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
	color: #fff;
	border-end-end-radius: 5px;
}
.tk-theirs .tk-bubble {
	background: #eef1f7;
	color: #16203d;
	border: 1px solid rgba(23, 32, 61, .07);
	border-end-start-radius: 5px;
}
.tk-link {
	text-decoration: underline;
	text-underline-offset: 2px;
	word-break: break-all;
}
.tk-mine .tk-link { color: #e0e7ff; }
.tk-theirs .tk-link { color: #4f46e5; }
.tk-bubble.tk-sticker {
	background: none !important;
	padding: 0 4px;
	font-size: 44px;
	line-height: 1.25;
	box-shadow: none;
}
.tk-file {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	margin-top: 8px;
	padding: 6px 10px;
	border-radius: 10px;
	font-size: 12px;
	text-decoration: none;
	max-width: 100%;
}
.tk-file span {
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}
.tk-mine .tk-file { background: rgba(255, 255, 255, .16); color: #fff; }
.tk-theirs .tk-file { background: rgba(23, 32, 61, .06); color: #16203d; }

/* ---- composer ---- */
.tk-composer { position: relative; }
.tk-composer textarea {
	resize: vertical;
	min-height: 76px;
	line-height: 1.8;
}
.tk-tools {
	display: flex;
	align-items: center;
	flex-wrap: wrap;
	gap: 8px;
	margin-top: 8px;
}
.tk-tool {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	border: 1px solid rgba(23, 32, 61, .12);
	background: transparent;
	color: #5c6b8a;
	border-radius: 999px;
	padding: 6px 12px;
	font-size: 12px;
	font-weight: 600;
	line-height: 1;
	cursor: pointer;
	transition: background .15s ease, color .15s ease, border-color .15s ease;
}
.tk-tool:hover { background: rgba(99, 102, 241, .09); color: #4f46e5; border-color: rgba(99, 102, 241, .3); }
.tk-tool.tk-on { background: rgba(99, 102, 241, .12); color: #4f46e5; border-color: rgba(99, 102, 241, .35); }
.tk-hint { font-size: 11px; color: #97a4af; margin-inline-start: auto; }

/* ---- emoji panel ---- */
.tk-emoji-panel {
	position: absolute;
	bottom: calc(100% + 8px);
	inset-inline-start: 0;
	z-index: 30;
	width: min(310px, calc(100vw - 40px));
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .1);
	border-radius: 14px;
	box-shadow: 0 12px 34px rgba(23, 32, 61, .16);
	padding: 10px;
	display: none;
}
.tk-emoji-panel.tk-open { display: block; }
.tk-emoji-title {
	font-size: 11px;
	font-weight: 600;
	color: #97a4af;
	margin: 2px 2px 6px;
}
.tk-emoji-grid {
	display: grid;
	grid-template-columns: repeat(8, 1fr);
	gap: 2px;
	max-height: 190px;
	overflow-y: auto;
}
.tk-emoji-grid.tk-stickers {
	grid-template-columns: repeat(6, 1fr);
	max-height: none;
	margin-bottom: 8px;
	padding-bottom: 8px;
	border-bottom: 1px solid rgba(23, 32, 61, .08);
}
.tk-emoji-btn {
	border: 0;
	background: transparent;
	border-radius: 8px;
	padding: 4px 0;
	font-size: 19px;
	line-height: 1.4;
	cursor: pointer;
}
.tk-stickers .tk-emoji-btn { font-size: 28px; }
.tk-emoji-btn:hover { background: rgba(99, 102, 241, .12); }

html[data-hs-theme="dark"] .tk-theirs .tk-bubble {
	background: rgba(255, 255, 255, .07);
	border-color: rgba(255, 255, 255, .09);
	color: #e7eaf3;
}
html[data-hs-theme="dark"] .tk-mine .tk-who { color: #a5b4fc; }
html[data-hs-theme="dark"] .tk-theirs .tk-who { color: #5eead4; }
html[data-hs-theme="dark"] .tk-theirs .tk-link { color: #a5b4fc; }
html[data-hs-theme="dark"] .tk-theirs .tk-file { background: rgba(255, 255, 255, .1); color: #e7eaf3; }
html[data-hs-theme="dark"] .tk-meta { color: #b6c4dc; }
html[data-hs-theme="dark"] .tk-hint { color: #8b9ab5; }
html[data-hs-theme="dark"] .tk-tool { border-color: rgba(255, 255, 255, .14); color: #9fb0cc; }
html[data-hs-theme="dark"] .tk-emoji-panel {
	background: #1c2540;
	border-color: rgba(255, 255, 255, .12);
	box-shadow: 0 12px 34px rgba(0, 0, 0, .45);
}
html[data-hs-theme="dark"] .tk-emoji-grid.tk-stickers { border-bottom-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .tk-thread::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, .18); }

@media (max-width: 575.98px) {
	.tk-thread { height: 22rem; }
	.tk-bubble { max-width: 92%; font-size: 13px; padding: 10px 13px; }
	.tk-bubble.tk-sticker { font-size: 38px; }
	.tk-tool { padding: 6px 10px; font-size: 11.5px; }
	.tk-hint { display: none; }
}
</style>

<script>
window.TicketChat = (function () {
	var STICKERS = ['👍', '🙏', '✅', '❤️', '🔥', '😊', '🎉', '👌', '😅', '🤝', '⚡', '💡'];
	var EMOJI = [
		'😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
		'🙂', '😉', '😊', '😍', '🥰', '😘', '😋', '😎',
		'🤗', '🤔', '🤨', '😐', '😑', '🙄', '😏', '😴',
		'😪', '😮', '😯', '😢', '😭', '😤', '😠', '🤯',
		'😳', '🥵', '🥶', '😱', '🤗', '🤭', '🤫', '😬',
		'👍', '👎', '👌', '🤝', '🙏', '👏', '🙌', '💪',
		'✌️', '🤞', '👋', '☝️', '✋', '🖐️', '👉', '👈',
		'❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💯',
		'✅', '❌', '⚠️', '❗', '❓', '💬', '📌', '📎',
		'🔥', '⭐', '✨', '🎉', '🎁', '🏆', '⚡', '💡',
		'🚀', '🛠️', '⚙️', '🔒', '🔑', '🌐', '📡', '🖥️',
		'💻', '📱', '⌛', '⏰', '📅', '📈', '📉', '💳'
	];

	function buildPanel(textarea) {
		var panel = document.createElement('div');
		panel.className = 'tk-emoji-panel';

		var stickerTitle = document.createElement('div');
		stickerTitle.className = 'tk-emoji-title';
		stickerTitle.textContent = window.TicketChatI18n ? window.TicketChatI18n.stickers : 'Stickers';
		panel.appendChild(stickerTitle);

		var stickerGrid = document.createElement('div');
		stickerGrid.className = 'tk-emoji-grid tk-stickers';
		STICKERS.forEach(function (char) { stickerGrid.appendChild(makeButton(char, textarea, true)); });
		panel.appendChild(stickerGrid);

		var emojiTitle = document.createElement('div');
		emojiTitle.className = 'tk-emoji-title';
		emojiTitle.textContent = window.TicketChatI18n ? window.TicketChatI18n.emoji : 'Emoji';
		panel.appendChild(emojiTitle);

		var grid = document.createElement('div');
		grid.className = 'tk-emoji-grid';
		EMOJI.forEach(function (char) { grid.appendChild(makeButton(char, textarea, false)); });
		panel.appendChild(grid);

		return panel;
	}

	function makeButton(char, textarea, isSticker) {
		var button = document.createElement('button');
		button.type = 'button';
		button.className = 'tk-emoji-btn';
		button.textContent = char;
		button.addEventListener('click', function () {
			insert(textarea, char, isSticker);
		});
		return button;
	}

	function insert(textarea, text, replaceAll) {
		if (replaceAll && textarea.value.trim() === '') {
			textarea.value = text;
		} else {
			var start = textarea.selectionStart;
			var end = textarea.selectionEnd;
			if (typeof start === 'number') {
				textarea.value = textarea.value.slice(0, start) + text + textarea.value.slice(end);
				textarea.selectionStart = textarea.selectionEnd = start + text.length;
			} else {
				textarea.value += text;
			}
		}
		textarea.focus();
	}

	function attachEmoji(button, textarea) {
		if (!button || !textarea) { return; }

		var panel = buildPanel(textarea);
		button.parentNode.appendChild(panel);

		button.addEventListener('click', function (event) {
			event.stopPropagation();
			panel.classList.toggle('tk-open');
		});

		panel.addEventListener('click', function (event) { event.stopPropagation(); });

		document.addEventListener('click', function () { panel.classList.remove('tk-open'); });
		document.addEventListener('keydown', function (event) {
			if (event.key === 'Escape') { panel.classList.remove('tk-open'); }
		});
	}

	function scrollToBottom(thread) {
		if (thread) { thread.scrollTop = thread.scrollHeight; }
	}

	return {
		attachEmoji: attachEmoji,
		insert: insert,
		scrollToBottom: scrollToBottom
	};
})();
</script>
{/literal}
