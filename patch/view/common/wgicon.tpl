{*
  The WireGuard app icon, in the panel's own icon style: an admin writes
  <span class='xmplus xmplus-wireguard fs-15'></span> in the client apps list,
  as for every other app. The panel's xmplus icon font has no WireGuard glyph,
  so this class draws one - the official WireGuard dragon / shield glyph -
  as a mask filled with currentColor, so it takes the same colour as the icons next to it.
  Included from user/layout/style.tpl and admin/layout/footer.tpl.
*}
{literal}
<style>
.xmplus-wireguard::before {
	content: "" !important;
	display: inline-block;
	width: 1em;
	height: 1em;
	vertical-align: -0.125em;
	background-color: currentColor;
	-webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill-rule='evenodd' d='M12 1L3 5v6c0 5.55 3.84 10.74 9 12c5.16-1.26 9-6.45 9-12V5l-9-4zm-1 6.5a1.5 1.5 0 1 1 3 0v2.6a3.5 3.5 0 0 1 1.7 4.9l-1.3-.75a2 2 0 0 0-.9-2.75V15a1.5 1.5 0 1 1-3 0v-1.5a2 2 0 0 0-.9 2.75l-1.3.75a3.5 3.5 0 0 1 1.7-4.9V7.5z'/%3E%3C/svg%3E") center / contain no-repeat;
	mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill-rule='evenodd' d='M12 1L3 5v6c0 5.55 3.84 10.74 9 12c5.16-1.26 9-6.45 9-12V5l-9-4zm-1 6.5a1.5 1.5 0 1 1 3 0v2.6a3.5 3.5 0 0 1 1.7 4.9l-1.3-.75a2 2 0 0 0-.9-2.75V15a1.5 1.5 0 1 1-3 0v-1.5a2 2 0 0 0-.9 2.75l-1.3.75a3.5 3.5 0 0 1 1.7-4.9V7.5z'/%3E%3C/svg%3E") center / contain no-repeat;
}
</style>
{/literal}
