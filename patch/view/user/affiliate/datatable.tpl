			<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
				<div class="card card-shadow shadow-lg rounded">
					<div class="card-header card-header-content-between border-bottom">
						<h4 class="page-header-title">{$translate->get('RebateRec')}</h4>

					</div>
					<div class="card-body">
						<div class="tab-pane fade show active" id="rebate" role="tabpanel" aria-labelledby="rebate-tab">
							{include file='table/columns.tpl'}
							<div class="table-responsive">
								{include file='table/datatable.tpl'}								
							</div>
						</div>
					</div>
				</div>
			</div>