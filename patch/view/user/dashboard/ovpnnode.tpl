{*
  One OpenVPN server row: status dot, name, and its file(s). Shared by
  ovpn.tpl and ovpnapp.tpl. Parameter: node - an entry of User::ovpnNodes().
  With both protocols on offer, the main button gets the file that carries
  both (UDP first, TCP where UDP is blocked) and UDP / TCP get their own.
*}
<li class="ovpn-server">
	<span class="ovpn-dot{if !$node.live} is-down{/if}" title="{if $node.live}{$translate->get('OvpnServerUp')}{else}{$translate->get('OvpnServerDown')}{/if}"></span>
	<span class="ovpn-server-name">{$node.name}</span>
	{if count($node.protos) > 1}
		{foreach $node.protos as $proto}
			<a class="ovpn-proto" href="/xmplus-patch.php?do=ovpn.profile&amp;node={$node.id}&amp;proto={$proto}" download title="{$translate->get('OvpnProtoOnly')} {$proto|upper}">{$proto|upper}</a>
		{/foreach}
		<a class="ovpn-get" href="/xmplus-patch.php?do=ovpn.profile&amp;node={$node.id}&amp;proto=both" download title="{$translate->get('OvpnBothHint')}">⬇️ {$translate->get('OvpnDownload')}</a>
	{else}
		<span class="ovpn-proto is-static">{$node.protos[0]|upper}</span>
		<a class="ovpn-get" href="/xmplus-patch.php?do=ovpn.profile&amp;node={$node.id}" download>⬇️ {$translate->get('OvpnDownload')}</a>
	{/if}
</li>
