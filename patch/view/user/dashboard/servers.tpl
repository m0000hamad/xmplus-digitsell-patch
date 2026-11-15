		<div class="col-lg-12 col-xl-6 col-md-12 col-sm-12 mb-3">
			<div class="card card-shadow shadow-lg rounded usage-card">
				<div class="card-header card-header-content-between border-bottom">
					<h4 class="card-header-title mb-0">{$translate->get('ServerUsage')}</h4>
					<span class="usage-badge" id="usageServerRangeLabel">{$translate->get('RangeDay')}</span>
				</div>

				<div class="card-body py-2">
					<div class="usage-servers-list" id="usageServerList"></div>
					{include file='user/dashboard/onlinepeople.tpl'}
				</div>
			</div>
		</div>
