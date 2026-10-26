{* Source selection now happens explicitly on the native payment page. *}
{literal}
<script>window.CommissionUse = {passed:true,before:function(packageid,cycle,next){next();}};</script>
{/literal}
