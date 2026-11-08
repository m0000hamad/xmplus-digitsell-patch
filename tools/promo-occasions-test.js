// Exercise the actual editor's picker, including transitions and custom text.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.join(__dirname, '..', 'patch');
const js = fs.readFileSync(path.join(root, 'view/admin/plans/promojs.tpl'), 'utf8');
const context = {};
vm.createContext(context);
vm.runInContext(js.match(/<script>([\s\S]*?)<\/script>/)[1], context);
const picker = js.match(/function promoThemePicked\(\) \{[\s\S]*?\n\t\}/)[0];
let theme, text;
context.$ = Object.assign(selector => ({val(value) {
    if (arguments.length) text = value;
    return selector === '#promo_theme' ? theme : text;
}}), {trim: value => value.trim()});
vm.runInContext(picker, context);
const keys = ['attar','saadi','ferdowsi','khayyam','avicenna','razi','rumi','hafez','cyrus','rainy','autumn_rain','walking','winter_snow','rainbow'];
for (const key of keys) {
    theme = key; text = '';
    context.promoThemePicked();
    assert.ok(text && text === context.promoThemeText[key], key);
    const previous = text;
    theme = key === 'rainbow' ? 'nowruz' : 'rainbow';
    context.promoThemePicked();
    assert.notEqual(text, previous, 'switching replaces the previous suggestion');
    text = 'متن دلخواه مدیر'; theme = key;
    context.promoThemePicked();
    assert.equal(text, 'متن دلخواه مدیر');
}
text = context.promoThemeText.attar; theme = 'autumn';
context.promoThemePicked(); assert.equal(text, '');
const form = fs.readFileSync(path.join(root, 'view/admin/plans/promoform.tpl'), 'utf8');
const css = fs.readFileSync(path.join(root, 'view/user/plan/promostyle.tpl'), 'utf8');
for (const key of keys) {
    assert.ok(form.includes('value="'+key+'"'), key+' option');
    assert.ok(form.includes("$ptheme == '"+key+"'"), key+' restored on edit');
    for (const selector of [' .promo-sticker-slot1', ' .promo-sticker-slot2', ' {'])
        assert.ok(css.includes('.promo-theme-'+key+selector), key+' style');
    assert.ok(css.includes('.promo-banner.promo-theme-'+key), key+' banner');
    const suffix = context.promoThemeText[key].match(/PromoOccasion(\w+)/)[1];
    for (const lang of ['fa_IR','en_US']) {
        const locale = fs.readFileSync(path.join(root, 'localization',lang+'.php'), 'utf8');
        for (const prefix of ['PromoTheme','PromoOccasion']) assert.ok(locale.includes("'"+prefix+suffix+"'"));
    }
}
console.log('PASS all 14 picker options, text switching, custom text preservation, edit restoration, palettes and both languages');
