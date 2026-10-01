#!/usr/bin/env bash
#
# Digitsell Xray node - installs the official Xray-core and the agent that
# ties it to the XMPlus panel, in place of the XMPlus node binary.
#
# Automatic (on a server that runs XMPlus now): no options at all. The panel
# address, key, node ids, certificate settings and fallbacks are read from
# /etc/XMPlus/config.yml, XMPlus's certificates are reused, and XMPlus is
# stopped and disabled (not deleted - see "Going back" in README.md):
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh)
#
# Guided (a new server): run it with no options and answer the questions - the
# panel address and API key, then it lists the panel's servers, marks the ones
# whose domain / IP point at this machine, and asks which of them this server
# runs. Needs the Digitsell patch 1.19.0+ on the panel for the list; with an
# older panel it asks for the node ids and checks each one. --pick asks again
# on a server that is already set up (to add or drop nodes).
#
# By hand (no questions):
#
#   bash install.sh --panel https://panel.example.com --key <ApiKey> --node 74 [--node 75 ...]
#        [--email you@example.com] [--dns-provider cloudflare --dns-env CF_DNS_API_TOKEN=...]
#        [--from /path/config.yml] [--keep-xmplus] [--no-bbr] [--xray-version v26.9.30]
#
#   bash install.sh --update      new Xray, geo files, lego and agent; settings kept
#
# Options given by hand win over what --auto / config.yml says. Safe to run
# again: agent.json is merged, not replaced, so edits made there are kept.
#
# Debian / Ubuntu (apt), also RHEL-likes (dnf / yum). amd64, arm64, armv7.

set -euo pipefail
trap 'echo "error: install.sh stopped at line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

REPO_RAW="${DIGITSELL_REPO_RAW:-https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main}"
ETC=/etc/digitsell-xray
LIB=/usr/local/lib/digitsell-xray
STATE=/var/lib/digitsell-xray

PANEL=""
KEY=""
NODES=""
EMAIL=""
DNS_PROVIDER=""
DNS_ENV=()
FROM=""
AUTO=0
KEEP_XMPLUS=0
BBR=1
XRAY_VERSION="latest"
UPDATE=0
WIZARD=0
ASSUME_YES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --panel)        PANEL="$2"; shift 2 ;;
        --key)          KEY="$2"; shift 2 ;;
        --node)         NODES="$NODES ${2//,/ }"; shift 2 ;;
        --email)        EMAIL="$2"; shift 2 ;;
        --dns-provider) DNS_PROVIDER="$2"; shift 2 ;;
        --dns-env)      DNS_ENV+=("$2"); shift 2 ;;
        --from)         FROM="$2"; AUTO=1; shift 2 ;;
        --auto)         AUTO=1; shift ;;
        --keep-xmplus)  KEEP_XMPLUS=1; shift ;;
        --no-bbr)       BBR=0; shift ;;
        --xray-version) XRAY_VERSION="$2"; shift 2 ;;
        --update)       UPDATE=1; shift ;;
        --pick)         WIZARD=1; shift ;;
        --yes|-y)       ASSUME_YES=1; shift ;;
        -h|--help)      sed -n '2,33p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

die() { echo "error: $*" >&2; exit 1; }
say() { echo "==> $*"; }

[ "$(id -u)" -eq 0 ] || die "run as root (sudo bash install.sh ...)"

# questions are read from the terminal, also under `curl ... | bash`
has_tty() { [ -t 0 ] || { [ -e /dev/tty ] && (: < /dev/tty) 2>/dev/null; }; }

# with nothing given and XMPlus on this server, take everything from it
if [ "$UPDATE" -eq 0 ] && [ "$WIZARD" -eq 0 ] && [ -z "$PANEL$KEY$NODES" ] && [ ! -f "$ETC/agent.json" ]; then
    AUTO=1
fi
if [ "$AUTO" -eq 1 ] && [ -z "$FROM" ]; then
    for candidate in /etc/XMPlus/config.yml /etc/XMPlus/config.yaml /usr/local/XMPlus/config.yml /root/config.yml; do
        if [ -f "$candidate" ]; then FROM="$candidate"; break; fi
    done
    if [ -z "$FROM" ] && [ ! -f "$ETC/agent.json" ]; then
        # a new server: ask instead of giving up
        has_tty || die "no XMPlus config found (/etc/XMPlus/config.yml); give --panel, --key and --node"
        AUTO=0
        WIZARD=1
    fi
fi
# panel and key given but no node: list the panel's servers to pick from
if [ "$UPDATE" -eq 0 ] && [ "$AUTO" -eq 0 ] && [ -z "$NODES" ] && [ -n "$PANEL$KEY" ] && has_tty; then
    WIZARD=1
fi
# moving from XMPlus at a terminal: show what config.yml says, with the
# panel's server list, and ask before installing (--yes skips the questions)
if [ "$UPDATE" -eq 0 ] && [ -n "$FROM" ] && [ "$ASSUME_YES" -eq 0 ] && [ -z "$NODES" ] && has_tty; then
    WIZARD=1
fi
[ "$WIZARD" -eq 0 ] || [ "$UPDATE" -eq 0 ] || die "--pick and --update do not go together"
[ "$WIZARD" -eq 0 ] || has_tty || die "--pick needs a terminal to answer in"
[ -z "$FROM" ] || [ -f "$FROM" ] || die "--from: $FROM does not exist"

[ -z "$PANEL" ] || [[ "$PANEL" =~ ^https?://[A-Za-z0-9.:-]+(/.*)?$ ]] || die "--panel must look like https://panel.example.com"
for n in $NODES; do [[ "$n" =~ ^[0-9]+$ ]] || die "--node takes numbers (got $n)"; done
[ -z "$KEY" ] || [[ "$KEY" =~ ^[^[:space:]\"\\]{1,256}$ ]] || die "--key has characters it cannot have"
for pair in "${DNS_ENV[@]+"${DNS_ENV[@]}"}"; do
    [[ "$pair" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]] || die "--dns-env takes NAME=value (got $pair)"
done

# ---------------------------------------------------------------- packages

say "installing packages"
if command -v apt-get >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null || true
    apt-get install -y -qq curl unzip tar openssl python3 ca-certificates iproute2 >/dev/null
    if [ -n "$FROM" ]; then apt-get install -y -qq python3-yaml >/dev/null || true; fi
elif command -v dnf >/dev/null || command -v yum >/dev/null; then
    PM=$(command -v dnf || command -v yum)
    "$PM" install -y -q curl unzip tar openssl python3 ca-certificates iproute >/dev/null
    if [ -n "$FROM" ]; then "$PM" install -y -q python3-pyyaml >/dev/null || true; fi
else
    die "no apt, dnf or yum here; install curl unzip tar openssl python3 by hand and run again"
fi
command -v python3 >/dev/null || die "python3 is missing"
command -v systemctl >/dev/null || die "systemd is needed"

case "$(uname -m)" in
    x86_64|amd64)  XRAY_ARCH=64;          LEGO_ARCH=amd64 ;;
    aarch64|arm64) XRAY_ARCH=arm64-v8a;   LEGO_ARCH=arm64 ;;
    armv7l|armv7)  XRAY_ARCH=arm32-v7a;   LEGO_ARCH=armv7 ;;
    *) die "unsupported CPU: $(uname -m)" ;;
esac

# the newest release tag: the "latest" link's redirect, else the API, else
# the version this installer was last tested with
latest_tag() {
    local tag
    tag=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" 2>/dev/null | sed -n 's|.*/tag/\(v[0-9][^/]*\)$|\1|p') || true
    if [ -z "$tag" ]; then
        tag=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" 2>/dev/null \
              | sed -n 's|.*"tag_name": *"\(v[^"]*\)".*|\1|p' | head -1) || true
    fi
    echo "${tag:-$2}"
}

TMP=$(mktemp -d)
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# ------------------------------------------------------------------ wizard

if [ "$WIZARD" -eq 1 ]; then
    cat > "$TMP/wizard.py" <<'PY'
"""Guided setup: panel address and API key, then the panel's servers with the
ones pointing at this machine marked, then which of them this server runs."""
import concurrent.futures, getpass, ipaddress, json, os, re, socket, ssl, subprocess, sys
import urllib.error, urllib.parse, urllib.request

out_path, etc = sys.argv[1], sys.argv[2]
ctx = ssl.create_default_context()
UA = {"User-Agent": "digitsell-xray-installer", "Accept": "application/json"}


def ask(prompt, default=""):
    try:
        answer = input("%s%s: " % (prompt, " [%s]" % default if default else "")).strip()
    except EOFError:
        sys.exit("error: no answer (the installer needs a terminal)")
    return answer or default


def yes(prompt, default=True):
    if os.environ.get("ASSUME_YES") == "1":
        return True
    answer = ask(prompt + (" [Y/n]" if default else " [y/N]")).lower()
    return default if not answer else answer in ("y", "yes", "بله", "آره")


def http(url, body=None, headers=None, timeout=15):
    """(status, decoded JSON or None, text) - never raises for HTTP errors."""
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(url, data=data, headers=dict(UA, **(headers or {})),
                                     method="POST" if data is not None else "GET")
    if data is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=timeout, context=ctx) as response:
            status, raw = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, raw = error.code, error.read()
    except Exception as error:  # unreachable, bad address, TLS - all reported, none fatal
        return 0, None, str(getattr(error, "reason", error))
    text = raw.decode("utf-8", "replace")
    try:
        return status, json.loads(text), text
    except ValueError:
        return status, None, text


def normalize(address):
    address = address.strip().rstrip("/")
    if address and not re.match(r"^https?://", address):
        address = "https://" + address
    return address


def node_settings(panel, key, node_id):
    """The node's own settings from the panel's node API, or None."""
    status, data, _ = http("%s/api/server/%d?key=%s" % (panel, node_id, urllib.parse.quote(key, safe="")), timeout=12)
    if status != 200 or not isinstance(data, dict) or not isinstance(data.get("server"), dict):
        return None
    return data["server"]


def obj(value):
    if isinstance(value, dict):
        return value
    try:
        value = json.loads(value or "{}")
        return value if isinstance(value, dict) else {}
    except (TypeError, ValueError):
        return {}


def describe(server):
    net, sec = obj(server.get("networkSettings")), obj(server.get("securitySettings"))
    kind = str(server.get("type") or "?").lower()
    transport = str(net.get("transport") or "tcp").lower()
    security = str(server.get("security") or "none").lower()
    return {"kind": kind, "transport": transport, "security": security,
            "port": str(server.get("listeningport") or "?"),
            "certmode": str(server.get("certmode") or "none").lower(),
            "domain": str(sec.get("serverName") or "").strip()}


def my_addresses():
    found = set()
    for url in ("https://api.ipify.org", "https://api6.ipify.org"):
        status, _, text = http(url, timeout=6)
        if status == 200 and text.strip():
            found.add(text.strip())
    try:
        out = subprocess.run(["hostname", "-I"], stdout=subprocess.PIPE, universal_newlines=True, timeout=5).stdout
        found.update(out.split())
    except (OSError, subprocess.TimeoutExpired):
        pass
    clean = set()
    for item in found:
        try:
            clean.add(str(ipaddress.ip_address(item.split("%")[0])))
        except ValueError:
            pass
    return clean


def resolve(name):
    try:
        return {str(ipaddress.ip_address(name))}
    except ValueError:
        pass
    try:
        return {info[4][0].split("%")[0] for info in socket.getaddrinfo(name, None)}
    except (OSError, UnicodeError):
        return set()


# ----------------------------------------------------------- panel and key

panel = normalize(os.environ.get("PANEL", ""))
key = os.environ.get("KEY", "")
from_ids = []
cert_files = {}   # node id -> (certificate, key) already known for it

# moving from XMPlus: its config.yml gives the defaults
if os.environ.get("FROM"):
    try:
        import yaml
        with open(os.environ["FROM"]) as handle:
            xm = yaml.safe_load(handle) or {}
        for item in xm.get("Nodes") or []:
            api = (item or {}).get("ApiConfig") or {}
            cert = ((item or {}).get("ControllerConfig") or {}).get("CertConfig") or {}
            nid = int(api.get("NodeID") or 0)
            if nid <= 0:
                continue
            from_ids.append(nid)
            panel = panel or normalize(str(api.get("ApiHost") or ""))
            key = key or str(api.get("ApiKey") or "")
            if cert.get("CertFile") and cert.get("KeyFile"):
                cert_files[nid] = (str(cert["CertFile"]), str(cert["KeyFile"]))
        print("Found XMPlus settings in %s: node(s) %s" % (os.environ["FROM"], ", ".join(map(str, from_ids)) or "none"))
    except Exception as error:  # an unreadable config.yml only loses the defaults
        print("note: could not read %s (%s); answer the questions instead" % (os.environ["FROM"], error))

agent_json = os.path.join(etc, "agent.json")
if os.path.isfile(agent_json):
    try:
        with open(agent_json) as handle:
            for item in json.load(handle).get("nodes") or []:
                if isinstance(item, dict) and item.get("cert_file") and item.get("key_file"):
                    cert_files[int(item["id"])] = (item["cert_file"], item["key_file"])
    except (OSError, ValueError, TypeError, KeyError):
        pass

print()
print("Panel connection. Use the panel's own address, not one behind a CDN.")
servers = None
while True:
    panel = normalize(ask("Panel address (e.g. https://origin.example.com)", panel))
    if not re.match(r"^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[^\s]*)?$", panel):
        print("  that is not a web address")
        panel = ""
        continue
    if not key:
        key = getpass.getpass("Panel API key (the ApiKey in the panel's API settings; not shown): ").strip()
    if not key:
        continue
    status, data, text = http(panel + "/xmplus-patch.php?do=node.list", body={}, headers={"X-Panel-Key": key})
    if status == 0:
        print("  cannot reach %s: %s" % (panel, text))
        continue
    if isinstance(data, dict) and data.get("ok") and isinstance(data.get("servers"), list):
        servers = data["servers"]
        break
    if status == 403 and isinstance(data, dict) and "key" in str(data.get("error")):
        print("  the panel refused this key - check it in the panel's API settings")
        key = ""
        continue
    # an older patch, or none: no list, the ids are asked for and checked one by one
    print("  this panel cannot list its servers (Digitsell patch 1.19.0 or later needed); node ids are asked for instead")
    break

# ------------------------------------------------------------ the servers

mine = my_addresses()
print()
print("This server: %s" % (", ".join(sorted(mine)) or "address unknown"))

rows = {}
if servers is not None:
    print("Reading %d server(s) from the panel..." % len(servers))
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        settings = dict(zip([s["id"] for s in servers],
                            pool.map(lambda s: node_settings(panel, key, int(s["id"])), servers)))
        names = set()
        for s in servers:
            names.update(s.get("addresses") or [])
        for nid, conf in settings.items():
            if conf:
                names.add(describe(conf)["domain"])
        names.discard("")
        resolved = dict(zip(names, pool.map(resolve, names)))
    for s in servers:
        nid = int(s["id"])
        conf = settings.get(nid)
        info = describe(conf) if conf else None
        addresses = list(s.get("addresses") or [])
        if info and info["domain"] and info["domain"] not in addresses:
            addresses.append(info["domain"])
        here = any(resolved.get(a, set()) & mine for a in addresses)
        rows[nid] = {"name": s.get("name") or "", "enabled": s.get("enabled"), "info": info,
                     "addresses": addresses, "here": here}
    if not rows:
        sys.exit("error: the panel has no servers yet - add one in the panel first")
    print()
    print("  %-5s %-22s %-24s %-7s %-34s %s" % ("ID", "NAME", "PROTOCOL", "PORT", "ADDRESS", "HERE"))
    for nid in sorted(rows):
        r = rows[nid]
        info = r["info"]
        proto = "%s %s %s" % (info["kind"], info["transport"], info["security"]) if info else "(no settings)"
        flag = "yes" if r["here"] else ""
        if r["enabled"] is False:
            flag = (flag + " (off)").strip()
        print("  %-5d %-22s %-24s %-7s %-34s %s" % (nid, r["name"][:22], proto[:24],
              info["port"] if info else "-", " ".join(r["addresses"])[:34], flag))
    print()
    print('"HERE" = the server\'s domain / IP in the panel points at this machine.')

# -------------------------------------------------------- pick the nodes

preset = [int(n) for n in os.environ.get("NODES", "").split() if n.isdigit()] or from_ids
if not preset and os.path.isfile(os.path.join(etc, "agent.json")):
    try:
        with open(os.path.join(etc, "agent.json")) as handle:
            preset = [n if isinstance(n, int) else int(n.get("id")) for n in json.load(handle).get("nodes") or []]
    except (OSError, ValueError, TypeError):
        preset = []
default = preset or sorted(n for n in rows if rows[n]["here"])

while True:
    answer = ask("Node id(s) this server runs, comma separated", ",".join(map(str, default)))
    try:
        chosen = list(dict.fromkeys(int(x) for x in re.split(r"[\s,]+", answer) if x))
    except ValueError:
        print("  numbers only, e.g. 69,74")
        continue
    if not chosen:
        continue
    problems = []
    for nid in chosen:
        if rows and nid not in rows:
            problems.append("%d is not a server of this panel" % nid)
        elif not rows:
            conf = node_settings(panel, key, nid)
            if conf is None:
                problems.append("node %d: the panel does not give its settings (wrong id, or wrong key?)" % nid)
            else:
                rows[nid] = {"name": "", "enabled": None, "info": describe(conf), "addresses": [], "here": False}
        elif rows[nid]["info"] is None:
            problems.append("node %d: the panel does not give its settings (switched off, or no type set?)" % nid)
    if problems:
        for p in problems:
            print("  " + p)
        continue
    break

# ------------------------------------------------------------ the checks

warnings = []
ports = {}
for nid in chosen:
    info = rows[nid]["info"]
    ports.setdefault(info["port"], []).append(nid)
for port, ids in ports.items():
    if len(ids) > 1:
        warnings.append("nodes %s all use port %s - only one of them can listen on it" % (", ".join(map(str, ids)), port))
try:
    listening = subprocess.run(["ss", "-Htlnp"], stdout=subprocess.PIPE, universal_newlines=True, timeout=5).stdout
except (OSError, subprocess.TimeoutExpired):
    listening = ""
for port in ports:
    for line in listening.splitlines():
        if re.search(r":%s\s" % re.escape(port), line) and not re.search(r"xray|XMPlus", line, re.I):
            warnings.append("port %s is already taken on this server: %s" % (port, line.split()[-1] if line.split() else "?"))
            break

needs_email = needs_dns = False
for nid in chosen:
    info = rows[nid]["info"]
    if info["security"] != "tls":
        continue
    if info["certmode"] in ("http", "tls", "dns"):
        needs_email = True
    if info["certmode"] == "dns":
        needs_dns = True
    if info["certmode"] in ("http", "tls") and info["domain"]:
        if not (resolve(info["domain"]) & mine):
            warnings.append("node %d: %s does not point at this server yet, so its certificate (mode %s) cannot be issued"
                            % (nid, info["domain"], info["certmode"]))
    if info["certmode"] == "file":
        known = cert_files.get(nid)
        if known and os.path.isfile(known[0]) and os.path.isfile(known[1]):
            continue
        standard = os.path.join(etc, "certs", (info["domain"] or "-") + ".crt")
        if os.path.isfile(standard) and os.path.isfile(standard[:-4] + ".key"):
            continue
        # certificate files already on this server, newest first, as the suggestion
        found = []
        for folder in ("/root", "/etc/XMPlus", "/etc/ssl/private", "/etc/letsencrypt/live/" + (info["domain"] or "-")):
            try:
                for name in os.listdir(folder):
                    if name.endswith((".crt", ".pem", ".cer")) and "key" not in name.lower():
                        found.append(os.path.join(folder, name))
            except OSError:
                pass
        found.sort(key=lambda p: -os.path.getmtime(p))
        print("Node %d (%s) uses certificate mode 'file'.%s" % (nid, info["domain"] or "no domain",
              (" Found: " + ", ".join(found[:5])) if found else ""))
        while True:
            crt = ask("  certificate file (Enter to set it later)", found[0] if found else "")
            if not crt:
                warnings.append("node %d: no certificate file yet - put %s.crt / .key in %s/certs, or set cert_file / key_file in agent.json"
                                % (nid, info["domain"] or "<domain>", etc))
                break
            guess = re.sub(r"(fullchain|cert)?\.(crt|pem|cer)$", "", crt)
            guesses = [guess + ext for ext in (".key", "privkey.pem", "-key.pem", ".key.pem")]
            if crt.endswith("fullchain.pem"):
                guesses.insert(0, crt[:-len("fullchain.pem")] + "privkey.pem")
            key_file = ask("  its key file", next((g for g in guesses if os.path.isfile(g)), ""))
            if os.path.isfile(crt) and os.path.isfile(key_file):
                cert_files[nid] = (crt, key_file)
                break
            print("  one of these files does not exist")

email = os.environ.get("EMAIL", "")
dns_provider = os.environ.get("DNS_PROVIDER", "")
dns_env = [x for x in os.environ.get("DNS_ENV_LINES", "").split("\n") if x]
if needs_email and not email:
    email = ask("E-mail for Let's Encrypt certificates (Enter to skip)")
if needs_dns and not dns_provider:
    print("A node issues its certificate by DNS (cert mode dns): give the DNS provider as lego names it")
    print("(e.g. cloudflare, see 'lego dnshelp') and its keys as NAME=value, one per line, an empty line ends.")
    dns_provider = ask("DNS provider")
    while dns_provider:
        line = ask("  NAME=value")
        if not line:
            break
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*=.+$", line):
            print("  NAME=value, e.g. CF_DNS_API_TOKEN=xxxx")
            continue
        dns_env.append(line)

# ---------------------------------------------------------------- summary

print()
print("Summary")
print("  panel : %s" % panel)
print("  key   : %s...%s" % (key[:3], key[-2:]) if len(key) > 6 else "  key   : (set)")
for nid in chosen:
    r = rows[nid]
    info = r["info"]
    print("  node %-4d %-20s %s %s %s port %s%s" % (nid, r["name"][:20], info["kind"], info["transport"], info["security"],
          info["port"], " (%s)" % info["domain"] if info["domain"] else ""))
    if nid in cert_files and info["certmode"] == "file":
        print("            certificate %s" % cert_files[nid][0])
for w in warnings:
    print("  warning: " + w)
if not yes("Install the Xray node for these on this server?"):
    sys.exit("stopped - nothing was changed")

with open(out_path, "w") as handle:
    json.dump({"panel": panel, "key": key, "nodes": chosen, "email": email,
               "dns_provider": dns_provider, "dns_env": dns_env,
               "files": {str(n): list(cert_files[n]) for n in chosen if n in cert_files}}, handle)
PY
    # a --pick on a set-up server starts from what agent.json has
    if [ -f "$ETC/agent.json" ]; then
        [ -n "$PANEL" ] || PANEL=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("panel", ""))' "$ETC/agent.json" 2>/dev/null || true)
        [ -n "$KEY" ] || KEY=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("key", ""))' "$ETC/agent.json" 2>/dev/null || true)
    fi
    DNS_ENV_LINES=$(printf '%s\n' "${DNS_ENV[@]+"${DNS_ENV[@]}"}")
    if [ -t 0 ]; then WIZ_IN=/dev/stdin; else WIZ_IN=/dev/tty; fi
    FROM="$FROM" PANEL="$PANEL" KEY="$KEY" NODES="$NODES" EMAIL="$EMAIL" DNS_PROVIDER="$DNS_PROVIDER" \
    DNS_ENV_LINES="$DNS_ENV_LINES" ASSUME_YES="$ASSUME_YES" python3 "$TMP/wizard.py" "$TMP/wizard.json" "$ETC" < "$WIZ_IN" || exit 1
    [ -f "$TMP/wizard.json" ] || exit 1
    wiz() { python3 -c 'import json,sys; v = json.load(open(sys.argv[1]))[sys.argv[2]]; print("\n".join(map(str, v)) if isinstance(v, list) else v)' "$TMP/wizard.json" "$1"; }
    PANEL=$(wiz panel)
    KEY=$(wiz key)
    NODES=$(wiz nodes | tr '\n' ' ')
    EMAIL=$(wiz email)
    DNS_PROVIDER=$(wiz dns_provider)
    DNS_ENV=()
    while IFS= read -r line; do [ -z "$line" ] || DNS_ENV+=("$line"); done < <(wiz dns_env)
    NODE_FILES_JSON=$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])).get("files", {})))' "$TMP/wizard.json")
    [ -n "$PANEL" ] && [ -n "$KEY" ] && [ -n "$NODES" ] || die "the questions did not give a panel, key and node"
    [[ "$PANEL" =~ ^https?://[A-Za-z0-9.:-]+(/.*)?$ ]] || die "the panel address does not look right: $PANEL"
    [[ "$KEY" =~ ^[^[:space:]\"\\]{1,256}$ ]] || die "the key has characters it cannot have"
    echo
fi

mkdir -p "$ETC" "$LIB" "$STATE" "$ETC/certs"
chmod 700 "$ETC" "$STATE"

# -------------------------------------------------------------------- xray

if [ "$XRAY_VERSION" = "latest" ]; then
    XRAY_VERSION=$(latest_tag XTLS/Xray-core v26.9.30)
fi
CURRENT=$("$LIB/xray" version 2>/dev/null | awk 'NR==1 {print "v" $2}') || true
if [ "$CURRENT" = "$XRAY_VERSION" ]; then
    say "Xray $XRAY_VERSION is already installed"
else
    say "downloading Xray $XRAY_VERSION ($XRAY_ARCH)"
    base="https://github.com/XTLS/Xray-core/releases/download/$XRAY_VERSION/Xray-linux-$XRAY_ARCH.zip"
    curl -fsSL --retry 3 -o "$TMP/xray.zip" "$base" || die "download failed: $base"
    if curl -fsSL --retry 3 -o "$TMP/xray.zip.dgst" "$base.dgst" 2>/dev/null; then
        want=$(awk -F'= ' '/256=/ {print $2; exit}' "$TMP/xray.zip.dgst")
        have=$(sha256sum "$TMP/xray.zip" | awk '{print $1}')
        [ -z "$want" ] || [ "$want" = "$have" ] || die "Xray download checksum does not match"
    fi
    unzip -o -q "$TMP/xray.zip" -d "$TMP/xray"
    install -m 755 "$TMP/xray/xray" "$LIB/xray.new"
    "$LIB/xray.new" version >/dev/null || die "the downloaded Xray does not run on this server"
    mv -f "$LIB/xray.new" "$LIB/xray"
    install -m 644 "$TMP/xray/geoip.dat" "$TMP/xray/geosite.dat" "$LIB/"
fi

# -------------------------------------------------------------------- lego

LEGO_VERSION=$(latest_tag go-acme/lego v5.5.2)
LEGO_CURRENT=$("$LIB/lego" --version 2>/dev/null | awk '{print "v" $3}') || true
if [ -n "$LEGO_VERSION" ] && [ "$LEGO_CURRENT" != "$LEGO_VERSION" ]; then
    say "downloading lego $LEGO_VERSION (Let's Encrypt certificates)"
    file="lego_${LEGO_VERSION}_linux_${LEGO_ARCH}.tar.gz"
    if curl -fsSL --retry 3 -o "$TMP/lego.tgz" "https://github.com/go-acme/lego/releases/download/$LEGO_VERSION/$file"; then
        if curl -fsSL -o "$TMP/lego.sums" "https://github.com/go-acme/lego/releases/download/$LEGO_VERSION/lego_${LEGO_VERSION#v}_checksums.txt" 2>/dev/null; then
            want=$(awk -v f="$file" '$2 == f {print $1}' "$TMP/lego.sums")
            have=$(sha256sum "$TMP/lego.tgz" | awk '{print $1}')
            [ -z "$want" ] || [ "$want" = "$have" ] || die "lego download checksum does not match"
        fi
        tar -xzf "$TMP/lego.tgz" -C "$TMP" lego
        install -m 755 "$TMP/lego" "$LIB/lego"
    else
        echo "warning: lego could not be downloaded; TLS nodes with cert mode http/tls/dns get a self-signed certificate until 'digitsell-xray update'" >&2
    fi
fi

# ------------------------------------------------------------ agent files

say "installing the agent"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo /nonexistent)"
for f in xray-agent.py digitsell-xray uninstall.sh; do
    if [ -f "$HERE/$f" ] && [ "${DIGITSELL_FROM_REPO:-0}" != "1" ]; then
        cp "$HERE/$f" "$TMP/$f"
    else
        curl -fsSL --retry 3 -o "$TMP/$f" "$REPO_RAW/node/xray/$f" || die "cannot download $f from $REPO_RAW"
    fi
done
python3 -m py_compile "$TMP/xray-agent.py" || die "the downloaded agent is broken"
install -m 755 "$TMP/xray-agent.py" "$LIB/xray-agent.py"
install -m 755 "$TMP/uninstall.sh" "$LIB/uninstall.sh"
install -m 755 "$TMP/digitsell-xray" /usr/local/bin/digitsell-xray
ln -sf /usr/local/bin/digitsell-xray /usr/local/bin/dxray

# ----------------------------------------------------------- agent.json

if [ "$UPDATE" -eq 0 ]; then
    say "writing $ETC/agent.json"
    DNS_ENV_JSON=$(python3 -c 'import json,sys; print(json.dumps(dict(a.split("=",1) for a in sys.argv[1:])))' "${DNS_ENV[@]+"${DNS_ENV[@]}"}")
    FROM="$FROM" PANEL="$PANEL" KEY="$KEY" NODES="$NODES" EMAIL="$EMAIL" DNS_PROVIDER="$DNS_PROVIDER" \
    DNS_ENV_JSON="$DNS_ENV_JSON" NODE_FILES_JSON="${NODE_FILES_JSON:-}" ETC="$ETC" python3 - <<'PY'
import json, os, sys

etc = os.environ["ETC"]
path = etc + "/agent.json"
conf = {}
if os.path.isfile(path):
    with open(path) as f:
        conf = json.load(f)

def from_xmplus(file):
    try:
        import yaml
    except ImportError:
        sys.exit("error: python3-yaml is needed to read %s (apt install python3-yaml), or give --panel/--key/--node" % file)
    with open(file) as f:
        y = yaml.safe_load(f) or {}
    out = {"nodes": [], "cert": {}, "policy": {}}
    cc = y.get("ConnectionConfig") or {}
    for src, dst in (("Handshake", "handshake"), ("ConnIdle", "connIdle"), ("UplinkOnly", "uplinkOnly"),
                     ("DownlinkOnly", "downlinkOnly"), ("BufferSize", "bufferSize")):
        if isinstance(cc.get(src), int) and cc.get(src) > 0:
            out["policy"][dst] = cc[src]
    dns_path = y.get("DnsConfigPath")
    hosts = set()
    for n in y.get("Nodes") or []:
        api = (n or {}).get("ApiConfig") or {}
        ctl = (n or {}).get("ControllerConfig") or {}
        node = {"id": int(api.get("NodeID") or 0)}
        if node["id"] <= 0:
            continue
        node["panel"] = str(api.get("ApiHost") or "").rstrip("/")
        node["key"] = str(api.get("ApiKey") or "")
        hosts.add((node["panel"], node["key"]))
        cert = ctl.get("CertConfig") or {}
        if cert.get("Email") and cert.get("Email") != "author@xmplus.dev":
            out["cert"]["email"] = cert["Email"]
        if cert.get("Provider") and any(v for v in (cert.get("CertEnv") or {}).values()):
            out["cert"]["provider"] = cert["Provider"]
            out["cert"]["env"] = {k: str(v) for k, v in (cert.get("CertEnv") or {}).items() if v not in (None, "")}
        for src, dst in (("CertFile", "cert_file"), ("KeyFile", "key_file")):
            if cert.get(src) and os.path.isfile(cert[src]):
                node[dst] = cert[src]
        if ctl.get("EnableFallback"):
            fbs = []
            for fb in ctl.get("FallBackConfigs") or []:
                item = {"dest": fb.get("Dest")}
                for s, d in (("SNI", "name"), ("Alpn", "alpn"), ("Path", "path"), ("ProxyProtocolVer", "xver")):
                    if fb.get(s) not in (None, "", 0):
                        item[d] = fb[s]
                if item["dest"] not in (None, ""):
                    fbs.append(item)
            if fbs:
                node["fallbacks"] = fbs
        rules = api.get("RuleListPath")
        if rules and os.path.isfile(rules) and os.path.getsize(rules) > 0:
            out["block_regex_file"] = rules
        if ctl.get("EnableDNS") and dns_path and os.path.isfile(dns_path):
            try:
                with open(dns_path) as f:
                    out["dns"] = json.load(f)
                if ctl.get("DNSStrategy") and ctl["DNSStrategy"] != "AsIs":
                    out["domain_strategy"] = ctl["DNSStrategy"]
            except ValueError:
                pass
        out["nodes"].append(node)
    if not out["nodes"]:
        sys.exit("error: no nodes with a NodeID in %s" % file)
    # one panel and key for all: keep them top level, nodes as plain ids
    if len(hosts) == 1:
        out["panel"], out["key"] = hosts.pop()
        simple = []
        for n in out["nodes"]:
            rest = {k: v for k, v in n.items() if k not in ("panel", "key")}
            simple.append(rest if len(rest) > 1 else n["id"])
        out["nodes"] = simple
    return out

if os.environ.get("FROM"):
    found = from_xmplus(os.environ["FROM"])
    print("    from %s: panel %s, node(s) %s" % (os.environ["FROM"], found.get("panel") or "per node",
          ", ".join(str(n if isinstance(n, int) else n["id"]) for n in found["nodes"])))
    for k in ("panel", "key", "nodes", "block_regex_file", "dns", "domain_strategy"):
        if k in found:
            conf[k] = found[k]
    if found["policy"]:
        conf.setdefault("policy", {}).update(found["policy"])
    if found["cert"]:
        conf.setdefault("cert", {}).update(found["cert"])

if os.environ.get("PANEL"):
    conf["panel"] = os.environ["PANEL"].rstrip("/")
if os.environ.get("KEY"):
    conf["key"] = os.environ["KEY"]
ids = [int(n) for n in os.environ.get("NODES", "").split()]
if ids:
    keep = {n["id"]: n for n in conf.get("nodes", []) if isinstance(n, dict)}
    conf["nodes"] = [keep.get(i, i) for i in dict.fromkeys(ids)]
# certificate files picked in the questions (cert mode "file")
files = json.loads(os.environ.get("NODE_FILES_JSON") or "{}")
if files:
    nodes = []
    for n in conf.get("nodes", []):
        node = dict(n) if isinstance(n, dict) else {"id": n}
        pair = files.get(str(node["id"]))
        if pair:
            node["cert_file"], node["key_file"] = pair[0], pair[1]
        nodes.append(node if len(node) > 1 else node["id"])
    conf["nodes"] = nodes
cert = conf.setdefault("cert", {})
if os.environ.get("EMAIL"):
    cert["email"] = os.environ["EMAIL"]
if os.environ.get("DNS_PROVIDER"):
    cert["provider"] = os.environ["DNS_PROVIDER"]
env = json.loads(os.environ.get("DNS_ENV_JSON") or "{}")
if env:
    cert.setdefault("env", {}).update(env)
if not cert:
    conf.pop("cert")

if not conf.get("nodes"):
    sys.exit("error: no node ids - give --node")
if not conf.get("panel") and not all(isinstance(n, dict) and n.get("panel") for n in conf["nodes"]):
    sys.exit("error: no panel address - give --panel")
if not conf.get("key") and not all(isinstance(n, dict) and n.get("key") for n in conf["nodes"]):
    sys.exit("error: no node key - give --key (the ApiKey from the panel)")

conf.setdefault("interval", 60)
conf.setdefault("block_private", True)
conf.setdefault("block_bittorrent", False)
conf.setdefault("ip_limit", True)
conf.setdefault("log_level", "warning")

tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(conf, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.chmod(tmp, 0o600)
os.replace(tmp, path)
PY
fi
[ -f "$ETC/agent.json" ] || die "no $ETC/agent.json - run once without --update"

# XMPlus's Let's Encrypt certificates and account, so nothing is issued again
if [ -n "$FROM" ] && [ ! -d "$ETC/lego/certificates" ]; then
    for dir in "$(dirname "$FROM")/cert" /usr/local/XMPlus/cert /etc/XMPlus/cert; do
        if [ -d "$dir/certificates" ]; then
            say "reusing XMPlus certificates from $dir"
            mkdir -p "$ETC/lego"
            cp -a "$dir/." "$ETC/lego/"
            [ -x "$LIB/lego" ] && "$LIB/lego" migrate --path "$ETC/lego" >/dev/null 2>&1 || true
            break
        fi
    done
fi

# ------------------------------------------------------------ services

# Xray needs a config to start; the agent replaces this within seconds
if [ ! -f "$ETC/xray.json" ]; then
    API=$(python3 -c 'import json; print(json.load(open("'"$ETC"'/agent.json")).get("api", "127.0.0.1:10085"))')
    cat > "$ETC/xray.json" <<EOF
{"log": {"loglevel": "warning"}, "api": {"tag": "api", "listen": "$API", "services": ["HandlerService", "StatsService", "RoutingService", "LoggerService"]}, "stats": {}, "outbounds": [{"protocol": "freedom"}]}
EOF
    chmod 600 "$ETC/xray.json"
fi

cat > /etc/systemd/system/digitsell-xray.service <<EOF
[Unit]
Description=Xray-core (Digitsell node)
Documentation=https://github.com/m0000hamad/xmplus-digitsell-patch/tree/main/node/xray
After=network-online.target
Wants=network-online.target

[Service]
Environment=XRAY_LOCATION_ASSET=$LIB
ExecStart=$LIB/xray run -c $ETC/xray.json
Restart=always
RestartSec=3
LimitNOFILE=1048576
LimitNPROC=65535

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/digitsell-xray-agent.service <<EOF
[Unit]
Description=Digitsell Xray agent (XMPlus panel sync)
After=network-online.target digitsell-xray.service
Wants=network-online.target

[Service]
Environment=XRAY_LOCATION_ASSET=$LIB
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/env python3 $LIB/xray-agent.py run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# XMPlus would hold the same ports
if [ "$UPDATE" -eq 0 ]; then
    for unit in XMPlus xmplus; do
        if systemctl list-unit-files "$unit.service" 2>/dev/null | grep -q "^$unit.service"; then
            if [ "$KEEP_XMPLUS" -eq 1 ]; then
                echo "warning: $unit is left running (--keep-xmplus); it and this node must not use the same ports" >&2
            elif systemctl is-active --quiet "$unit" || systemctl is-enabled --quiet "$unit" 2>/dev/null; then
                say "stopping and disabling $unit (kept on disk; 'systemctl enable --now $unit' brings it back)"
                systemctl disable --now "$unit" >/dev/null 2>&1 || true
            fi
        fi
    done
fi

# --------------------------------------------------------------- system

if [ "$BBR" -eq 1 ] && [ "$UPDATE" -eq 0 ]; then
    modprobe tcp_bbr 2>/dev/null || true
    if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
        say "turning on BBR and network tuning"
        cat > /etc/sysctl.d/99-digitsell-xray.conf <<'EOF'
# written by digitsell-xray install.sh (--no-bbr leaves it out)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.ip_local_port_range = 10240 65000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
fs.file-max = 1048576
EOF
        sysctl --system >/dev/null 2>&1 || true
    else
        echo "note: this kernel has no BBR; skipped (the OS is too old or a container)" >&2
    fi
fi
# VMess and REALITY refuse clients whose clock is off
timedatectl set-ntp true >/dev/null 2>&1 || true

systemctl daemon-reload
systemctl enable digitsell-xray digitsell-xray-agent >/dev/null 2>&1
if [ "$UPDATE" -eq 1 ]; then
    # the agent never drops connections; Xray restarts once for the new binary
    say "restarting"
    systemctl restart digitsell-xray-agent
    [ "$CURRENT" = "$XRAY_VERSION" ] || systemctl restart digitsell-xray
else
    systemctl restart digitsell-xray
    systemctl restart digitsell-xray-agent
fi

# ---------------------------------------------------------------- check

say "asking the panel about the node(s)"
if ! python3 "$LIB/xray-agent.py" check; then
    echo >&2
    echo "warning: some node could not be read from the panel - see above. Fix agent.json ($ETC/agent.json)" >&2
    echo "         or run this installer again with --panel / --key / --node, then: digitsell-xray restart" >&2
fi

# open the node ports when ufw is on
if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    for port in $(python3 "$LIB/xray-agent.py" render 2>/dev/null | python3 -c 'import json,sys
for i in json.load(sys.stdin).get("inbounds", []): print(str(i.get("port")).replace("-", ":"))' 2>/dev/null); do
        ufw allow "$port/tcp" >/dev/null 2>&1 || true
        ufw allow "$port/udp" >/dev/null 2>&1 || true
    done
fi

sleep 5
echo
say "done - Xray $("$LIB/xray" version | awk 'NR==1 {print $2}'), agent $(python3 "$LIB/xray-agent.py" version)"
echo "    digitsell-xray status    what runs, accounts, online, certificates"
echo "    digitsell-xray log       live log (agent + Xray)"
echo "    digitsell-xray doctor    check everything"
echo "    digitsell-xray update    newest Xray and agent"
