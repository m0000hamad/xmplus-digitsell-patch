	<div class="row match-height">
		<div class="col-12 mb-3 mb-lg-5">
			<div class="card card-shadow shadow-lg rounded usage-card">
				<div class="card-header card-header-content-between border-bottom">
					<h4 class="card-header-title mb-0">{$translate->get('ServerUsage')}</h4>
					<span class="usage-badge" id="usageServerRangeLabel">{$translate->get('RangeDay')}</span>
				</div>

				<div class="card-body">
					<div class="row align-items-center">
						<div class="col-lg-5 col-md-12 mb-3 mb-lg-0">
							<div id="usageDonut" style="min-height:260px"></div>
						</div>
						<div class="col-lg-7 col-md-12">
							<div class="usage-servers-list" id="usageServerList"></div>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
