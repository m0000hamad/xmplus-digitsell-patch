{*
  Step 3 of the apps card for a WireGuard app. Included by application.tpl in
  place of the subscription link when the client's name contains "WireGuard"
  (added by the admin in the panel's own client apps list, which is where its
  download link, icon and guide are edited). Parameter: app - the client row.
  WireGuard does not read the subscription link: it needs a .conf file, which
  carries the account's own keys (app/Patch/Wg.php), so there is no username
  or password to show.
*}
{include file='user/dashboard/wgstyle.tpl'}

<div class="app-step">
	<div class="app-step-head">
		<span class="app-step-num">3</span>
		<div>
			<h5 class="app-step-title">{$translate->get('InstallConnect')}</h5>
			<span class="app-step-sub">{$translate->get('WgAppHint')}</span>
		</div>
	</div>

	<div class="app-connect">
		{if $user->wgEnabled()}
			<ul class="wg-servers mb-3">
				{foreach $user->wgNodes() as $wgNode}
					{include file='user/dashboard/wgnode.tpl' node=$wgNode}
				{/foreach}
			</ul>
		{else}
			<p class="wg-note">{$translate->get('WgNoServer')}</p>
		{/if}

		<div class="app-actions">
			<a class="app-btn app-btn-get" href="{$app->url}" target="_blank" rel="noopener">⬇️ {$translate->get('Download')} {$app->client}</a>
			{if $app->uuid || $app->uuid != 0}
				<a class="app-btn app-btn-help" href="/portal/knowledgebase/{$app->uuid}">📖 {$translate->get('Instruction')}</a>
			{/if}
		</div>

		<ol class="wg-steps">
			<li>{$translate->get('WgHow1')}</li>
			<li>{$translate->get('WgHow2')}</li>
			<li>{$translate->get('WgHow3')}</li>
		</ol>
		<p class="wg-note">{$translate->get('WgResetNote')}</p>
	</div>
</div>