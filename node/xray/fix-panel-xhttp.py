#!/usr/bin/env python3
"""
Run on the PANEL server (not on a node), once, as root.

Problem: with a node on the xhttp transport, every subscription link the panel
builds for an account that can see that node answers "Internal Server Error".
The panel's own link builder, app/Http/Schema/Xray.php, reads keys such as
`headerType` and `alpn` without checking they exist, and its controller leaves
them out for xhttp. Whoops turns the PHP notice into a fatal error, so one such
node breaks the subscription of every account that can see it. The log shows:

    Undefined index: headerType   (app/Http/Schema/Xray.php:85)

Fix: put defaults for the keys that may be missing at the top of
Xray::build(). Keys that are there are not touched (array union), so nodes that
work today produce the same links.

    python3 fix-panel-xhttp.py [/www/wwwroot/p.digitsell-shop.ir]

Safe to run again (it says "already patched"). The original is saved to
/root/Xray.php.bak-<time>, the result is syntax-checked, and the original is
put back if the check fails. A panel update that replaces Xray.php removes the
fix; run this again then.
"""

import os
import shutil
import subprocess
import sys
import time

ROOT = sys.argv[1] if len(sys.argv) > 1 else "/www/wwwroot/p.digitsell-shop.ir"
PATH = os.path.join(ROOT, "app/Http/Schema/Xray.php")
MARKER = "// digitsell: defaults"
ANCHOR = "$return = null;\n"

BLOCK = ANCHOR + "                " + MARKER + """ - the panel leaves some keys out for some transports (xhttp);
                // an undefined index is fatal here (Whoops), which breaks every subscription link
                $item += [
                        'headerType' => 'none', 'alpn' => [], 'mode' => 'auto', 'path' => '', 'host' => '',
                        'sni' => '', 'tls' => '', 'fingerprint' => '', 'flow' => '', 'serviceName' => '',
                        'authority' => '', 'quic_security' => '', 'quic_key' => '', 'seed' => '',
                        'allowinsecure' => 0,
                ];
"""


def main():
    if not os.path.isfile(PATH):
        sys.exit("error: %s not found - pass the panel directory as the argument" % PATH)

    source = open(PATH).read()
    if MARKER in source:
        print("already patched")
        return
    if source.count(ANCHOR) != 1:
        sys.exit("error: the file is not the version this script knows (found %d anchors); nothing changed"
                 % source.count(ANCHOR))

    # next to nothing else in the app directory: the settings page treats stray files as locales
    backup = "/root/Xray.php.bak-%d" % time.time()
    shutil.copy(PATH, backup)
    with open(PATH, "w") as handle:  # rewrite in place: owner and mode stay as they are
        handle.write(source.replace(ANCHOR, BLOCK, 1))

    check = subprocess.run(["php", "-l", PATH], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           universal_newlines=True)
    if "No syntax errors" not in check.stdout:
        with open(PATH, "w") as handle:
            handle.write(source)
        sys.exit("error: syntax check failed, the original was put back:\n" + (check.stdout + check.stderr))

    print("patched; original saved to " + backup)
    print("try it: curl -sk --resolve <panel host>:443:127.0.0.1 -o /dev/null -w '%{http_code}\\n' "
          "'https://<panel host>/link/<token>?config=1'")


main()
