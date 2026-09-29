{*
 * The top of the subscription card while the account runs on its wallet.
 *
 * On the wallet the billing job keeps expire_in a day ahead and the quota at
 * what the balance buys, so the plan's own status, name, traffic chip and
 * "1 day left" clock would all mislead. This says what is really going on,
 * the way an operator app says "no package - paying from your credit".
 * Included by subsciption.tpl instead of those parts.
 *}
{$wMode = $user->paygMode()}
{$wGb = $user->paygHeadroomGb()}
<span class="sub-status sub-status-wallet{if $wMode == 'empty'} is-empty{/if}">
	<span class="sub-dot"></span>
	{if $wMode == 'empty'}{$translate->get('PaygModeEmpty')}{else}{$translate->get('PaygStateBalance')}{/if}
</span>

<h4 class="sub-name">{if $wMode == 'empty'}⛔ {$translate->get('PaygStateNameEmpty')}{else}⚡ {$translate->get('PaygStateNameBalance')}{/if}</h4>

<div class="sub-chips">
	<span class="sub-chip">💳 <bdi>{$user->paygBalanceShown()}</bdi> {if $user->paygToman()}{$translate->get('PaygToman')}{else}{$translate->get('PaygRial')}{/if}</span>
	{if $wGb === null}
		<span class="sub-chip">♾️ {$translate->get('PaygUnlimited')}</span>
	{else}
		<span class="sub-chip">📶 {$translate->get('PaygAboutGb')|replace:'%gb%':$wGb}</span>
	{/if}
</div>

<div class="sub-clock sub-wallet-clock{if $wMode == 'empty'} is-empty{/if}">
	<div class="sub-wallet-text">{if $wMode == 'empty'}{$translate->get('PaygStateTextEmpty')}{else}{$translate->get('PaygStateTextBalance')}{/if}</div>
	<div class="sub-mood">💡 {$translate->get('PaygStateHint')}</div>
</div>
