<div class="row"><div class="col-12">
<div class="card card-shadow shadow-lg rounded mb-4 sir-card" id="subscriptionInfoRows">
  <div class="card-header"><h4 class="card-header-title">ردیف‌های اطلاعات داخل اشتراک</h4></div>
  <div class="card-body">
    <p class="text-muted">برای هر لینک، فقط ردیف‌های تیک‌خورده نمایش داده می‌شوند. متن هر ردیف را می‌توانید تغییر دهید؛ مقدارهای داخل آکولاد از اطلاعات واقعی همان کاربر پر می‌شوند.</p>
    <p class="small text-muted">ردیف‌های مربوط به وضعیت، فقط در همان حالت دیده می‌شوند؛ مثلاً «تمام‌شدن حجم» وقتی حجم تمام شده باشد. مقادیر پیش‌نمایش نمونه‌اند.</p>
    <div id="sirTokens" class="small mb-3"></div>
    <div id="sirProfiles" class="row g-3"></div>
    <button type="button" id="sirSave" class="btn btn-primary mt-3" disabled>ذخیره ردیف‌های هر دو لینک</button>
    <span id="sirStatus" class="small ms-2" role="status"></span>
  </div>
</div>
</div></div>
{literal}
<style>.sir-card .form-check-input{position:static;float:none;margin-inline-end:.5rem}.sir-card .sir-row{border-bottom:1px solid rgba(127,127,127,.15);padding:.75rem 0}.sir-card .sir-row:last-child{border:0}.sir-card code{display:inline-block;direction:ltr;margin:.2rem .35rem}</style>
<script>
document.addEventListener('DOMContentLoaded', function () {
  const root=document.getElementById('sirProfiles'), save=document.getElementById('sirSave'), status=document.getElementById('sirStatus');
  if(!root)return;
  const endpoint='/xmplus-patch.php?do=subprofiles.inforows.', controls={}; let token='';
  const sample={expire_date:'۱۵ آبان ۱۴۰۵',days_left:'۵',remaining:'۲۰ گیگ',remaining_short:'۲۰',total:'۱۰۰ گیگ',used:'۸۰ گیگ',balance:'۵۰٬۰۰۰ ریال',updated_time:'۱۲:۳۰'};
  const descriptions={expire_date:'تاریخ پایان',days_left:'روز باقی‌مانده',remaining:'حجم باقی‌مانده',remaining_short:'باقی‌مانده کوتاه',total:'حجم کل',used:'مصرف‌شده',balance:'موجودی کیف پول',updated_time:'ساعت به‌روزرسانی'};
  function element(tag,cls,text){const el=document.createElement(tag);if(cls)el.className=cls;if(text)el.textContent=text;return el;}
  fetch(endpoint+'get',{credentials:'same-origin',cache:'no-store'}).then(r=>r.json()).then(data=>{
    if(!data.ok)throw new Error(data.error);token=data.token;
    data.tokens.forEach(key=>{const item=element('span','me-2'), code=element('code','','{'+key+'}');item.append(code,document.createTextNode(descriptions[key]));document.getElementById('sirTokens').appendChild(item);});
    [1,2].forEach(slot=>{
      const col=element('div','col-lg-6'), box=element('fieldset','border rounded p-3 h-100');box.dataset.slot=slot;
      box.appendChild(element('legend','fs-5','لینک '+slot+' — '+data.titles[slot-1]));
      const masterLabel=element('label','d-block fw-bold mb-2'), master=element('input','form-check-input');master.type='checkbox';master.checked=data.profiles[slot].enabled;
      masterLabel.append(master,document.createTextNode('نمایش اطلاعات این لینک'));box.appendChild(masterLabel);controls[slot]={master,rows:{}};
      Object.entries(data.definitions).forEach(([key,definition])=>{
        const row=element('div','sir-row');row.dataset.key=key;
        const label=element('label','d-block mb-2'), check=element('input','form-check-input');check.type='checkbox';check.checked=data.profiles[slot].rows[key].enabled;
        label.append(check,document.createTextNode(definition.label));row.appendChild(label);
        const input=element('input','form-control');input.type='text';input.maxLength=200;input.dir='auto';input.value=data.profiles[slot].rows[key].text;input.setAttribute('aria-label','متن '+definition.label+' در لینک '+slot);
        const preview=element('div','small text-muted mt-1');
        function show(){preview.textContent='نمونه: '+input.value.replace(/\{([^{}]+)\}/g,(_,key)=>sample[key]??'{'+key+'}');}
        input.addEventListener('input',show);show();row.append(input,preview);box.appendChild(row);controls[slot].rows[key]={check,input};
      });
      col.appendChild(box);root.appendChild(col);
    });save.disabled=false;
  }).catch(e=>{status.textContent='بارگذاری انجام نشد: '+e.message;});
  save.addEventListener('click',async function(){
    const profiles={};
    [1,2].forEach(slot=>{const control=controls[slot], rows={};Object.entries(control.rows).forEach(([key,row])=>{rows[key]={enabled:row.check.checked,text:row.input.value};});profiles[slot]={enabled:control.master.checked,rows};});
    save.disabled=true;status.textContent='در حال ذخیره…';
    try{const body=new URLSearchParams({token,profiles:JSON.stringify(profiles)});const data=await(await fetch(endpoint+'save',{method:'POST',credentials:'same-origin',body})).json();if(!data.ok)throw new Error(data.error);status.textContent='تنظیمات مستقل هر دو لینک ذخیره شد؛ کاربران اشتراک را به‌روزرسانی کنند.';}
    catch(e){status.textContent=e.message;}finally{save.disabled=false;}
  });
});
</script>
{/literal}
