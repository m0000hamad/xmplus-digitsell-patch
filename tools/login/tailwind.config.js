// Builds the utility CSS inlined into patch/view/auth/login.tpl.
// Run from repo root: node tools/login/build.js
module.exports = {
  content: ['./tools/login/login.src.tpl', './patch/view/auth/loginsocial.tpl'],
  theme: { extend: {} },
};
