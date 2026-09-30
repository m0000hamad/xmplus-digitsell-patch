#!/usr/bin/env python3
"""
Run on the PANEL server (not on a node), as root. Safe to run again.

Problem: with a node on the xhttp transport, pages that build a link for that
node answer "Internal Server Error": the subscription link (/link/<token>) and
the user's Servers page (/portal/servers). The panel's link builders in
app/Http/Schema/ (Xray.php, VlessURI.php, VmessURI.php, TrojanURI.php ...) read
keys such as `headerType` and `alpn` without checking they exist, and the
panel's controller leaves some of them out for xhttp. Whoops turns the PHP
notice into a fatal error, so one such node breaks every account that can see
it. The log shows:

    Undefined index: headerType   (app/Http/Schema/VlessURI.php:12)

Fix: in every builder of app/Http/Schema/, put defaults in front of build() for
the keys that file only ever reads without a check. Keys that are there are not
touched (array union), and a key the file guards anywhere is left alone, so
links of nodes that work today stay the same.

    python3 fix-panel-xhttp.py [/www/wwwroot/panel.example.com]

Each changed file is saved to /root/<name>.bak-<time> first, syntax-checked
afterwards, and put back if the check fails. A panel update that replaces these
files removes the fix; run this again then.
"""

import glob
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = sys.argv[1] if len(sys.argv) > 1 else "/www/wwwroot/panel.example.com"
SCHEMA = os.path.join(ROOT, "app/Http/Schema")
MARKER = "// digitsell: defaults"

# PHP literal each key gets when the panel left it out
DEFAULTS = [
    ("headerType", "'none'"), ("alpn", "[]"), ("mode", "'auto'"), ("path", "''"), ("host", "''"),
    ("sni", "''"), ("tls", "''"), ("fingerprint", "''"), ("flow", "''"), ("serviceName", "''"),
    ("authority", "''"), ("quic_security", "''"), ("quic_key", "''"), ("seed", "''"),
    ("allowinsecure", "0"), ("publickey", "''"), ("spiderx", "''"), ("shortid", "''"),
]
BUILD = re.compile(r"function\s+build\s*\(\s*array\s+\$item\s*\)\s*\{")


def unguarded(src, key):
    """True when every read of $item['key'] in the file is unchecked (no isset / empty / ??) and the
    file never sets it itself. A key the file guards anywhere is left alone: it already copes with the
    key being absent, and a default would change what it does for nodes that work today."""
    ref = r"\$item\[\s*['\"]%s['\"]\s*\]" % re.escape(key)
    if re.search(ref + r"\s*(?:\.|\+|-)?=(?!=)", src):
        return False
    bare = False
    for match in re.finditer(ref, src):
        before = src[max(0, match.start() - 16):match.start()]
        after = src[match.end():match.end() + 8]
        if re.search(r"(?:isset|empty)\s*\(\s*$", before) or re.match(r"\s*\?\?", after):
            return False
        bare = True
    return bare


def patch(path):
    name = os.path.basename(path)
    with open(path, encoding="utf-8", errors="surrogateescape", newline="") as handle:
        source = handle.read()
    if MARKER in source:
        return "already patched"
    found = BUILD.findall(source)
    if len(found) != 1:
        return "skipped (%d build(array $item) functions)" % len(found)
    keys = [(key, value) for key, value in DEFAULTS if unguarded(source, key)]
    if not keys:
        return "nothing to do"

    lines = ["", "        " + MARKER + " - the panel leaves keys out for some transports (xhttp); an undefined",
             "        // index is fatal here (Whoops) and breaks every page that builds this link",
             "        $item += ["]
    for key, value in keys:
        lines.append("            '%s' => %s," % (key, value))
    lines.append("        ];")
    match = BUILD.search(source)
    patched = source[:match.end()] + "\n".join(lines) + source[match.end():]

    backup = "/root/%s.bak-%d" % (name, time.time())
    shutil.copy(path, backup)
    with open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as handle:
        handle.write(patched)
    check = subprocess.run(["php", "-l", path], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           universal_newlines=True)
    if "No syntax errors" not in check.stdout:
        with open(path, "w", encoding="utf-8", errors="surrogateescape", newline="") as handle:
            handle.write(source)
        return "ERROR: syntax check failed, the original was put back: " + (check.stdout + check.stderr).strip()
    return "patched (%s) - original in %s" % (", ".join(key for key, _ in keys), backup)


def main():
    files = sorted(glob.glob(os.path.join(SCHEMA, "*.php")))
    if not files:
        sys.exit("error: no files in %s - pass the panel directory as the argument" % SCHEMA)
    failed = False
    for path in files:
        result = patch(path)
        failed = failed or result.startswith("ERROR")
        print("%-24s %s" % (os.path.basename(path), result))
    print("\ntry it: curl -sk --resolve <panel host>:443:127.0.0.1 -o /dev/null -w '%{http_code}\\n' "
          "'https://<panel host>/link/<token>?config=1'   (and open /portal/servers)")
    sys.exit(1 if failed else 0)


main()
