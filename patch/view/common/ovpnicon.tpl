{*
  The OpenVPN app icon, in the panel's own icon style: an admin writes
  <span class='xmplus xmplus-openvpn fs-15'></span> in the client apps list,
  as for every other app. The panel's xmplus icon font has no OpenVPN glyph,
  so this class draws one - a circle with a keyhole - as a mask filled with
  the text colour, so it takes the same colour as the icons next to it.
  Included from user/layout/style.tpl and admin/layout/footer.tpl.
*}
{literal}
<style>
.xmplus-openvpn::before {
	content: "" !important;
	display: inline-block;
	width: 1em;
	height: 1em;
	vertical-align: -0.125em;
	background-color: currentColor;
	-webkit-mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill-rule='evenodd' d='M1 12a11 11 0 1 0 22 0a11 11 0 1 0-22 0zM13.8 12.72A3.6 3.6 0 1 0 10.2 12.72L8.9 18.5h6.2z'/%3E%3C/svg%3E") center / contain no-repeat;
	mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill-rule='evenodd' d='M1 12a11 11 0 1 0 22 0a11 11 0 1 0-22 0zM13.8 12.72A3.6 3.6 0 1 0 10.2 12.72L8.9 18.5h6.2z'/%3E%3C/svg%3E") center / contain no-repeat;
}
</style>
{/literal}
