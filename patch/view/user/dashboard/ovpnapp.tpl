{*
  Step 3 of the apps card for an OpenVPN app. Included by application.tpl in
  place of the subscription link when the client's name contains "OpenVPN"
  (added by the admin in the panel's own client apps list, which is where its
  download link, icon and guide are edited). Parameter: app - the client row.
  OpenVPN does not read the subscription link: it needs a server file and the
  account's OpenVPN username / password (app/Patch/Ovpn.php).
*}
{include file='user/dashboard/ovpnstyle.tpl'}

<div class="app-step">
	<div class="app-step-head">
		<span class="app-step-num">3</span>
		<div>
			<h5 class="app-step-title">{$translate->get('InstallConnect')}</h5>
			<span class="app-step-sub">{$translate->get('OvpnAppHint')}</span>
		</div>
	</div>

	<div class="app-connect">
		{if $user->ovpnEnabled()}
			<ul class="ovpn-servers mb-3">
				{foreach $user->ovpnNodes() as $ovpnNode}
					{include file='user/dashboard/ovpnnode.tpl' node=$ovpnNode}
				{/foreach}
			</ul>

			<div class="ovpn-cred">
				<span class="ovpn-cred-label">{$translate->get('OvpnUsername')}</span>
				<span class="ovpn-cred-value">{$user->ovpnLogin()}</span>
				<button type="button" class="ovpn-icon-btn copy-text" data-clipboard-text="{$user->ovpnLogin()}" title="{$translate->get('OvpnCopy')}"><i class="fa-regular fa-copy"></i></button>
			</div>
			<div class="ovpn-cred">
				<span class="ovpn-cred-label">{$translate->get('OvpnPassword')}</span>
				<span class="ovpn-cred-value" data-ovpn-pass="{$user->ovpnPassword()}">••••••••••••</span>
				<button type="button" class="ovpn-icon-btn" data-ovpn-show title="{$translate->get('OvpnShow')}"><i class="fa-regular fa-eye"></i></button>
				<button type="button" class="ovpn-icon-btn copy-text" data-clipboard-text="{$user->ovpnPassword()}" title="{$translate->get('OvpnCopy')}"><i class="fa-regular fa-copy"></i></button>
			</div>
		{else}
			<p class="ovpn-note mb-3">{$translate->get('OvpnAppOff')}</p>
		{/if}

		<div class="app-actions">
			<a class="app-btn app-btn-get" href="{$app->url}" target="_blank" rel="noopener">⬇️ {$translate->get('Download')} {$app->client}</a>
			{if $app->uuid || $app->uuid != 0}
				<a class="app-btn app-btn-help" href="/portal/knowledgebase/{$app->uuid}">📖 {$translate->get('Instruction')}</a>
			{/if}
		</div>

		{if $user->ovpnEnabled()}
			<div class="app-howto">
				<div class="app-howto-item"><span class="app-howto-emoji">⬇️</span><span>{$translate->get('OvpnAppStep1')}</span></div>
				<div class="app-howto-item"><span class="app-howto-emoji">📂</span><span>{$translate->get('OvpnHow1')}</span></div>
				<div class="app-howto-item"><span class="app-howto-emoji">🔑</span><span>{$translate->get('OvpnHow2')}</span></div>
			</div>
			<p class="ovpn-note mb-0">{$translate->get('OvpnResetNote')}</p>
		{/if}
	</div>
</div>
