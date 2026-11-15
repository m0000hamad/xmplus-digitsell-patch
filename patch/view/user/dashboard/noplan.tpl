{literal}
<style>
.dash-noplan { display: flex; align-items: center; justify-content: space-between; gap: 20px; margin-bottom: 16px; padding: 20px 22px; border: 1px solid rgba(99, 102, 241, .18); border-radius: 18px; background: linear-gradient(135deg, rgba(99, 102, 241, .09), rgba(139, 92, 246, .04)); box-shadow: 0 10px 28px rgba(79, 70, 229, .08); }
.dash-noplan-copy { display: flex; align-items: center; gap: 14px; min-width: 0; }
.dash-noplan-icon { display: inline-flex; align-items: center; justify-content: center; width: 50px; height: 50px; flex: 0 0 auto; border-radius: 16px; font-size: 24px; background: #fff; box-shadow: 0 7px 18px rgba(99, 102, 241, .13); }
.dash-noplan h2 { margin: 0 0 4px; font-size: 18px; font-weight: 900; color: #16203d; }
.dash-noplan p { margin: 0; font-size: 12.5px; line-height: 1.8; color: #66738d; }
.dash-noplan-btn { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 44px; padding: 10px 22px; border-radius: 13px; font-size: 13px; font-weight: 900; white-space: nowrap; text-decoration: none !important; color: #fff !important; background: linear-gradient(135deg, #4f46e5, #7c3aed); box-shadow: 0 8px 20px rgba(99, 102, 241, .3); }
html[data-hs-theme="dark"] .dash-noplan { background: rgba(99, 102, 241, .12); border-color: rgba(129, 140, 248, .25); }
html[data-hs-theme="dark"] .dash-noplan-icon { background: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .dash-noplan h2 { color: #e7eaf3; }
html[data-hs-theme="dark"] .dash-noplan p { color: #aab6cc; }
@media (max-width: 575.98px) { .dash-noplan { align-items: stretch; flex-direction: column; padding: 17px; } .dash-noplan-btn { width: 100%; } }
</style>
{/literal}
<section class="dash-noplan">
	<div class="dash-noplan-copy"><span class="dash-noplan-icon">🛡️</span><div><h2>{$translate->get('DashNoPlanTitle')}</h2><p>{$translate->get('DashNoPlanText')}</p></div></div>
	<a class="dash-noplan-btn" href="/portal/plans">🛒 {$translate->get('OrderApaln')}</a>
</section>
