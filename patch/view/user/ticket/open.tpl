  <div class="modal fade" id="add_ticket" tabindex="-1" aria-labelledby="add_ticket" role="dialog" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
      <div class="modal-content">

        <div class="modal-header">
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
			
			<div class="card-body ">
				<div class="form-group mb-3">
					<div class="row align-items-center">
						<label class="col-xl-2 form-label">{$translate->get('Department')}</label>
						<div class="col-xl-10 text-dark tom-select-custom ">
								<select class="js-select form-select shadow-lg" autocomplete="off" id="department" name="department"
										data-hs-tom-select-options='{
										  "hideSearch": true
										}' >
									<option value="other" selected>{$translate->get('GeneralDept')}</option>
									<option value="billing">{$translate->get('BillingDept')}</option>
									<option value="data">{$translate->get('DataDept')}</option>
									<option value="configuration">{$translate->get('ConfigDept')}</option>
									<option value="refund">{$translate->get('RefundDept')}</option>
							</select>
						</div>
					</div>
				</div>
				<div class="form-group mb-3">
					<div class="row align-items-center">
						<label class="col-xl-2 form-label">{$translate->get('Subject')}</label>
						<div class="col-xl-10">
							<input type="text" class="form-control shadow-lg" name="title" id="title">
						</div>
					</div>
				</div>
				<div class="form-group mb-3" hidden>
					<div class="row align-items-center">
						<label class="col-xl-2 form-label"></label>
						<div class="col-xl-10">
							<input type="text" class="form-control" name="files" id="files">
						</div>
					</div>
				</div>
				<div class="form-group mb-3">
					<div class="row">
						<label class="col-xl-2 form-label">{$translate->get('Message')}</label>
						<div class="col-xl-10">
							<div class="tk-composer">
							<textarea rows="8" class="form-control shadow-lg" name="message" id="message" placeholder="{$translate->get('TypeHere')}"></textarea>
							<div class="tk-tools">
								<button type="button" class="tk-tool" id="tkOpenEmojiBtn">😊 {$translate->get('Emoji')}</button>
								<span class="tk-hint">{$translate->get('NewLineHint')}</span>
							</div>
						</div>
						</div>
					</div>
				</div>						
			</div>
			
			<div class="card-footer">
				<div class="row">
						<button class="btn btn-dark btn-space mb-0 sendTicket">{$translate->get('Submit')}</button>
				</div>
			</div>
			
        </div>
      </div>
    </div>
  </div>