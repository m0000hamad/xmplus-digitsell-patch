// Builds the utility CSS inlined into patch/view/auth/register.tpl.
// Run from repo root: node tools/register/build.js
module.exports = {
  content: ['./tools/register/register.src.tpl', './patch/view/auth/loginsocial.tpl'],
  theme: { extend: {} },
};
