					<option value="auto" {if $selectedtheme == 'auto'}selected{/if}>🗓️ {$translate->get('PromoThemeAuto')}</option>
					<optgroup label="{$translate->get('PromoThemeSeasons')}">
						<option value="spring" {if $selectedtheme == 'spring'}selected{/if}>🌸 {$translate->get('PromoThemeSpring')}</option>
						<option value="summer" {if $selectedtheme == 'summer'}selected{/if}>☀️ {$translate->get('PromoThemeSummer')}</option>
						<option value="autumn" {if $selectedtheme == 'autumn'}selected{/if}>🍁 {$translate->get('PromoThemeAutumn')}</option>
						<option value="winter" {if $selectedtheme == 'winter'}selected{/if}>❄️ {$translate->get('PromoThemeWinter')}</option>
					</optgroup>
					<optgroup label="{$translate->get('PromoThemeOccasions')}">
						<option value="nowruz" {if $selectedtheme == 'nowruz'}selected{/if}>🌱 {$translate->get('PromoThemeNowruz')}</option>
						<option value="yalda" {if $selectedtheme == 'yalda'}selected{/if}>🍉 {$translate->get('PromoThemeYalda')}</option>
						<option value="christmas" {if $selectedtheme == 'christmas'}selected{/if}>🎄 {$translate->get('PromoThemeChristmas')}</option>
						<option value="mother" {if $selectedtheme == 'mother'}selected{/if}>💐 {$translate->get('PromoThemeMother')}</option>
						<option value="father" {if $selectedtheme == 'father'}selected{/if}>👔 {$translate->get('PromoThemeFather')}</option>
						<option value="girl" {if $selectedtheme == 'girl'}selected{/if}>🎀 {$translate->get('PromoThemeGirl')}</option>
						<option value="boy" {if $selectedtheme == 'boy'}selected{/if}>🧢 {$translate->get('PromoThemeBoy')}</option>
					</optgroup>
					<optgroup label="{$translate->get('PromoThemeCultural')|escape:'html'}">
						<option value="attar" {if $selectedtheme == 'attar'}selected{/if}>🪶 {$translate->get('PromoThemeAttar')}</option>
						<option value="saadi" {if $selectedtheme == 'saadi'}selected{/if}>🌹 {$translate->get('PromoThemeSaadi')}</option>
						<option value="ferdowsi" {if $selectedtheme == 'ferdowsi'}selected{/if}>📜 {$translate->get('PromoThemeFerdowsi')}</option>
						<option value="khayyam" {if $selectedtheme == 'khayyam'}selected{/if}>🌌 {$translate->get('PromoThemeKhayyam')}</option>
						<option value="avicenna" {if $selectedtheme == 'avicenna'}selected{/if}>🩺 {$translate->get('PromoThemeAvicenna')}</option>
						<option value="razi" {if $selectedtheme == 'razi'}selected{/if}>⚗️ {$translate->get('PromoThemeRazi')}</option>
						<option value="rumi" {if $selectedtheme == 'rumi'}selected{/if}>🌀 {$translate->get('PromoThemeRumi')}</option>
						<option value="hafez" {if $selectedtheme == 'hafez'}selected{/if}>📖 {$translate->get('PromoThemeHafez')}</option>
						<option value="cyrus" {if $selectedtheme == 'cyrus'}selected{/if}>🏛️ {$translate->get('PromoThemeCyrus')}</option>
					</optgroup>
					<optgroup label="{$translate->get('PromoThemeWeather')|escape:'html'}">
						<option value="rainy" {if $selectedtheme == 'rainy'}selected{/if}>🌧️ {$translate->get('PromoThemeRainy')}</option>
						<option value="autumn_rain" {if $selectedtheme == 'autumn_rain'}selected{/if}>🍂 {$translate->get('PromoThemeAutumnRain')}</option>
						<option value="walking" {if $selectedtheme == 'walking'}selected{/if}>🚶 {$translate->get('PromoThemeWalking')}</option>
						<option value="winter_snow" {if $selectedtheme == 'winter_snow'}selected{/if}>🌨️ {$translate->get('PromoThemeWinterSnow')}</option>
						<option value="rainbow" {if $selectedtheme == 'rainbow'}selected{/if}>🌈 {$translate->get('PromoThemeRainbow')}</option>
					</optgroup>
					<option value="classic" {if $selectedtheme == 'classic'}selected{/if}>⭐ {$translate->get('PromoThemeClassic')}</option>
