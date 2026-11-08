{literal}
<script>
(function () {
    var selected = new Set(), busy = false;
    var bar = document.createElement('div');
    bar.className = 'd-flex flex-wrap align-items-center gap-2 mb-3';
    bar.innerHTML = '<label><input type="checkbox" id="tkSelectPage"> انتخاب این صفحه</label><span id="tkSelectedCount">۰ انتخاب</span><button type="button" class="btn btn-sm btn-secondary" data-tk-operation="close">بستن انتخاب‌شده‌ها</button><button type="button" class="btn btn-sm btn-danger" data-tk-operation="delete">حذف انتخاب‌شده‌ها</button>';
    var table = document.getElementById('pagination');
    if (!table) return;
    table.parentNode.insertBefore(bar, table);
    function update() {
        bar.querySelector('#tkSelectedCount').textContent = selected.size + ' انتخاب';
        bar.querySelectorAll('button').forEach(function (b) { b.disabled = busy || !selected.size; });
        var boxes = Array.from(table.querySelectorAll('.tk-select'));
        var all = bar.querySelector('#tkSelectPage');
        all.checked = boxes.length > 0 && boxes.every(function (b) { return b.checked; });
        all.indeterminate = boxes.some(function (b) { return b.checked; }) && !all.checked;
    }
    function wire() {
        table.querySelectorAll('tbody tr').forEach(function (row) {
            if (row.querySelector('.tk-select')) return;
            var match = row.innerHTML.match(/\/admin\/ticket\/(\d+)/);
            if (!match || !row.cells.length) return;
            var id = match[1], box = document.createElement('input');
            box.type = 'checkbox'; box.style.position = 'static'; box.className = 'tk-select form-check-input me-2';
            box.value = id; box.checked = selected.has(id); box.setAttribute('aria-label', 'انتخاب تیکت ' + id);
            box.addEventListener('change', function () { box.checked ? selected.add(id) : selected.delete(id); update(); });
            row.cells[0].prepend(box);
            var del = document.createElement('button'); del.type = 'button';
            del.className = 'btn btn-sm btn-outline-danger ms-2'; del.textContent = 'حذف';
            del.addEventListener('click', function () { manage('delete', [id]); });
            row.cells[0].appendChild(del);
        });
        update();
    }
    async function manage(operation, ids) {
        if (busy || !ids.length) return;
        if (ids.length > 100) { layer.msg('حداکثر ۱۰۰ تیکت را انتخاب کنید.'); return; }
        var answer = await Swal.fire({title: operation === 'delete' ? 'حذف دائمی ' + ids.length + ' تیکت و تمام پاسخ‌ها؟' : 'بستن ' + ids.length + ' تیکت؟', icon:'warning', showCancelButton:true, confirmButtonText:'تأیید', cancelButtonText:'انصراف'});
        if (!answer.isConfirmed || busy) return;
        busy = true; update();
        try {
            var token = await $.getJSON('/xmplus-patch.php?do=ticket.token');
            var result = await $.ajax({url:'/xmplus-patch.php?do=ticket.manage', type:'POST', dataType:'json', data:{token:token.token, operation:operation, ids:ids}});
            if (!result.ok) throw new Error(result.error || 'عملیات انجام نشد.');
            ids.forEach(function (id) { selected.delete(id); });
            if ($.fn.dataTable.isDataTable(table)) $(table).DataTable().ajax.reload(null, false);
            else window.location.reload();
            layer.msg('عملیات انجام شد.');
        } catch (error) { layer.msg('نتیجه عملیات مشخص نیست؛ فهرست را تازه کنید و بررسی کنید.'); }
        finally { busy = false; update(); }
    }
    bar.querySelector('#tkSelectPage').addEventListener('change', function (e) {
        table.querySelectorAll('.tk-select').forEach(function (b) { b.checked = e.target.checked; b.checked ? selected.add(b.value) : selected.delete(b.value); }); update();
    });
    bar.querySelectorAll('[data-tk-operation]').forEach(function (b) { b.addEventListener('click', function () { manage(b.dataset.tkOperation, Array.from(selected)); }); });
    $(table).on('draw.dt', wire);
    wire();
})();
</script>
{/literal}
