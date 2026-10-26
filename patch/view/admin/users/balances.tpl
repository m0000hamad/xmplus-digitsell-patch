<div id="admin-user-balances" data-user="{$user_edit->id|escape:'html'}">
 <div class="row mb-2">
  <label class="col-sm-3 col-form-label form-label" for="aub-wallet">موجودی کیف پول مصرفی</label>
  <div class="col-sm-9" style="max-width:60rem"><div class="input-group"><span class="input-group-text">ریال</span><input type="text" inputmode="decimal" class="form-control shadow-lg" id="aub-wallet" disabled placeholder="در حال خواندن موجودی…"></div></div>
 </div>
 <div class="row mb-2">
  <label class="col-sm-3 col-form-label form-label" for="aub-commission">موجودی پورسانت</label>
  <div class="col-sm-9" style="max-width:60rem"><div class="input-group"><span class="input-group-text">ریال</span><input type="text" inputmode="decimal" class="form-control shadow-lg" id="aub-commission" disabled placeholder="در حال خواندن موجودی…"></div><small class="text-muted">مجموع پورسانت قدیمی و کیف پورسانت</small></div>
 </div>
 <div class="row mb-2">
  <label class="col-sm-3 col-form-label form-label" for="aub-reason">توضیح تغییر موجودی</label>
  <div class="col-sm-9" style="max-width:60rem"><input class="form-control" id="aub-reason" maxlength="180" placeholder="اختیاری"><small class="text-muted">مبلغ نهایی موجودی را وارد کنید؛ با دکمهٔ ذخیره، تغییرات هر منبع جدا ثبت می‌شود.</small><p id="aub-status" role="status" class="mt-2 mb-0"></p></div>
 </div>
</div>
{literal}
<script>
(function(){
 'use strict';
 var original=null,root=document.getElementById('admin-user-balances');
 function el(name){return document.getElementById('aub-'+name);}
 function normal(raw){var text=String(raw).replace(/[۰-۹]/g,function(c){return String('۰۱۲۳۴۵۶۷۸۹'.indexOf(c));}).replace(/[٠-٩]/g,function(c){return String('٠١٢٣٤٥٦٧٨٩'.indexOf(c));}).replace(/[,٬،\s]/g,'').replace('٫','.');return Number(text).toFixed(2);}
 window.AdminUserBalances={ready:false,payload:function(){return {
  token:original.token,request_key:original.request_key,
  wallet_changed:normal(el('wallet').value)!==normal(original.wallet_balance)?'1':'0',
  commission_changed:normal(el('commission').value)!==normal(original.commission_balance)?'1':'0',
  wallet_balance:el('wallet').value,commission_balance:el('commission').value,
  expected_wallet:original.wallet_balance,expected_legacy:original.legacy,expected_dedicated:original.dedicated,balance_reason:el('reason').value
 };}};
 function load(){fetch('/xmplus-patch.php?do=userbalances.get&id='+encodeURIComponent(root.dataset.user),{credentials:'same-origin',cache:'no-store'})
  .then(function(r){return r.json();}).then(function(r){if(!r.ok)throw new Error(r.error||'خواندن موجودی انجام نشد.');
   original=r;el('wallet').value=r.wallet_balance;el('commission').value=r.commission_balance;
   el('wallet').disabled=el('commission').disabled=!r.editable;window.AdminUserBalances.ready=true;
   var save=document.getElementById('admin-user-save');if(save)save.disabled=false;
   if(!r.editable)el('status').textContent='تغییر موجودی فقط برای مدیر اصلی مجاز است.';
  }).catch(function(e){el('status').textContent=e.message;el('status').className='text-danger';});
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',load);else load();
})();
</script>
{/literal}
