{literal}
<section class="card mb-4" dir="rtl" id="digitsell-invoices" style="border-radius:18px">
 <div class="card-body">
  <h2 class="h4">فاکتورهای صادرشده</h2>
  <p class="text-muted">فاکتور خدمات فقط بابت خدمات است. فاکتور پلن پس از پرداخت، خرید یا تمدید سرویس را انجام می‌دهد.</p>
  <div id="di-admin" hidden>
   <form id="di-form" class="row g-3 mb-4">
    <div class="col-md-6"><label class="form-label" for="di-search">جستجوی کاربر (نام، ایمیل یا شناسه)</label><input class="form-control" id="di-search" autocomplete="off"><select class="form-select mt-2" id="di-user" required aria-label="انتخاب کاربر"></select></div>
    <div class="col-md-6"><label class="form-label" for="di-title">عنوان فاکتور</label><input class="form-control" id="di-title" maxlength="200" required></div>
    <div class="col-md-4"><label class="form-label" for="di-kind">نوع فاکتور</label><select class="form-select" id="di-kind"><option value="service">مبلغ دلخواه بابت خدمات</option><option value="plan">خرید یا تمدید پلن</option></select></div>
    <div class="col-md-4" id="di-amount-wrap"><label class="form-label" for="di-amount">مبلغ (ریال)</label><input class="form-control" type="number" min="1" max="100000000000" step="0.01" id="di-amount"></div>
    <div class="col-md-4" id="di-package-wrap" hidden><label class="form-label" for="di-package">پلن</label><select class="form-select" id="di-package"></select></div>
    <div class="col-md-4" id="di-plan-wrap" hidden><label class="form-label" for="di-plan">دوره و مبلغ</label><select class="form-select" id="di-plan"></select><label class="mt-2"><input type="checkbox" id="di-renew"> تمدید پلن فعلی کاربر</label></div>
    <div class="col-12"><label class="form-label" for="di-description">شرح خدمات</label><textarea class="form-control" id="di-description" maxlength="2000" rows="2"></textarea></div>
    <div class="col-12"><button class="btn btn-primary" id="di-submit">صدور و اطلاع‌رسانی</button> <small class="text-muted">اعلان پنل + ایمیل و تلگرام در صورت فعال بودن و اتصال کاربر</small></div>
   </form>
  </div>
  <p id="di-message" role="status" aria-live="polite"></p>
  <div id="di-list"></div>
 </div>
</section>
<script>
(function(){
 'use strict';
 var admin=!!window.DigitsellInvoiceAdmin, token='', key='', packages=[];
 var $=function(id){return document.getElementById('di-'+id);};
 var labels={month:'ماهانه',quater:'سه ماهه',semiannual:'شش ماهه',annual:'سالانه',onetime:'یک‌باره',custom:'سفارشی'};
 var states={pending:'در انتظار پرداخت',paid:'پرداخت شده',closed:'بسته شده',canceled:'لغو شده'};
 function money(n){return Number(n).toLocaleString('fa-IR')+' ریال';}
 function api(action,data){
  var opts={credentials:'same-origin',cache:'no-store'};
  if(data){data.token=token;opts.method='POST';opts.headers={'Content-Type':'application/x-www-form-urlencoded'};opts.body=new URLSearchParams(data).toString();}
  return fetch('/xmplus-patch.php?do=invoice.'+action,opts).then(function(r){return r.json();}).then(function(r){if(!r.ok)throw new Error(r.error||'عملیات انجام نشد');return r;});
 }
 function msg(e){$('message').textContent=e.message||e;}
 function node(tag,text,cls){var el=document.createElement(tag);el.textContent=text;if(cls)el.className=cls;return el;}
 function render(rows){
  $('list').replaceChildren();
  if(!rows.length){$('list').appendChild(node('p','فاکتوری وجود ندارد.','text-muted'));return;}
  rows.forEach(function(i){
   var card=node('article','','border rounded p-3 mb-3');card.id='invoice-'+i.id;
   card.appendChild(node('h3','#'+i.id+' — '+i.title,'h5'));
   card.appendChild(node('p',(admin?i.username+' · ':'')+money(i.amount)+' · '+states[i.status]));
   card.appendChild(node('p',i.description));
   if(i.kind==='plan'){card.appendChild(node('p',Number(i.renew)?'تمدید طبق قوانین پلن فعلی انجام می‌شود.':'پس از پرداخت، پلن خریداری‌شده جایگزین سرویس فعلی می‌شود.','text-muted'));}
   if(admin){
    var status={off:'غیرفعال/بدون مقصد',queued:'در صف',sent:'ارسال شد',failed:'ناموفق'};
    card.appendChild(node('small','ایمیل: '+status[i.mail_status]+' | تلگرام: '+status[i.telegram_status],'d-block text-muted mb-2'));
    var link=node('a','لینک فاکتور','btn btn-sm btn-outline-primary me-2');link.href=i.url;link.target='_blank';link.rel='noopener';card.appendChild(link);
    if(!i.orderid&&i.status==='pending'){var cancel=node('button','لغو','btn btn-sm btn-outline-danger');cancel.onclick=function(){cancel.disabled=true;api('cancel',{id:i.id}).then(load).catch(msg).finally(function(){cancel.disabled=false;});};card.appendChild(cancel);}
   }else if(i.status==='pending'){
    var pay=node('button','مشاهده درگاه‌ها و پرداخت','btn btn-primary');pay.onclick=function(){if(i.kind==='plan'&&!Number(i.renew)&&!window.confirm('پس از پرداخت، این پلن جایگزین سرویس فعلی می‌شود. ادامه می‌دهید؟'))return;pay.disabled=true;api('checkout',{id:i.id}).then(function(r){location.assign(r.url);}).catch(msg).finally(function(){pay.disabled=false;});};card.appendChild(pay);
   }
   $('list').appendChild(card);
  });
  if(/^#invoice-\d+$/.test(location.hash)){var target=document.getElementById(location.hash.slice(1));if(target)target.scrollIntoView({block:'center'});}
 }
 function cycles(){
  $('plan').replaceChildren();var p=packages.find(function(p){return String(p.id)===$('package').value;});
  if(!p)return;var opts=JSON.parse(p.price_option||'{}');
  Object.keys(labels).forEach(function(k){if(opts[k]&&Number(opts[k].price)>0){var o=node('option',labels[k]+' — '+money(opts[k].price));o.value=k;$('plan').appendChild(o);}});
 }
 function load(){return api(admin?'admin':'me').then(function(r){token=r.token;key=r.request_key||'';render(r.invoices);if(admin&&packages.length===0){packages=r.packages;packages.forEach(function(p){var o=node('option',p.name);o.value=p.id;$('package').appendChild(o);});cycles();}}).catch(msg);}
 $('admin').hidden=!admin;
 if(admin){
  var timer,seq=0;
  $('search').oninput=function(){clearTimeout(timer);var current=++seq;timer=setTimeout(function(){api('users&q='+encodeURIComponent($('search').value)).then(function(r){if(current!==seq)return;$('user').replaceChildren();r.users.forEach(function(u){var o=node('option','#'+u.id+' '+u.username+' — '+u.email);o.value=u.id;$('user').appendChild(o);});}).catch(msg);},300);};
  $('kind').onchange=function(){var isPlan=this.value==='plan';$('amount-wrap').hidden=isPlan;$('package-wrap').hidden=!isPlan;$('plan-wrap').hidden=!isPlan;};
  $('package').onchange=cycles;
  $('form').onsubmit=function(e){e.preventDefault();$('submit').disabled=true;api('create',{request_key:key,userid:$('user').value,title:$('title').value,description:$('description').value,kind:$('kind').value,amount:$('amount').value,packageid:$('package').value,plan:$('plan').value,renew:$('renew').checked?'1':'0'}).then(function(){msg('فاکتور صادر شد؛ وضعیت اطلاع‌رسانی در فهرست نمایش داده می‌شود.');$('title').value='';$('description').value='';return load();}).catch(msg).finally(function(){$('submit').disabled=false;});};
 }
 load();
})();
</script>
{/literal}
