			<div id="content" class="set-profile">
				<div class="set-profile-cover">
					<img id="profileCoverImg" src="/assets/img/1920x400/img2.jpg" alt="">
					<input type="file" class="js-file-attach profile-cover-uploader-input">
				</div>

				<label id="upload-button" class="set-profile-avatar" for="editAvatarUploaderModal">
					<img src="{$user->image()}" alt="">
				</label>

				<h2 class="set-profile-name">
					{$user->username|escape:'html'}
					<i class="bi-patch-check-fill fs-5 text-primary" data-bs-toggle="tooltip" data-bs-placement="top" title="{$translate->get('Verified')}"></i>
				</h2>
				<p class="set-profile-meta">
					<span>📅</span> {$translate->get('MemberSince')} {date("M Y", strtotime($user->reg_date))}
				</p>
			</div>
