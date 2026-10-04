{*
  One WireGuard server row: status dot, name, and its file. Shared by wg.tpl
  and wgapp.tpl. Parameter: node - an entry of User::wgNodes().
*}
<li class="wg-server">
	<span class="wg-dot{if !$node.live} is-down{/if}" title="{if $node.live}{$translate->get('WgServerUp')}{else}{$translate->get('WgServerDown')}{/if}"></span>
	<span class="wg-server-name">{$node.name}</span>
	<span class="wg-proto is-static">{$translate->get('WgUdp')}</span>
	<a class="wg-get" href="/xmplus-patch.php?do=wg.profile&amp;node={$node.id}" download title="{$translate->get('WgFileHint')}">⬇️ {$translate->get('WgDownload')}</a>
</li>