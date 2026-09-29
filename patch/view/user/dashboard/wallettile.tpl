{*
 * The wallet tile in the subscription card, where the balance tile used to be -
 * the way operator apps put the balance next to the package. Included by
 * subsciption.tpl when the pay-as-you-go wallet is switched on. Everything
 * else about the wallet lives in the side panel, user/dashboard/wallet.tpl,
 * which any [data-wallet-open] element opens.
 *}
{$wMode = $user->paygMode()}
{$wGb = $user->paygHeadroomGb()}
<div class="sub-tile sub-wallet{if $wMode == 'balance'} is-balance{elseif $wMode == 'empty'} is-empty{/if}" style="--tile:{if $wMode == 'empty'}#f43f5e{elseif $wMode == 'balance'}#f59e0b{else}#10b981{/if}">
	<div class="sub-tile-head">
		<span class="sub-tile-emoji">💳</span>{$translate->get('PaygWallet')}
		{if $user->paygUnseen() > 0}<span class="sub-wallet-dot" title="{$translate->get('PaygUnseenHint')}"></span>{/if}
		<button type="button" class="sub-wallet-more" data-wallet-open="history">{$translate->get('PaygDetails')} ‹</button>
	</div>
	<div class="sub-wallet-value">
		<bdi>{$user->paygBalanceShown()}</bdi>
		<small>{if $user->paygToman()}{$translate->get('PaygToman')}{else}{$translate->get('PaygRial')}{/if}</small>
	</div>
	<div class="sub-tile-note">
		{if $wGb === null}
			♾️ {$translate->get('PaygUnlimited')}
		{else}
			📶 {$translate->get('PaygAboutGb')|replace:'%gb%':$wGb}
		{/if}
		{if $user->commissionWalletEnabled() && $user->commissionWalletBalance() > 0}
			<br>🤝 {$translate->get('PaygCommissionShort')}: <bdi>{number_format((float)$user->commissionWalletBalance(), (int){$currency->decimals})}</bdi>
		{/if}
		{if (float)$user->money > 0}
			<br>💰 {$translate->get('PaygPanelMoney')}: <bdi>{number_format((float)$user->money, (int){$currency->decimals})}</bdi>
		{/if}
	</div>
	<div class="sub-wallet-actions">
		<button type="button" class="sub-wallet-add" data-wallet-open="charge">➕ {$translate->get('PaygAddFunds')}</button>
	</div>
</div>
