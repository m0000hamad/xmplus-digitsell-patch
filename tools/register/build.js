// Compiles Tailwind for the register page and inlines it at /*TAILWIND*/.
// The panel is served behind an Iranian CDN and public/assets is outside the
// updater's allowed paths, so the page carries its own CSS instead of a CDN.
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '../..');
const out = path.join(__dirname, '.tw.css');
fs.writeFileSync(path.join(__dirname, '.in.css'), '@tailwind base;\n@tailwind components;\n@tailwind utilities;\n');
execSync(`npx --yes tailwindcss@3.4.17 -c tools/register/tailwind.config.js -i tools/register/.in.css -o ${JSON.stringify(out)} --minify`, { cwd: root, stdio: 'inherit' });
const css = fs.readFileSync(out, 'utf8');
if (css.includes('{/literal}')) throw new Error('compiled CSS would close the Smarty literal block');
const src = fs.readFileSync(path.join(__dirname, 'register.src.tpl'), 'utf8');
fs.writeFileSync(path.join(root, 'patch/view/auth/register.tpl'), src.replace('/*TAILWIND*/', css));
fs.unlinkSync(out); fs.unlinkSync(path.join(__dirname, '.in.css'));
console.log('register.tpl written,', css.length, 'bytes of CSS');
