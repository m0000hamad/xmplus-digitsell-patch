<script>localStorage.setItem('toggleID', 'usersMenu'); </script>	
{include file='admin/layout/header.tpl'}
    <div class="page-header">
        <div class="row align-items-end">
			<div class="col-sm mb-2 mb-sm-0">
				<h1 class="page-header-title">{$translate->get('EditUser')}</h1>
			</div>
        </div>
    </div>

	<div class="row match-height">
		<div class="card card-shadow shadow-lg rounded">
			<div class="card-header card-header-content-between border-bottom">
				<h3 class="card-header-title mb-2 mb-sm-0">{$translate->get('EditUserInfo')}</h3>
				{if $Config['verify'] == 1 && $user_edit->verify == 0}
					<button  class="btn btn-dark" type="button" onClick="ActivateUser()" class="btn btn-dark">{$translate->get('ActivateAcc')}</button>
				{/if}
			</div>
			<div class="card-body">
				<div class="row">	
					<div class="col-lg-6 col-xl-6 col-md-6 col-sm-12 mb-3">
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="status">{$translate->get('Status')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="status" name="status" data-hs-tom-select-options='{
										"hideSearch": true
									}'>
									<option value="0" {if $user_edit->status == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $user_edit->status == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="role">{$translate->get('UserGroup')}</label>
							<div class="col-sm-9 tom-select-custom"  style="max-width: 60rem">
								<select class="js-select form-select shadow-lg" id="role" name="role" data-hs-tom-select-options='{
										"hideSearch": true
									}'  {if $user->role != 1}disabled{/if}>
									<option value="0" {if $user_edit->role == 0}selected{/if}>{$translate->get('User')}</option>
									{foreach $usergroups as $usergroup}
										<option value="{$usergroup->id}" {if $user_edit->role == $usergroup->id}selected{/if}>{$usergroup->name}</option>
									{/foreach}
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="email">{$translate->get('Email')} </label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="email" name="email" placeholder="{$translate->get('Email')}" value="{$user_edit->email}">
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="password">{$translate->get('Password')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="password" name="password" placeholder="{$translate->get('Password')}" >
							</div>
						</div>
						{include file='admin/users/balances.tpl'}
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="rebate">{$translate->get('Rebate')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<div class="input-group">
									<a class="btn btn-dark text-center">%</a>
									<input type="text" class="form-control shadow-lg" id="rebate" name="rebate" placeholder="{$translate->get('Rebate')}" value="{$user_edit->rebate}">
								</div>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="payout_balance">{$translate->get('WithdrawalAvail')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<div class="input-group">
									<a class="btn btn-dark text-center">{$currency->symbol_left} {$currency->symbol_right}</a>
									<input type="text" class="form-control shadow-lg" id="payout_balance" name="payout_balance" placeholder="{$translate->get('WithdrawalAvail')}" value="{$user_edit->payout_balance}">
								</div>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="link">{$translate->get('ConfigLinks')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								{$adminLinks = $user_edit->subscriptionProfiles()}
                                {$nativeLink = $helpers->SubUrl()|cat:$user_edit->token}
                                {foreach $adminLinks as $profile}
                                    {$profileLink = $nativeLink}
                                    {if $profile.id > 0}
                                        {$profileLink = $nativeLink|regex_replace:'~/link/([A-Za-z0-9_-]+)/?$~':'/xmplus-patch.php?do=sub&t=$1'|cat:'&profile='|cat:$profile.id|cat:'&config=1'}
                                    {/if}
                                    {if $profile.name}<label class="form-label">{$profile.name|escape}</label>{/if}
                                    {if $profile.description}<p class="text-muted small" style="white-space:pre-line">{$profile.description|escape}</p>{/if}
                                    <input type="text" class="form-control shadow-lg copy-text mb-2" value="{$profileLink|escape}" data-clipboard-text="{$profileLink|escape}" readonly onclick="this.select()">
                                {foreachelse}
                                    <span class="text-muted">لینکی برای گروه اشتراک این کاربر فعال نیست.</span>
                                {/foreach}
							</div>
						</div>
					</div>	
					<div class="col-lg-6 col-xl-6 col-md-6 col-sm-12 mb-3">
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="transfer_enable">{$translate->get('TotalData')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" {if $user->role != 1}disabled{/if} id="transfer_enable" name="transfer_enable" placeholder="{$translate->get('TotalData')}" value="{$user_edit->transfer_enable/(1024*1024*1024)}">
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="used_data">{$translate->get('UsedData')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg"  value="{$helpers->trafficConvert($user_edit->u + $user_edit->d)}" disabled>
							</div>
						</div>				
						<div class="row mb-2">
								<label class="col-sm-3 col-form-label form-label" for="server_group">{$translate->get('ServerGroup')}</label>
								<div class="col-sm-9 tom-select-custom">
									<select class="js-select form-select shadow-lg" id="server_group" name="server_group" data-hs-tom-select-options='{
									  "hideSearch": false,
									  "placeholder": ""
									}' >
										{foreach $group as $server_group}
											<option value="{$server_group->id}" {if $server_group->id == $user_edit->server_group} selected{/if}>{$server_group->name}</option>
										{/foreach}
									</select>
								</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="speedlimit">{$translate->get('Speedlimit')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="speedlimit" name="speedlimit" placeholder="{$translate->get('Speedlimit')}" value="{$user_edit->speedlimit}">
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="iplimit">{$translate->get('IPLimit')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="iplimit" name="iplimit" placeholder="{$translate->get('IPLimit')}" value="{$user_edit->iplimit}">
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="telegram_id">Telegram ID</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="telegram_id" name="telegram_id" value="{$user_edit->telegram_id}" disabled>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="telegram_name">Telegram {$translate->get('Username')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" id="telegram_name" name="telegram_name" value="{$user_edit->telegram_name}" disabled>
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="expire_in">{$translate->get('DataExp')}</label>
							<div class="col-sm-9"  style="max-width: 60rem">
								<input type="text" class="form-control shadow-lg" {if $user->role != 1}disabled{/if} id="expire_in" name="expire_in" placeholder="{$translate->get('DataExp')}" value="{$user_edit->expire_in}">
							</div>
						</div>						
					
					</div>
				</div>	
			</div>	
		</div>	
	</div>	
      <div class="position-fixed start-50 bottom-0 translate-middle-x w-100 zi-99 mb-3" style="max-width: 40rem;">
        <!-- Card -->
        <div class="card card-sm bg-dark border-dark mx-2">
          <div class="card-body">
            <div class="row justify-content-center justify-content-sm-between">
              <div class="col">
                <a type="button" onClick="deleteUserModal()" class="btn btn-ghost-danger">{$translate->get('Delete')}</a>
              </div>
              <div class="col-auto">
                <div class="d-flex gap-3">
                  <a type="button" href="/admin/users" class="btn btn-ghost-light">{$translate->get('Discard')}</a>
                  <button type="button" id="admin-user-save" disabled onClick="updateUser()" class="btn btn-dark">{$translate->get('Save')}</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>	
{include file='admin/layout/footer.tpl'}
<script>
    function deleteUserModal() {
		Swal.fire({
			title: "{$translate->get('ConfirmDelete')}",
			text: "{$translate->get('ConfirmDeleteNote')}",
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton:true,
			confirmButtonText: "{$translate->get('Delete')}",
			cancelButtonText: "{$translate->get('Cancel')}",
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-secondary ms-1',
				cancelButton: 'btn btn-danger ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (result.isConfirmed) {
				delete_id();
			}
		});
    }

	function delete_id() {
        $.ajax({
            type: "DELETE",
            url: "/admin/user/delete",
            dataType: "json",
            data: {
                id: {$user_edit->id},
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    window.setTimeout("location.href='/admin/users'", 1500);
                } else {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
            }
        });
    }
	
	function ActivateUser(){
		$.ajax({
            type: "POST",
            url: "/admin/user/activate",
            dataType: "json",
            data: {
                id: {$user_edit->id},
            },
            success: data => {
                if (data.ret) {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                    window.setTimeout("location.href='/admin/users'", 1500);
                } else {
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
                }
            },
            error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 5000,
					offset:  '100px'
				});
            }
        });
	}
	
	function updateUser(){
        if (!window.AdminUserBalances || !window.AdminUserBalances.ready) { layer.msg('ابتدا منتظر بارگذاری موجودی‌ها بمانید.'); return; }
		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/xmplus-patch.php?do=userbalances.save",
			dataType: "json",
			data: Object.assign({
				id: {$user_edit->id},
				status: $("#status").val(),
				role: $("#role").val(),
				email: $("#email").val(),
				passwd: $("#password").val(),
				transfer_enable: $("#transfer_enable").val(),
				server_group: $("#server_group").val(),
				speedlimit: $("#speedlimit").val(),
				iplimit: $("#iplimit").val(),
				expire_in: $("#expire_in").val(),
				payout_balance: $("#payout_balance").val(),
				rebate:$("#rebate").val(),
			}, window.AdminUserBalances.payload()),
			success: (data) => {
				layer.closeAll('loading');
				if (data.ret == 1) { 
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/admin/users'", 1000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
						time: 5000,
						offset:  '100px'
					});
			}
		});	
	}
</script>


