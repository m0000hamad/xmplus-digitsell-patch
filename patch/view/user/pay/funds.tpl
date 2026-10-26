<script>window.CheckoutFundsOrder="{$order->order_id|escape:'javascript'}";</script>
{literal}
<style>#checkout-funds [hidden]{display:none!important}</style>
<div id="checkout-funds" class="border rounded p-3 mb-3" dir="rtl">
 <strong>استفاده اختیاری از موجودی</strong>
 <label class="d-block border rounded p-2 mt-2" id="cf-wallet-row" hidden><input type="checkbox" id="cf-wallet"> استفاده از کیف پول: <span id="cf-wallet-balance"></span></label>
 <label class="d-block border rounded p-2 mt-2" id="cf-commission-row" hidden><input type="checkbox" id="cf-commission"> استفاده از پورسانت: <span id="cf-commission-balance"></span></label>
 <small class="d-block text-muted mt-2" id="cf-note">در حال بررسی موجودی…</small>
 <div id="cf-deductions" class="mt-2" hidden>
  <div>کسر از کیف پول: <span id="cf-wallet-used"></span></div>
  <div>کسر از پورسانت: <span id="cf-commission-used"></span></div>
 </div>
 <div id="cf-error" role="status" class="text-danger mt-2"></div>
 <div id="cf-gateways"></div>
</div>
<script>
(function(){
 'use strict';
 var token='',seq=0,last=null;
 function el(id){return document.getElementById('cf-'+id);}
 function money(n){return Number(n).toLocaleString('fa-IR',{maximumFractionDigits:2})+' ریال';}
 function button(disabled){var b=document.getElementById('checkout');if(b)b.disabled=disabled;}
 function args(){var radio=document.querySelector('input[name="payments"]:checked');return {
  order_id:window.CheckoutFundsOrder,method:radio?radio.value:'',use_wallet:el('wallet').checked?'1':'0',use_commission:el('commission').checked?'1':'0',expected_total:last?String(last.total):''};}
 function api(action,body){var data=body||args(),opts={credentials:'same-origin',cache:'no-store'};
  var url='/xmplus-patch.php?do=funds.'+action;
  if(action==='quote')url+='&'+new URLSearchParams(data).toString();
  else{data.token=token;opts.method='POST';opts.headers={'Content-Type':'application/x-www-form-urlencoded'};opts.body=new URLSearchParams(data).toString();}
  return fetch(url,opts).then(function(r){return r.json();}).then(function(r){if(!r.ok)throw new Error(r.error||r.msg||'محاسبه پرداخت انجام نشد.');return r;});
 }
 function show(q){last=q;token=q.token||token;
  document.getElementById('checkout-funds').style.display='block';
  el('wallet-row').hidden=false;el('commission-row').hidden=false;
  el('wallet-balance').textContent=money(q.wallet_balance);el('commission-balance').textContent=money(q.commission_balance);
  el('wallet').disabled=q.frozen||!q.wallet_eligible||!(q.wallet_balance>0);el('commission').disabled=q.frozen||!q.commission_eligible||!(q.commission_balance>0);
  if(q.frozen){el('wallet').checked=q.use_wallet;el('commission').checked=q.use_commission;}
  el('note').textContent=q.frozen?'اعتبار انتخاب‌شده برای این سفارش رزرو شده؛ در صورت لغو، به همان منبع برمی‌گردد.':
   (!q.wallet_eligible?'برای شارژ کیف پول از درگاه استفاده کنید.':(!q.commission_eligible&&q.commission_balance>0?'پورسانت فقط برای خرید و تمدید اشتراک قابل استفاده است.':'تا گزینه‌ای را انتخاب نکنید، موجودی کسر نمی‌شود.'));
  el('deductions').hidden=!(q.wallet_used>0||q.commission_used>0);
  el('wallet-used').textContent=money(q.wallet_used);el('commission-used').textContent=money(q.commission_used);
  var total=document.getElementById('total'),fee=document.getElementById('gateway_fee');
  if(total)total.textContent=Number(q.total).toLocaleString('fa-IR');if(fee)fee.textContent=Number(q.fee).toLocaleString('fa-IR');
  var legacy=document.getElementById('funds-legacy-credit');if(legacy)legacy.style.display='none';
  el('error').textContent='';window.CheckoutFunds.ready=true;button(false);
  // Some native checkouts expose only account-balance payment when its
  // implicit allocation covered the order. Opting out still needs a gateway.
  if(q.remaining>0 && q.gateways && q.gateways.length && !document.querySelector('input[name="payments"][value]:not([value="-1"]):not([value="c2c"])')){
   q.gateways.forEach(function(g,index){var label=document.createElement('label'),radio=document.createElement('input');
    radio.type='radio';radio.name='payments';radio.value=String(g.id);radio.onchange=function(){window.CheckoutFunds.quote();};
    label.className='d-block mt-2';label.appendChild(radio);label.appendChild(document.createTextNode(' '+g.name));el('gateways').appendChild(label);if(index===0)radio.checked=true;
   });window.CheckoutFunds.quote();
  }
 }
 window.CheckoutFunds={ready:false,quote:function(){var current=++seq;button(true);this.ready=false;
   return api('quote').then(function(q){if(current===seq)show(q);return q;}).catch(function(e){if(current===seq){el('error').textContent=e.message;button(true);}return null;});
  },data:function(){var d=args();d.token=token;return d;},remaining:function(){return last?last.remaining:null;},
  reserve:function(){button(true);return api('reserve').then(function(q){show(q);return q;}).catch(function(e){el('error').textContent=e.message;button(false);throw e;});}
 };
 el('wallet').onchange=el('commission').onchange=function(){window.CheckoutFunds.quote();};
 button(true);
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',function(){window.CheckoutFunds.quote();});else window.CheckoutFunds.quote();
})();
</script>
{/literal}
