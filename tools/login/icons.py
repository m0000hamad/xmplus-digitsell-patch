"""
Builds tools/login/icons.css: the handful of Font Awesome icons the sign-in page
uses, as two subset woff2 fonts inlined in base64 (a few KB instead of the
panel's 67 KB all.min.css plus ~375 KB of webfonts).

Needs fonttools and brotli (pip install fonttools brotli) and, next to this
file in fa/, the panel's own
    public/assets/fonts/fontawesome/css/all.min.css
    public/assets/fonts/fontawesome/webfonts/fa-solid-900.woff2
    public/assets/fonts/fontawesome/webfonts/fa-brands-400.woff2
(fa/ is not committed - the fonts are the panel's licensed copy).

Run from the repo root after adding an icon to login.src.tpl or
loginsocial.tpl:   python tools/login/icons.py && node tools/login/build.js
"""
import base64, io, os, re, sys
from fontTools import subset
from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
FA = os.path.join(HERE, 'fa')
SOURCES = [os.path.join(HERE, 'login.src.tpl'), os.path.join(ROOT, 'patch', 'view', 'auth', 'loginsocial.tpl')]

css = open(os.path.join(FA, 'all.min.css'), encoding='utf-8').read()
used = set()
for path in SOURCES:
    used |= set(re.findall(r'\bfa-([a-z0-9-]+)', open(path, encoding='utf-8').read()))
used -= {'solid', 'brands', 'regular', 'light', 'thin', 'duotone'}

codes = {}
for name in sorted(used):
    # the name must end right there (".fa-eye:" not ".fa-eye-slash"); FA6 lists
    # aliases as ".fa-a:before,.fa-b:before{content:...}"
    m = re.search(r'\.fa-' + re.escape(name) + r'(?=[:,])[^{]*\{content:"\\([0-9a-f]+)"', css)
    if not m:
        sys.exit('no codepoint for fa-' + name)
    codes[name] = int(m.group(1), 16)

def subset_font(file, cps):
    font = TTFont(os.path.join(FA, file))
    cmap = font.getBestCmap()
    keep = [c for c in cps if c in cmap]
    opts = subset.Options()
    opts.flavor = 'woff2'
    opts.layout_features = []
    opts.name_IDs = []
    opts.notdef_outline = False
    sub = subset.Subsetter(opts)
    sub.populate(unicodes=keep)
    sub.subset(font)
    out = io.BytesIO()
    font.flavor = 'woff2'
    font.save(out)
    return set(keep), out.getvalue()

solid_cps, solid = subset_font('fa-solid-900.woff2', codes.values())
brand_cps, brands = subset_font('fa-brands-400.woff2', codes.values())
missing = [n for n, c in codes.items() if c not in solid_cps and c not in brand_cps]
if missing:
    sys.exit('not in either font: ' + ', '.join(missing))

rules = [
    '@font-face{font-family:"lgi-s";font-style:normal;font-weight:900;font-display:block;src:url(data:font/woff2;base64,%s) format("woff2")}' % base64.b64encode(solid).decode(),
    '@font-face{font-family:"lgi-b";font-style:normal;font-weight:400;font-display:block;src:url(data:font/woff2;base64,%s) format("woff2")}' % base64.b64encode(brands).decode(),
    '.fa-solid,.fa-brands{display:inline-block;font-style:normal;font-variant:normal;line-height:1;text-rendering:auto;-webkit-font-smoothing:antialiased}',
    '.fa-solid{font-family:"lgi-s";font-weight:900}',
    '.fa-brands{font-family:"lgi-b";font-weight:400}',
]
for name, cp in sorted(codes.items()):
    rules.append('.fa-%s:before{content:"\\%x"}' % (name, cp))

open(os.path.join(HERE, 'icons.css'), 'w', encoding='utf-8', newline='\n').write('\n'.join(rules) + '\n')
print('icons.css: %d icons, solid %d B, brands %d B' % (len(codes), len(solid), len(brands)))
