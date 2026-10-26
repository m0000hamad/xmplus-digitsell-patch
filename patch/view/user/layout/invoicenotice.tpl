{literal}
<a id="digitsell-invoice-notice" class="alert alert-info d-block mb-3" href="/portal/orders" style="display:none!important" role="status"></a>
<script>
(function(){
 fetch('/xmplus-patch.php?do=invoice.me',{credentials:'same-origin',cache:'no-store'}).then(function(r){return r.json();}).then(function(r){
  if(!r.ok)return;
  var pending=r.invoices.filter(function(i){return i.status==='pending';});
  if(!pending.length)return;
  var link=document.getElementById('digitsell-invoice-notice');
  link.textContent='🧾 '+pending.length.toLocaleString('fa-IR')+' فاکتور در انتظار پرداخت دارید — مشاهده و پرداخت';
  link.href='/portal/orders#invoice-'+pending[0].id;link.style.removeProperty('display');
 }).catch(function(){});
})();
</script>
{/literal}
