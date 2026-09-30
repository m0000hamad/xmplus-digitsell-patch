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
# By hand (a new server, or to change something):
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
        -h|--help)      sed -n '2,26p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

die() { echo "error: $*" >&2; exit 1; }
say() { echo "==> $*"; }

[ "$(id -u)" -eq 0 ] || die "run as root (sudo bash install.sh ...)"

# with nothing given and XMPlus on this server, take everything from it
if [ "$UPDATE" -eq 0 ] && [ -z "$PANEL$KEY$NODES" ] && [ ! -f "$ETC/agent.json" ]; then
    AUTO=1
fi
if [ "$AUTO" -eq 1 ] && [ -z "$FROM" ]; then
    for candidate in /etc/XMPlus/config.yml /etc/XMPlus/config.yaml /usr/local/XMPlus/config.yml /root/config.yml; do
        if [ -f "$candidate" ]; then FROM="$candidate"; break; fi
    done
    if [ -z "$FROM" ] && [ ! -f "$ETC/agent.json" ]; then
        die "no XMPlus config found (/etc/XMPlus/config.yml); give --panel, --key and --node"
    fi
fi
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
    DNS_ENV_JSON="$DNS_ENV_JSON" ETC="$ETC" python3 - <<'PY'
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
