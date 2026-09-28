{*
  Promotion fields for a subscription plan (type 2), included by add.tpl and
  edit.tpl under the prices. None of these inputs has a name, so the encoded
  /admin/plan/save never sees them; promojs.tpl sends them to
  /xmplus-patch.php?do=promo.save after that save has written the list prices.

  $promoedit is the stored entry (Package::promoAdmin) or null. A closed entry
  is not loaded back into the fields: saving again would restart it.
*}
{$pk = 'none'}{$ppct = 20}{$pprize = 0}{$pmode = 'either'}
{$pgbmin = 1}{$pgbmax = 5}{$pdmin = 1}{$pdmax = 7}
{$pocc = ''}{$pends = ''}{$pmax = ''}{$pleft = 0}{$pannounce = 1}{$pchannel = 1}{$ptheme = 'auto'}
{if isset($promoedit) && $promoedit && empty($promoedit.closed_at)}
	{$pk = $promoedit.kind}
	{if $promoedit.percent > 0}{$ppct = $promoedit.percent}{/if}
	{if !empty($promoedit.prize.on)}
		{$pprize = 1}
		{$pmode = $promoedit.prize.mode}
		{if !empty($promoedit.prize.gb_min)}{$pgbmin = $promoedit.prize.gb_min}{/if}
		{if !empty($promoedit.prize.gb_max)}{$pgbmax = $promoedit.prize.gb_max}{/if}
		{if !empty($promoedit.prize.days_min)}{$pdmin = $promoedit.prize.days_min}{/if}
		{if !empty($promoedit.prize.days_max)}{$pdmax = $promoedit.prize.days_max}{/if}
	{/if}
	{$pocc = $promoedit.occasion}
	{* Solar Hijri on Tehran time; an end time already behind us comes back empty (Package::promoAdmin) *}
	{if !empty($promoedit.ends_field)}{$pends = $promoedit.ends_field}{/if}
	{if $promoedit.max_sales > 0}{$pmax = $promoedit.max_sales}{/if}
	{$pleft = $promoedit.show_left}
	{$pannounce = !empty($promoedit.announce)}
	{$pchannel = !empty($promoedit.channel)}
	{if !empty($promoedit.theme)}{$ptheme = $promoedit.theme}{/if}
{/if}
<span id="promobox" hidden>

	<h4 class="mt-4">🏷️ {$translate->get('PromoSection')}</h4>
	<p class="text-muted small mb-3">{$translate->get('PromoSectionHint')}</p>

	{if isset($promoedit) && $promoedit}
		<div class="alert {if $promoedit.running}alert-soft-success{else}alert-soft-secondary{/if} mb-3">
			{if $promoedit.running}
				✅ {$translate->get('PromoStateRunning')}
			{elseif empty($promoedit.closed_at)}
				⏳ {$translate->get('PromoStateClosing')}
			{else}
				🏁 {$translate->get('PromoStateEnded')}
				<bdi>{$promoedit.closed_text}</bdi>
				({$translate->get("PromoReason_{$promoedit.closed_reason}")})
			{/if}
			· {$translate->get('PromoSoldSoFar')}: <b>{$promoedit.sold}</b>{if $promoedit.max_sales > 0} / {$promoedit.max_sales}{/if}
		</div>
	{/if}

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="promo_kind">{$translate->get('PromoKind')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<select class="form-control form-select shadow-lg" id="promo_kind" onchange="promoApply()">
				<option value="none" {if $pk == 'none'}selected{/if}>{$translate->get('PromoKindNone')}</option>
				<option value="discount" {if $pk == 'discount'}selected{/if}>🏷️ {$translate->get('PromoKindDiscount')}</option>
				<option value="special" {if $pk == 'special'}selected{/if}>⭐ {$translate->get('PromoKindSpecial')}</option>
			</select>
		</div>
	</div>

	<span id="promo_discount_fields" hidden>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_percent">{$translate->get('PromoPercent')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="input-group">
					<input type="number" min="1" max="95" class="form-control shadow-lg" id="promo_percent" value="{$ppct}" oninput="promoPreview()">
					<span class="input-group-text">%</span>
				</div>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label">{$translate->get('PromoPreview')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div id="promo_preview" class="d-flex flex-wrap gap-2"></div>
			</div>
		</div>
	</span>

	<div class="row mb-2">
		<label class="col-sm-3 col-form-label form-label" for="promo_prize_on">🎁 {$translate->get('PromoPrize')}</label>
		<div class="col-sm-9" style="max-width: 60rem">
			<div class="form-check form-switch mt-2">
				<input class="form-check-input" type="checkbox" role="switch" id="promo_prize_on" {if $pprize}checked{/if} onchange="promoApply()">
				<label class="form-check-label small text-muted" for="promo_prize_on">{$translate->get('PromoPrizeHint')}</label>
			</div>
		</div>
	</div>

	<span id="promo_prize_fields" hidden>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_prize_mode">{$translate->get('PromoPrizeMode')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<select class="form-control form-select shadow-lg" id="promo_prize_mode" onchange="promoApply()">
					<option value="gb" {if $pmode == 'gb'}selected{/if}>{$translate->get('PromoPrizeModeGb')}</option>
					<option value="days" {if $pmode == 'days'}selected{/if}>{$translate->get('PromoPrizeModeDays')}</option>
					<option value="either" {if $pmode == 'either'}selected{/if}>{$translate->get('PromoPrizeModeEither')}</option>
				</select>
			</div>
		</div>
		<div class="row mb-2" id="promo_gb_row">
			<label class="col-sm-3 col-form-label form-label">{$translate->get('PromoPrizeGb')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="input-group">
					<input type="number" min="1" class="form-control shadow-lg" id="promo_gb_min" value="{$pgbmin}" placeholder="{$translate->get('PromoMin')}">
					<span class="input-group-text">{$translate->get('PromoTo')}</span>
					<input type="number" min="1" class="form-control shadow-lg" id="promo_gb_max" value="{$pgbmax}" placeholder="{$translate->get('PromoMax')}">
					<span class="input-group-text">GB</span>
				</div>
			</div>
		</div>
		<div class="row mb-2" id="promo_days_row">
			<label class="col-sm-3 col-form-label form-label">{$translate->get('PromoPrizeDays')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="input-group">
					<input type="number" min="1" class="form-control shadow-lg" id="promo_days_min" value="{$pdmin}" placeholder="{$translate->get('PromoMin')}">
					<span class="input-group-text">{$translate->get('PromoTo')}</span>
					<input type="number" min="1" class="form-control shadow-lg" id="promo_days_max" value="{$pdmax}" placeholder="{$translate->get('PromoMax')}">
					<span class="input-group-text">{$translate->get('Days')}</span>
				</div>
			</div>
		</div>
	</span>

	<span id="promo_extra_fields" hidden>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_theme">🎨 {$translate->get('PromoTheme')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<select class="form-control form-select shadow-lg" id="promo_theme" onchange="promoThemePicked()">
					<option value="auto" {if $ptheme == 'auto'}selected{/if}>🗓️ {$translate->get('PromoThemeAuto')}</option>
					<optgroup label="{$translate->get('PromoThemeSeasons')}">
						<option value="spring" {if $ptheme == 'spring'}selected{/if}>🌸 {$translate->get('PromoThemeSpring')}</option>
						<option value="summer" {if $ptheme == 'summer'}selected{/if}>☀️ {$translate->get('PromoThemeSummer')}</option>
						<option value="autumn" {if $ptheme == 'autumn'}selected{/if}>🍁 {$translate->get('PromoThemeAutumn')}</option>
						<option value="winter" {if $ptheme == 'winter'}selected{/if}>❄️ {$translate->get('PromoThemeWinter')}</option>
					</optgroup>
					<optgroup label="{$translate->get('PromoThemeOccasions')}">
						<option value="nowruz" {if $ptheme == 'nowruz'}selected{/if}>🌱 {$translate->get('PromoThemeNowruz')}</option>
						<option value="yalda" {if $ptheme == 'yalda'}selected{/if}>🍉 {$translate->get('PromoThemeYalda')}</option>
						<option value="christmas" {if $ptheme == 'christmas'}selected{/if}>🎄 {$translate->get('PromoThemeChristmas')}</option>
						<option value="mother" {if $ptheme == 'mother'}selected{/if}>💐 {$translate->get('PromoThemeMother')}</option>
						<option value="father" {if $ptheme == 'father'}selected{/if}>👔 {$translate->get('PromoThemeFather')}</option>
						<option value="girl" {if $ptheme == 'girl'}selected{/if}>🎀 {$translate->get('PromoThemeGirl')}</option>
						<option value="boy" {if $ptheme == 'boy'}selected{/if}>🧢 {$translate->get('PromoThemeBoy')}</option>
					</optgroup>
					<option value="classic" {if $ptheme == 'classic'}selected{/if}>⭐ {$translate->get('PromoThemeClassic')}</option>
				</select>
				<small class="text-muted">{$translate->get('PromoThemeHint')}</small>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_occasion">📣 {$translate->get('PromoOccasion')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<input type="text" maxlength="300" class="form-control shadow-lg" id="promo_occasion" value="{$pocc|escape:'html'}" placeholder="{$translate->get('PromoOccasionHint')}">
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_ends_at">⏳ {$translate->get('PromoEndsAt')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="promo-ends-wrap">
					<div class="input-group">
						<input type="text" inputmode="numeric" maxlength="16" class="form-control shadow-lg" id="promo_ends_at" value="{$pends}" placeholder="1405/07/30 23:59" dir="ltr" autocomplete="off">
						<button type="button" class="btn btn-soft-primary" id="promo_cal_open" onclick="promoCalToggle()" title="{$translate->get('PromoCalOpen')}">📅</button>
					</div>
					{* the Solar Hijri calendar (promojs.tpl draws it) *}
					<div id="promo_cal" class="promo-cal shadow-lg" hidden></div>
				</div>
				<div class="promo-ends-span mt-2">
					<span>⏱️ {$translate->get('PromoEndsOr')}</span>
					<input type="number" min="0" max="365" class="form-control form-control-sm" id="promo_ends_days" placeholder="2" dir="ltr">
					<span>{$translate->get('PromoEndsDaysUntil')}</span>
					<input type="time" class="form-control form-control-sm" id="promo_ends_hour" value="23:59" dir="ltr">
				</div>
				<div id="promo_ends_note" class="small fw-semibold mt-1" hidden></div>
				<small class="text-muted">{$translate->get('PromoEndsAtHint')}</small>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_max_sales">🔢 {$translate->get('PromoMaxSales')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<input type="number" min="0" class="form-control shadow-lg" id="promo_max_sales" value="{$pmax}" placeholder="{$translate->get('PromoMaxSalesHint')}">
				<div class="form-check mt-2">
					<input class="form-check-input" type="checkbox" id="promo_show_left" {if $pleft}checked{/if}>
					<label class="form-check-label" for="promo_show_left">{$translate->get('PromoShowLeft')}</label>
				</div>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_announce">📢 {$translate->get('PromoAnnounce')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="form-check form-switch mt-2">
					<input class="form-check-input" type="checkbox" role="switch" id="promo_announce" {if $pannounce}checked{/if}>
					<label class="form-check-label small text-muted" for="promo_announce">{$translate->get('PromoAnnounceHint')}</label>
				</div>
			</div>
		</div>
		<div class="row mb-2">
			<label class="col-sm-3 col-form-label form-label" for="promo_channel">📣 {$translate->get('PromoChannel')}</label>
			<div class="col-sm-9" style="max-width: 60rem">
				<div class="form-check form-switch mt-2">
					<input class="form-check-input" type="checkbox" role="switch" id="promo_channel" {if $pchannel}checked{/if}>
					<label class="form-check-label small text-muted" for="promo_channel">{$translate->get('PromoChannelHint')}</label>
				</div>
			</div>
		</div>
	</span>

</span>
