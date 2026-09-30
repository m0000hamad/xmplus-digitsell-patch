#!/usr/bin/env python3
"""
Digitsell Xray node - runs the official Xray-core for the XMPlus panel, in
place of the XMPlus node binary (XMPlusDev/XMPlus).

It speaks the panel's own node API, the one the XMPlus binary uses, so the
panel needs no change and servers are still edited in the panel:

  GET  /api/server/<node>          inbound settings (ETag, 304 when unchanged)
  GET  /api/subscriptions/<node>   the accounts that may use the node
  POST /api/traffic/<node>         usage per account since the last report
  POST /api/onlineip/<node>        the addresses each account is online from

Xray itself is the unmodified release from XTLS/Xray-core and runs as its own
service (digitsell-xray), so updating Xray is replacing one file, and this
agent restarting or being updated never drops a customer's connection:

  * the Xray config (/etc/digitsell-xray/xray.json) is generated from the
    panel; Xray is restarted only when a node's settings change;
  * accounts added or removed in the panel are added to / removed from the
    running Xray through its API (xray api adu / rmu) - no restart;
  * usage is read and reset from Xray's counters every minute and sent to
    the panel; what the panel did not accept is kept on disk and sent with
    the next report, so a panel outage loses no traffic;
  * the device limit (the panel's IP limit) is enforced here: addresses past
    an account's limit get a routing rule to the blackhole outbound;
  * TLS certificates come from Let's Encrypt through lego (http, tls or dns
    challenge, as the node's cert mode in the panel says) and are renewed
    here; Xray re-reads them by itself, again without a restart.

If the panel cannot be reached the last answers kept on disk are used, so a
reboot during a panel outage still brings every node up with its accounts.

Python 3.6+, standard library only. Configuration: /etc/digitsell-xray/agent.json
(written by install.sh; see README.md for every option).

Usage:
  xray-agent.py [run] [--config PATH]   the service
  xray-agent.py check                   ask the panel about every node, print what would run
  xray-agent.py render                  print the Xray config that would be generated
  xray-agent.py status                  what the running agent last saw
  xray-agent.py doctor                  check this server end to end
"""

import base64
import copy
import hashlib
import json
import os
import re
import shutil
import signal
import socket
import ssl
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid as uuidlib

VERSION = "1.0.0"

ETC = "/etc/digitsell-xray"
LIB = "/usr/local/lib/digitsell-xray"
DEFAULT_CONFIG = ETC + "/agent.json"

DEFAULTS = {
    "panel": "",
    "key": "",
    "nodes": [],
    "timeout": 20,
    "interval": 60,
    "limit_interval": 15,
    "api": "127.0.0.1:10085",
    "xray": LIB + "/xray",
    "xray_config": ETC + "/xray.json",
    "state_dir": "/var/lib/digitsell-xray",
    "service": "digitsell-xray",
    "xray_manager": "systemd",
    "log_level": "warning",
    "access_log": "",
    "domain_strategy": "AsIs",
    "block_private": True,
    "block_bittorrent": False,
    "block_regex_file": "",
    "ip_limit": True,
    "sniffing_route_only": False,
    # behind a CDN the customer's address comes in X-Forwarded-For; Xray
    # believes it only when one of these headers (set by the CDN) is there too
    "trusted_xff": ["CF-Connecting-IP", "X-Real-IP", "True-Client-IP"],
    "policy": {},
    "dns": None,
    "cert": {},
}

CERT_DEFAULTS = {
    "email": "",
    "provider": "",
    "env": {},
    "dir": ETC + "/lego",
    "lego": LIB + "/lego",
    "self_dir": ETC + "/self-signed",
    "file": "",
    "key": "",
    "renew_days": 30,
}

# an address keeps its place under an account's device limit this long after
# its last connection closed, so a phone between two requests is not bumped
IP_GRACE = 120
# how often certificates are checked for renewal, and a failed issue retried
CERT_CHECK = 12 * 3600
CERT_RETRY = 600
# Xray restarts caused by API failures, at most one per this many seconds
RESTART_BACKOFF = 60

TRANSPORTS = {
    "ws": "ws", "websocket": "ws",
    "xhttp": "xhttp", "splithttp": "xhttp",
    "grpc": "grpc",
    "httpupgrade": "httpupgrade",
    "raw": "raw", "tcp": "raw",
    "kcp": "kcp", "mkcp": "kcp",
}
REMOVED_TRANSPORTS = {
    "h2": "HTTP/2 was removed from Xray - use xhttp",
    "h3": "HTTP/3 was removed from Xray - use xhttp",
    "http": "HTTP transport was removed from Xray - use xhttp",
    "quic": "QUIC was removed from Xray - use xhttp",
}
# xhttp settings the panel's network settings JSON may carry, passed to Xray as they are
XHTTP_KEYS = (
    "headers", "xPaddingBytes", "xPaddingObfsMode", "xPaddingKey", "xPaddingHeader",
    "xPaddingPlacement", "xPaddingMethod", "uplinkHTTPMethod", "sessionIDPlacement",
    "sessionIDKey", "sessionIDTable", "sessionIDLength", "seqPlacement", "seqKey",
    "uplinkDataPlacement", "uplinkDataKey", "uplinkChunkSize", "noSSEHeader",
    "scMaxEachPostBytes", "scMaxBufferedPosts", "scStreamUpServerSecs",
    "serverMaxHeaderBytes", "extra",
)
SS2022 = ("2022-blake3-aes-128-gcm", "2022-blake3-aes-256-gcm", "2022-blake3-chacha20-poly1305")
SS_AEAD = {
    "aes-128-gcm": "aes-128-gcm", "aead_aes_128_gcm": "aes-128-gcm",
    "aes-256-gcm": "aes-256-gcm", "aead_aes_256_gcm": "aes-256-gcm",
    "chacha20-poly1305": "chacha20-poly1305", "chacha20-ietf-poly1305": "chacha20-poly1305",
    "aead_chacha20_poly1305": "chacha20-poly1305",
    "xchacha20-poly1305": "xchacha20-poly1305", "xchacha20-ietf-poly1305": "xchacha20-poly1305",
    "none": "none", "plain": "none",
}
VISION = ("xtls-rprx-vision", "xtls-rprx-vision-udp443")


def log(*parts):
    print(time.strftime("%Y-%m-%d %H:%M:%S"), *parts, flush=True)


def as_obj(value):
    if isinstance(value, dict):
        return value
    if isinstance(value, str) and value.strip().startswith("{"):
        try:
            parsed = json.loads(value)
            return parsed if isinstance(parsed, dict) else {}
        except ValueError:
            return {}
    return {}


def as_bool(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        return value.strip().lower() in ("1", "true", "yes", "on")
    return False


def as_int(value, default=0):
    try:
        return int(value)
    except (TypeError, ValueError):
        try:
            return int(float(value))
        except (TypeError, ValueError):
            return default


def as_str(value):
    return "" if value is None else str(value).strip()


def as_list(value):
    if isinstance(value, list):
        return [as_str(v) for v in value if as_str(v)]
    if isinstance(value, str) and value.strip():
        return [v.strip() for v in value.split(",") if v.strip()]
    return []


def write_atomic(path, text, mode=0o600):
    folder = os.path.dirname(path) or "."
    os.makedirs(folder, exist_ok=True)
    handle, tmp = tempfile.mkstemp(dir=folder, prefix=".tmp-")
    try:
        with os.fdopen(handle, "w") as out:
            out.write(text)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def dumps(data):
    return json.dumps(data, indent=2, ensure_ascii=False, sort_keys=False) + "\n"


def fingerprint(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


# -------------------------------------------------------------------- config

def load_config(path):
    with open(path, "r") as handle:
        raw = json.load(handle)
    conf = dict(DEFAULTS)
    conf.update(raw)
    cert = dict(CERT_DEFAULTS)
    cert.update(raw.get("cert") or {})
    conf["cert"] = cert

    nodes = []
    for entry in conf.get("nodes") or []:
        node = {"id": entry} if not isinstance(entry, dict) else dict(entry)
        node["id"] = as_int(node.get("id"), 0)
        node.setdefault("panel", conf["panel"])
        node.setdefault("key", conf["key"])
        if node["id"] <= 0 or not node["panel"] or not node["key"]:
            raise SystemExit("agent.json: every node needs an id, and a panel and key (its own or the top-level one)")
        nodes.append(node)
    if not nodes:
        raise SystemExit("agent.json: no nodes - add the node ids from the panel to \"nodes\"")
    if len({n["id"] for n in nodes}) != len(nodes):
        raise SystemExit("agent.json: a node id is listed twice")
    conf["nodes"] = nodes
    conf["interval"] = max(15, as_int(conf["interval"], 60))
    conf["limit_interval"] = max(5, as_int(conf["limit_interval"], 15))
    return conf


# --------------------------------------------------------------------- panel

class PanelError(Exception):
    pass


class Panel:
    """The panel's node API, as the XMPlus binary calls it."""

    def __init__(self, base, key, timeout):
        self.base = base.rstrip("/")
        self.key = key
        self.timeout = timeout
        self.context = ssl.create_default_context()

    def call(self, method, path, body=None, etag=None):
        url = "%s%s?key=%s" % (self.base, path, urllib.parse.quote(self.key, safe=""))
        headers = {"User-Agent": "digitsell-xray/" + VERSION, "Accept": "application/json"}
        data = None
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        if etag:
            headers["If-None-Match"] = etag
        request = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=self.timeout, context=self.context) as response:
                return response.status, response.headers.get("ETag") or "", response.read()
        except urllib.error.HTTPError as error:
            if error.code == 304:
                return 304, etag or "", b""
            text = error.read().decode("utf-8", "replace")
            raise PanelError("%s %s: HTTP %d %s" % (method, path, error.code, text[:200].strip()))
        except (urllib.error.URLError, socket.timeout, OSError) as error:
            reason = getattr(error, "reason", error)
            raise PanelError("%s %s: %s" % (method, path, reason))

    def get_json(self, path, etag=None):
        status, new_etag, body = self.call("GET", path, etag=etag)
        if status == 304:
            return None, new_etag
        try:
            return json.loads(body.decode("utf-8", "replace")), new_etag
        except ValueError:
            snippet = body.decode("utf-8", "replace")[:200].strip()
            raise PanelError("GET %s: the panel did not answer JSON (wrong key or node id?): %s" % (path, snippet))

    def post(self, path, rows):
        self.call("POST", path, body={"data": rows})


# --------------------------------------------------------------- node parsing

class NodeError(Exception):
    pass


def parse_node(node_id, raw):
    """The panel's /api/server answer -> the settings this agent builds from."""
    srv = as_obj(raw.get("server")) if isinstance(raw, dict) else {}
    if not srv:
        raise NodeError("the panel's answer has no \"server\" (node %d)" % node_id)

    ntype = as_str(srv.get("type")).lower()
    if ntype not in ("vless", "vmess", "trojan", "shadowsocks"):
        raise NodeError("node type %r is not supported" % srv.get("type"))

    port = as_str(srv.get("listeningport"))
    if not re.match(r"^\d{1,5}(-\d{1,5})?$", port):
        raise NodeError("bad listening port %r (a port or a range like 20000-20100)" % port)

    net = as_obj(srv.get("networkSettings"))
    sec = as_obj(srv.get("securitySettings"))
    sock = as_obj(srv.get("socketSettings"))

    transport = as_str(net.get("transport")).lower() or "tcp"
    if transport in REMOVED_TRANSPORTS:
        raise NodeError(REMOVED_TRANSPORTS[transport])
    network = TRANSPORTS.get(transport)
    if not network:
        raise NodeError("unknown transport %r" % transport)

    security = as_str(srv.get("security")).lower() or "none"
    if security not in ("none", "tls", "reality"):
        raise NodeError("unknown security %r" % security)

    flow = as_str(net.get("flow")) or as_str(sec.get("flow"))
    if flow not in VISION:
        flow = ""

    spec = {
        "id": node_id,
        "tag": "n%d" % node_id,
        "type": ntype,
        "port": port,
        "listen": as_str(srv.get("listenip")),
        "network": network,
        "transport": transport,
        "net": net,
        "security": security,
        "sec": sec,
        "certmode": as_str(srv.get("certmode")).lower() or "none",
        "cert_domain": as_str(sec.get("serverName")),
        "cipher": as_str(srv.get("cipher")).lower(),
        "server_key": as_str(srv.get("server_key")),
        "sniffing": as_bool(srv.get("sniffing")),
        "send_through": as_str(srv.get("sendthrough")),
        "speedlimit": as_int(srv.get("speedlimit")),
        "flow": flow if ntype == "vless" else "",
        "proxy_protocol": as_bool(net.get("acceptProxyProtocol")),
        "sock": sock if as_bool(sock.get("useSocket")) else {},
        "rules": [],
        "bad_rules": [],
        "relay": None,
    }

    if security == "tls" and spec["certmode"] != "none" and not spec["cert_domain"]:
        raise NodeError("TLS is on but the certificate domain (serverName) is empty")
    if security == "reality":
        if not as_str(sec.get("privatekey")):
            raise NodeError("REALITY needs a private key (privatekey)")
        if not as_list(sec.get("serverNames")):
            raise NodeError("REALITY needs serverNames")
    if ntype == "shadowsocks":
        if network != "raw":
            raise NodeError("Shadowsocks with a plugin / non-tcp transport is not supported")
        if spec["cipher"] in SS2022:
            if not spec["server_key"]:
                raise NodeError("Shadowsocks 2022 needs the server key")
        elif spec["cipher"] not in SS_AEAD:
            raise NodeError("Shadowsocks cipher %r is not supported by Xray" % spec["cipher"])

    for rule in raw.get("rules") or []:
        pattern = as_str(as_obj(rule).get("regex")) if isinstance(rule, dict) else ""
        if not pattern:
            continue
        try:
            re.compile(pattern)
        except re.error:
            spec["bad_rules"].append(pattern)
            continue
        spec["rules"].append(pattern)

    if as_bool(raw.get("relay")):
        spec["relay"] = parse_relay(node_id, as_obj(raw.get("relay_server")))
    return spec


def parse_relay(node_id, rs):
    rtype = as_str(rs.get("type")).lower()
    if rtype not in ("vless", "vmess", "trojan", "shadowsocks"):
        raise NodeError("relay type %r is not supported" % rs.get("type"))
    net = as_obj(rs.get("networkSettings"))
    sec = as_obj(rs.get("securitySettings"))
    transport = as_str(net.get("transport")).lower() or "tcp"
    if transport in REMOVED_TRANSPORTS:
        raise NodeError("relay: " + REMOVED_TRANSPORTS[transport])
    network = TRANSPORTS.get(transport)
    if not network:
        raise NodeError("relay: unknown transport %r" % transport)
    address = as_str(rs.get("address")) or as_str(rs.get("ip"))
    port = as_int(rs.get("listeningport"))
    if not address or not 0 < port < 65536:
        raise NodeError("relay server needs an address and a port")
    flow = as_str(net.get("flow"))
    return {
        "id": as_int(rs.get("serverid")) or as_int(rs.get("id")),
        "type": rtype,
        "address": address,
        "port": port,
        "network": network,
        "net": net,
        "security": as_str(rs.get("security")).lower() or "none",
        "sec": sec,
        "cipher": as_str(rs.get("cipher")).lower(),
        "server_key": as_str(rs.get("server_key")),
        "flow": flow if (flow in VISION and network == "raw" and rtype == "vless") else "",
        "send_through": as_str(rs.get("sendthrough")),
    }


def node_warnings(spec):
    notes = []
    if spec["network"] == "ws":
        notes.append("WebSocket works, but Xray marks it deprecated (the warning in the log) - xhttp is the replacement")
    if spec["network"] == "grpc":
        notes.append("gRPC works, but Xray marks it deprecated - xhttp is the replacement")
    if spec["network"] == "httpupgrade":
        notes.append("HTTPUpgrade works, but Xray marks it deprecated - xhttp is the replacement")
    if spec["network"] == "kcp" and (as_str(spec["net"].get("seed")) or as_obj(spec["net"].get("header")).get("type") not in (None, "", "none")):
        notes.append("mKCP seed / header are ignored by current Xray (moved to finalmask) - clients using them will not connect")
    if spec["network"] == "xhttp" and "?" in as_str(spec["net"].get("path")):
        notes.append("xhttp path has a query (%s) - '?ed=' is for WebSocket only, remove it" % as_str(spec["net"].get("path")))
    if spec["security"] == "tls" and as_bool(spec["sec"].get("allowInsecure")):
        notes.append("allowInsecure is on: current Xray clients refuse links with it (the option was removed) - turn it off, the certificate is real")
    for pattern in spec.get("bad_rules") or []:
        notes.append("block rule %r skipped - not a valid regular expression" % pattern)
    if spec["speedlimit"]:
        notes.append("speed limit %s Mbps is not applied (official Xray has no per-user speed limit)" % spec["speedlimit"])
    if spec["security"] == "none" and spec["type"] in ("vless", "trojan") and spec["network"] not in ("ws", "xhttp", "grpc", "httpupgrade"):
        notes.append("%s without TLS or REALITY sends everything readable" % spec["type"])
    return notes


# ------------------------------------------------------------------- clients

def user_email(node_id, sub):
    return "n%d|%s|%d" % (node_id, as_str(sub.get("email")), as_int(sub.get("id")))


def email_node_uid(email):
    parts = email.split("|")
    if len(parts) < 3 or not parts[0].startswith("n"):
        return None, None
    node, uid = as_int(parts[0][1:], 0), as_int(parts[-1], 0)
    if node <= 0 or uid <= 0:
        return None, None
    return node, uid


def ss2022_user_key(passwd, method):
    raw = passwd.encode("utf-8")
    size = 16 if method == "2022-blake3-aes-128-gcm" else 32
    if len(raw) < size:
        return None
    return base64.b64encode(raw[:size]).decode()


def make_client(spec, sub, email):
    kind = spec["type"]
    uuid = as_str(sub.get("uuid"))
    if kind in ("vless", "vmess", "trojan") and not uuid:
        return None
    if kind == "vless":
        client = {"id": uuid, "email": email}
        if spec["flow"]:
            client["flow"] = spec["flow"]
        return client
    if kind == "vmess":
        return {"id": uuid, "email": email}
    if kind == "trojan":
        return {"password": uuid, "email": email}
    passwd = as_str(sub.get("passwd"))
    if spec["cipher"] in SS2022:
        key = ss2022_user_key(passwd, spec["cipher"])
        return {"password": key, "email": email} if key else None
    if not passwd:
        return None
    return {"password": passwd, "method": SS_AEAD[spec["cipher"]], "email": email}


def placeholder_client(spec):
    """Shadowsocks wants at least one account; this one nobody knows."""
    try:
        with open("/etc/machine-id") as handle:
            seed = handle.read().strip()
    except OSError:
        seed = socket.gethostname()
    secret = hashlib.sha256(("digitsell-xray|%s|%s" % (seed, spec["tag"])).encode()).digest()
    email = "%s|placeholder|0" % spec["tag"]
    if spec["cipher"] in SS2022:
        size = 16 if spec["cipher"] == "2022-blake3-aes-128-gcm" else 32
        return {"password": base64.b64encode(secret[:size]).decode(), "email": email}
    return {"password": secret.hex(), "method": SS_AEAD[spec["cipher"]], "email": email}


def select_users(spec, subs, last_online):
    """Accounts for this node, with the panel's device limit applied the way
    XMPlus applies it: `ipcount` is what the account has online on every node,
    so what is left for this node is iplimit - ipcount + what it had here at
    the last report; an account with nothing left is not let on at all."""
    clients, limits = {}, {}
    for sub in subs:
        if not isinstance(sub, dict):
            continue
        uid = as_int(sub.get("id"))
        if uid <= 0:
            continue
        limit = as_int(sub.get("iplimit"))
        count = as_int(sub.get("ipcount"))
        if limit > 0 and count > 0:
            here = last_online.get(uid, 0)
            left = limit - count + here
            if left > 0:
                limit = left
            elif here > 0:
                limit = here
            else:
                continue
        email = user_email(spec["id"], sub)
        client = make_client(spec, sub, email)
        if client is None:
            continue
        clients[email] = client
        limits[email] = max(0, limit)
    return clients, limits


# ------------------------------------------------------------- xray config

def port_value(port):
    return int(port) if "-" not in port else port


def sockopt_for(spec):
    opt = {}
    if spec.get("proxy_protocol"):
        opt["acceptProxyProtocol"] = True
    sock = spec.get("sock") or {}
    for key, name in (("tcpKeepAliveInterval", "tcpKeepAliveInterval"), ("tcpKeepAliveIdle", "tcpKeepAliveIdle"),
                      ("tcpUserTimeout", "tcpUserTimeout"), ("tcpMaxSeg", "tcpMaxSeg"),
                      ("tcpWindowClamp", "tcpWindowClamp")):
        value = as_int(sock.get(key))
        if value > 0:
            opt[name] = value
    if as_bool(sock.get("tcpMptcp")):
        opt["tcpMptcp"] = True
    return opt


def transport_settings(network, net, server):
    path = as_str(net.get("path")) or "/"
    host = as_str(net.get("host"))
    if network == "ws":
        ws = {"path": path}
        if host:
            ws["host"] = host
        heartbeat = as_int(net.get("heartbeatperiod"))
        if heartbeat > 0:
            ws["heartbeatPeriod"] = heartbeat
        return "wsSettings", ws
    if network == "httpupgrade":
        hu = {"path": path}
        if host:
            hu["host"] = host
        return "httpupgradeSettings", hu
    if network == "xhttp":
        xh = {"path": path, "mode": as_str(net.get("mode")) or "auto"}
        if host:
            xh["host"] = host
        for key in XHTTP_KEYS:
            if key in net and net[key] not in (None, ""):
                xh[key] = net[key]
        if not server and as_bool(net.get("noGRPCHeader")):
            xh["noGRPCHeader"] = True
        return "xhttpSettings", xh
    if network == "grpc":
        grpc = {"serviceName": as_str(net.get("serviceName"))}
        if not server and as_str(net.get("authority")):
            grpc["authority"] = as_str(net.get("authority"))
        return "grpcSettings", grpc
    if network == "raw":
        header = as_obj(net.get("header"))
        if as_str(header.get("type")).lower() == "http":
            request = as_obj(header.get("request"))
            paths = request.get("path") or "/"
            return "rawSettings", {"header": {"type": "http", "request": {"path": paths if isinstance(paths, list) else [as_str(paths)]}}}
        return "rawSettings", {}
    if network == "kcp":
        return "kcpSettings", {}
    return None, None


def short_ids(value):
    ids = [as_str(v) for v in value] if isinstance(value, list) else as_list(value)
    return ids or [""]


def build_inbound(spec, clients, cert, fallbacks=None, trusted_xff=None):
    kind = spec["type"]
    if spec["network"] != "raw":
        fallbacks = None  # Xray takes fallbacks on raw TCP only
    clients = list(clients)
    if kind == "vless":
        settings = {"clients": clients, "decryption": "none"}
        if fallbacks:
            settings["fallbacks"] = fallbacks
    elif kind == "vmess":
        settings = {"clients": clients}
    elif kind == "trojan":
        settings = {"clients": clients}
        if fallbacks:
            settings["fallbacks"] = fallbacks
    else:
        if not clients:
            clients = [placeholder_client(spec)]
        settings = {"clients": clients, "network": "tcp,udp"}
        if spec["cipher"] in SS2022:
            settings["method"] = spec["cipher"]
            settings["password"] = spec["server_key"]

    stream = {"network": spec["network"]}
    field, value = transport_settings(spec["network"], spec["net"], server=True)
    if field and value:
        stream[field] = value

    sec = spec["sec"]
    if spec["security"] == "tls" and spec["certmode"] != "none" and cert:
        tls = {
            "certificates": [{"certificateFile": cert[0], "keyFile": cert[1]}],
            "rejectUnknownSni": as_bool(sec.get("rejectUnknownSni")),
        }
        curves = as_list(sec.get("curvepreferences"))
        if curves:
            tls["curvePreferences"] = curves
        alpn = as_list(sec.get("alpn"))
        if alpn:
            tls["alpn"] = alpn
        stream["security"] = "tls"
        stream["tlsSettings"] = tls
    elif spec["security"] == "reality":
        target = sec.get("dest") if sec.get("dest") not in (None, "") else sec.get("target")
        reality = {
            "show": as_bool(sec.get("show")),
            "target": target if isinstance(target, int) else as_str(target),
            "xver": as_int(sec.get("proxyprotocol")),
            "serverNames": as_list(sec.get("serverNames")),
            "privateKey": as_str(sec.get("privatekey")),
            "shortIds": short_ids(sec.get("shortids")),
        }
        for key, name in (("minclientver", "minClientVer"), ("maxclientver", "maxClientVer")):
            if as_str(sec.get(key)):
                reality[name] = as_str(sec.get(key))
        if as_int(sec.get("maxtimediff")) > 0:
            reality["maxTimeDiff"] = as_int(sec.get("maxtimediff"))
        stream["security"] = "reality"
        stream["realitySettings"] = reality

    sockopt = sockopt_for(spec)
    if trusted_xff and spec["network"] in ("ws", "xhttp", "httpupgrade", "grpc"):
        sockopt["trustedXForwardedFor"] = list(trusted_xff)
    if sockopt:
        stream["sockopt"] = sockopt

    inbound = {
        "tag": spec["tag"],
        "port": port_value(spec["port"]),
        "protocol": kind,
        "settings": settings,
        "streamSettings": stream,
        "sniffing": {
            "enabled": spec["sniffing"],
            "destOverride": ["http", "tls", "quic"],
        },
    }
    if spec["listen"]:
        inbound["listen"] = spec["listen"]
    return inbound


def relay_outbound(spec, sub, email):
    """The relay (chain) outbound for one account: the next node, logged in
    as that same account, the way XMPlus builds it."""
    relay = spec["relay"]
    uuid = as_str(sub.get("uuid"))
    passwd = as_str(sub.get("passwd"))
    kind = relay["type"]
    if kind == "vless":
        user = {"id": uuid, "encryption": "none"}
        if relay["flow"]:
            user["flow"] = relay["flow"]
        settings = {"vnext": [{"address": relay["address"], "port": relay["port"], "users": [user]}]}
    elif kind == "vmess":
        settings = {"vnext": [{"address": relay["address"], "port": relay["port"], "users": [{"id": uuid, "security": "auto"}]}]}
    elif kind == "trojan":
        settings = {"servers": [{"address": relay["address"], "port": relay["port"], "password": uuid}]}
    else:
        if relay["cipher"] in SS2022:
            key = ss2022_user_key(passwd, relay["cipher"])
            if not key:
                return None
            password = "%s:%s" % (relay["server_key"], key)
        else:
            password = passwd
        settings = {"servers": [{"address": relay["address"], "port": relay["port"], "method": relay["cipher"],
                                 "password": password, "uot": True}]}

    stream = {"network": relay["network"]}
    field, value = transport_settings(relay["network"], relay["net"], server=False)
    if field and value:
        stream[field] = value
    sec = relay["sec"]
    host = as_str(relay["net"].get("host"))
    if relay["security"] == "tls":
        tls = {"serverName": as_str(sec.get("serverName")) or host or relay["address"]}
        if as_str(sec.get("fingerprint")):
            tls["fingerprint"] = as_str(sec.get("fingerprint"))
        stream["security"] = "tls"
        stream["tlsSettings"] = tls
    elif relay["security"] == "reality":
        stream["security"] = "reality"
        stream["realitySettings"] = {
            "serverName": as_str(sec.get("serverName")),
            "publicKey": as_str(sec.get("publickey")),
            "shortId": as_str(sec.get("shortid")),
            "spiderX": as_str(sec.get("spiderx")),
            "fingerprint": as_str(sec.get("fingerprint")) or "chrome",
        }

    tag = relay_tag(spec, email)
    outbound = {"tag": tag, "protocol": kind, "settings": settings, "streamSettings": stream}
    if relay["send_through"] or spec["send_through"]:
        outbound["sendThrough"] = relay["send_through"] or spec["send_through"]
    return outbound


def relay_tag(spec, email):
    _, uid = email_node_uid(email)
    return "relay-%s-%d" % (spec["tag"], uid or 0)


# ----------------------------------------------------------------- the agent

class XrayError(Exception):
    pass


class Agent:
    def __init__(self, conf):
        self.conf = conf
        self.xray = conf["xray"]
        self.state_path = os.path.join(conf["state_dir"], "state.json")
        self.panels = {}
        for node in conf["nodes"]:
            self.panels[node["id"]] = Panel(node["panel"], node["key"], as_int(conf["timeout"], 20))
        self.node_conf = {n["id"]: n for n in conf["nodes"]}

        self.state = self.load_state()
        self.specs = {}         # node id -> parsed settings in use
        self.errors = {}        # node id -> why it is not running
        self.warnings = {}      # node id -> notes shown by check / status
        self.clients = {}       # node id -> {email: client} in the running Xray
        self.subs = {}          # node id -> {email: subscription row} (relay needs the row)
        self.limits = {}        # email -> device limit on this node, 0 = none
        self.last_online = {}   # node id -> {uid: addresses reported last time}
        self.ipstate = {}       # email -> {ip: {"first": t, "seen": t, "ok": bool}}
        self.blocked = {}       # email -> [ip] refused for the device limit
        self.online = {}        # email -> [ip] let in, from the last look
        self.pushed_rules = None
        self.certs = {}         # node id -> (certificate, key)
        self.cert_failed = {}   # domain -> time of the last failed issue
        self.self_signed_used = set()
        self.applied_fp = None  # what the panel said when the config was last built
        self.last_restart = 0
        self.process = None     # xray_manager "process": the child Xray
        self.running = True
        self.xray_identity = None

    # ------------------------------------------------------------- state

    def load_state(self):
        try:
            with open(self.state_path, "r") as handle:
                state = json.load(handle)
        except (OSError, ValueError):
            state = {}
        state.setdefault("nodes", {})
        state.setdefault("pending", {})
        state.setdefault("status", {})
        return state

    def save_state(self):
        try:
            write_atomic(self.state_path, json.dumps(self.state, ensure_ascii=False))
        except OSError as error:
            log("could not save state: %s" % error)

    def node_state(self, node_id):
        return self.state["nodes"].setdefault(str(node_id), {})

    # ------------------------------------------------------------ fetching

    def fetch(self, node_id, fresh=False):
        """Ask the panel for the node's settings and accounts; the cached
        answers stand in when it cannot be reached. Returns (raw, subs, changed)."""
        panel = self.panels[node_id]
        st = self.node_state(node_id)
        changed = False

        try:
            etag = st.get("server_etag") if st.get("server") is not None and not fresh else None
            raw, new_etag = panel.get_json("/api/server/%d" % node_id, etag)
            if raw is not None:
                changed = changed or raw != st.get("server")
                st["server"] = raw
                st["server_etag"] = new_etag
        except PanelError as error:
            if st.get("server") is None:
                raise
            log("node %d: panel unreachable, using its last settings: %s" % (node_id, error))

        try:
            etag = st.get("subs_etag") if st.get("subs") is not None and not fresh else None
            answer, new_etag = panel.get_json("/api/subscriptions/%d" % node_id, etag)
            if answer is not None:
                subs = answer.get("subscriptions") if isinstance(answer, dict) else None
                if subs is None:
                    subs = []
                if not isinstance(subs, list):
                    raise PanelError("the subscriptions answer is not a list")
                changed = changed or subs != st.get("subs")
                st["subs"] = subs
                st["subs_etag"] = new_etag
        except PanelError as error:
            if st.get("subs") is None:
                raise
            log("node %d: panel unreachable, using its last account list: %s" % (node_id, error))

        return st.get("server"), st.get("subs") or [], changed

    # --------------------------------------------------------- certificates

    def cert_for(self, spec):
        """(certificate, key) for a TLS node, issuing one when needed. A node
        whose certificate cannot be had yet gets a self-signed one, so the
        others keep running and a CDN in 'Full' mode still connects; the
        real one is retried every few minutes."""
        if spec["security"] != "tls" or spec["certmode"] == "none":
            return None
        domain = spec["cert_domain"]
        mode = spec["certmode"]
        node = self.node_conf.get(spec["id"], {})
        cert = self.conf["cert"]

        if mode == "file":
            pairs = [
                (node.get("cert_file"), node.get("key_file")),
                (cert.get("file"), cert.get("key")),
                (os.path.join(ETC, "certs", domain + ".crt"), os.path.join(ETC, "certs", domain + ".key")),
            ]
            for crt, key in pairs:
                if crt and key and os.path.isfile(crt) and os.path.isfile(key):
                    return crt, key
            log("node %d: cert mode 'file' but no certificate for %s (put it at %s/certs/%s.crt and .key)"
                % (spec["id"], domain, ETC, domain))
            return self.self_signed(domain)

        if mode in ("http", "tls", "dns"):
            crt, key = self.lego_paths(domain)
            if os.path.isfile(crt) and os.path.isfile(key):
                self.cert_failed.pop(domain, None)
                return crt, key
            last = self.cert_failed.get(domain, 0)
            if time.time() - last >= CERT_RETRY:
                if self.lego_run(domain, mode, spec):
                    self.cert_failed.pop(domain, None)
                    return crt, key
                self.cert_failed[domain] = time.time()
            return self.self_signed(domain)

        log("node %d: unknown cert mode %r, using a self-signed certificate" % (spec["id"], mode))
        return self.self_signed(domain)

    def lego_paths(self, domain):
        name = domain.replace("*", "_").replace(":", "-")
        folder = os.path.join(self.conf["cert"]["dir"], "certificates")
        return os.path.join(folder, name + ".crt"), os.path.join(folder, name + ".key")

    def lego_run(self, domain, mode, spec=None):
        cert = self.conf["cert"]
        lego = cert["lego"]
        if not os.path.isfile(lego):
            log("certificate for %s: lego is not installed at %s (run: digitsell-xray update)" % (domain, lego))
            return False
        cmd = [lego, "run", "--accept-tos", "--path", cert["dir"], "--domains", domain,
               "--renew-days", str(as_int(cert.get("renew_days"), 30)), "--no-random-sleep"]
        if cert.get("email"):
            cmd += ["--email", cert["email"]]
        env = dict(os.environ)
        stopped = False
        if mode == "dns":
            if not cert.get("provider"):
                log("certificate for %s: cert mode 'dns' needs cert.provider (and its keys in cert.env) in agent.json" % domain)
                return False
            cmd += ["--dns", cert["provider"]]
            for name, value in (cert.get("env") or {}).items():
                env[str(name)] = str(value)
        elif mode == "http":
            cmd += ["--http"]
            if self.port_busy(80):
                log("certificate for %s: port 80 is in use, the http challenge needs it free "
                    "(use cert mode 'dns', or free port 80)" % domain)
                return False
        else:
            cmd += ["--tls"]
            if self.port_busy(443):
                if self.xray_holds(443):
                    log("certificate for %s: stopping Xray for a moment, the tls challenge needs port 443" % domain)
                    self.xray_stop()
                    stopped = True
                else:
                    log("certificate for %s: port 443 is in use by another program, the tls challenge needs it" % domain)
                    return False
        log("certificate for %s: asking Let's Encrypt (%s challenge)" % (domain, mode))
        try:
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env,
                                  universal_newlines=True, timeout=600)
            ok = proc.returncode == 0
            output = proc.stdout
        except (OSError, subprocess.TimeoutExpired) as error:
            ok, output = False, str(error)
        finally:
            if stopped:
                self.xray_start()
        if ok:
            log("certificate for %s: ok" % domain)
        else:
            lines = [l for l in output.strip().splitlines() if l.strip()][-6:]
            log("certificate for %s failed:\n    %s" % (domain, "\n    ".join(lines)))
        return ok

    def renew_certs(self):
        for spec in self.specs.values():
            if spec["security"] == "tls" and spec["certmode"] in ("http", "tls", "dns"):
                crt, _ = self.lego_paths(spec["cert_domain"])
                days = cert_days_left(crt)
                if days is not None and days <= as_int(self.conf["cert"].get("renew_days"), 30):
                    # Xray re-reads certificate files every hour by itself
                    self.lego_run(spec["cert_domain"], spec["certmode"], spec)

    def self_signed(self, domain):
        folder = self.conf["cert"]["self_dir"]
        os.makedirs(folder, exist_ok=True)
        name = re.sub(r"[^A-Za-z0-9.-]", "_", domain or "node")
        crt, key = os.path.join(folder, name + ".crt"), os.path.join(folder, name + ".key")
        if not (os.path.isfile(crt) and os.path.isfile(key)):
            cmd = ["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1",
                   "-nodes", "-days", "3650", "-subj", "/CN=" + (domain or "node"), "-keyout", key, "-out", crt]
            if domain:
                cmd[-4:-4] = ["-addext", "subjectAltName=DNS:" + domain]
            proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
            if proc.returncode != 0:
                raise XrayError("openssl could not make a self-signed certificate: " + proc.stdout[-300:])
            os.chmod(key, 0o600)
        if domain not in self.self_signed_used:
            self.self_signed_used.add(domain)
            log("warning: %s uses a SELF-SIGNED certificate until a real one is had - fine behind a CDN "
                "in 'Full' mode, clients connecting directly refuse it" % domain)
        return crt, key

    @staticmethod
    def port_busy(port):
        for family, addr in ((socket.AF_INET, "0.0.0.0"), (socket.AF_INET6, "::")):
            try:
                probe = socket.socket(family, socket.SOCK_STREAM)
            except OSError:
                continue
            try:
                probe.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                probe.bind((addr, port))
            except OSError:
                return True
            finally:
                probe.close()
        return False

    def xray_holds(self, port):
        for spec in self.specs.values():
            first, _, last = spec["port"].partition("-")
            if as_int(first) <= port <= as_int(last or first):
                return True
        return False

    # ------------------------------------------------------- xray process

    def xray_cmd(self, *args, timeout=30):
        try:
            proc = subprocess.run([self.xray] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                  universal_newlines=True, timeout=timeout)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise XrayError("%s: %s" % (" ".join(args[:2]), error))
        if proc.returncode != 0:
            raise XrayError((proc.stderr or proc.stdout).strip()[-800:] or "exit %d" % proc.returncode)
        return proc.stdout

    def api(self, command, *args, timeout=30):
        return self.xray_cmd("api", command, "--server=" + self.conf["api"], "-t", str(timeout), *args,
                             timeout=timeout + 10)

    def systemctl(self, *args):
        return subprocess.run(["systemctl"] + list(args), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              universal_newlines=True)

    def xray_start(self):
        if self.conf["xray_manager"] == "process":
            if self.process is None or self.process.poll() is not None:
                self.process = subprocess.Popen([self.xray, "run", "-c", self.conf["xray_config"]])
            return
        self.systemctl("start", self.conf["service"])

    def xray_stop(self):
        if self.conf["xray_manager"] == "process":
            if self.process is not None and self.process.poll() is None:
                self.process.terminate()
                try:
                    self.process.wait(10)
                except subprocess.TimeoutExpired:
                    self.process.kill()
            self.process = None
            return
        self.systemctl("stop", self.conf["service"])

    def xray_restart(self):
        self.last_restart = time.time()
        if self.conf["xray_manager"] == "process":
            self.xray_stop()
            self.xray_start()
        else:
            proc = self.systemctl("restart", self.conf["service"])
            if proc.returncode != 0:
                log("systemctl restart %s failed: %s" % (self.conf["service"], proc.stdout.strip()))
        self.pushed_rules = None
        self.wait_api()
        self.xray_identity = self.xray_ident()

    def xray_active(self):
        if self.conf["xray_manager"] == "process":
            return self.process is not None and self.process.poll() is None
        return self.systemctl("is-active", "--quiet", self.conf["service"]).returncode == 0

    def xray_ident(self):
        """Changes whenever Xray is (re)started, by us or by systemd after a crash."""
        if self.conf["xray_manager"] == "process":
            return self.process.pid if self.process else None
        proc = self.systemctl("show", "-p", "MainPID", "-p", "ExecMainStartTimestampMonotonic", self.conf["service"])
        return proc.stdout.strip() if proc.returncode == 0 else None

    def wait_api(self, seconds=15):
        deadline = time.time() + seconds
        while time.time() < deadline:
            try:
                self.api("statsquery", "-pattern", "nothing>>>", timeout=3)
                return True
            except XrayError:
                time.sleep(0.5)
        log("Xray's API does not answer at %s" % self.conf["api"])
        return False

    # ------------------------------------------------------------ building

    def static_rules(self):
        rules = []
        if self.conf.get("block_bittorrent"):
            rules.append({"ruleTag": "bittorrent", "protocol": ["bittorrent"], "outboundTag": "block"})
        local = []
        path = self.conf.get("block_regex_file")
        if path and os.path.isfile(path):
            with open(path, "r") as handle:
                for line in handle:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        try:
                            re.compile(line)
                            local.append("regexp:" + line)
                        except re.error:
                            log("block_regex_file: skipping %r - not a valid regular expression" % line)
        if local:
            rules.append({"ruleTag": "local-block", "domain": local, "outboundTag": "block"})
        for node_id in sorted(self.specs):
            spec = self.specs[node_id]
            if spec["rules"]:
                rules.append({"ruleTag": "panel-block-%s" % spec["tag"], "inboundTag": [spec["tag"]],
                              "domain": ["regexp:" + r for r in spec["rules"]], "outboundTag": "block"})
        for node_id in sorted(self.specs):
            spec = self.specs[node_id]
            if spec["relay"]:
                for email in sorted(self.clients.get(node_id, {})):
                    if email in self.subs.get(node_id, {}):
                        tag = relay_tag(spec, email)
                        rules.append({"ruleTag": tag, "user": [email], "outboundTag": tag})
        for node_id in sorted(self.specs):
            spec = self.specs[node_id]
            if spec["send_through"]:
                rules.append({"ruleTag": "via-%s" % spec["tag"], "inboundTag": [spec["tag"]],
                              "outboundTag": "direct-%s" % spec["tag"]})
        return rules

    def limit_rules(self):
        rules = []
        for email in sorted(self.blocked):
            ips = self.blocked[email]
            if ips:
                digest = hashlib.sha1(email.encode()).hexdigest()[:12]
                rules.append({"ruleTag": "iplimit-" + digest, "user": [email], "source": ips, "outboundTag": "block"})
        return rules

    def freedom(self, tag, send_through=""):
        settings = {"domainStrategy": self.conf.get("domain_strategy") or "AsIs"}
        # Xray's freedom already refuses private / LAN targets for proxied
        # traffic by default; turning that off takes an explicit allow
        if not as_bool(self.conf.get("block_private", True)):
            settings["finalRules"] = [{"action": "allow", "ip": ["geoip:private"]}]
        out = {"tag": tag, "protocol": "freedom", "settings": settings}
        if send_through:
            out["sendThrough"] = send_through
        return out

    def build_config(self, specs=None, clients=None):
        specs = self.specs if specs is None else specs
        clients = self.clients if clients is None else clients
        policy = {"handshake": 4, "connIdle": 300, "uplinkOnly": 2, "downlinkOnly": 5, "bufferSize": 64}
        policy.update(self.conf.get("policy") or {})
        policy.update({"statsUserUplink": True, "statsUserDownlink": True, "statsUserOnline": True})

        inbounds, outbounds = [], [self.freedom("direct"), {"tag": "block", "protocol": "blackhole"}]
        for node_id in sorted(specs):
            spec = specs[node_id]
            fallbacks = self.node_conf.get(node_id, {}).get("fallbacks")
            node_clients = [clients.get(node_id, {})[e] for e in sorted(clients.get(node_id, {}))]
            inbounds.append(build_inbound(spec, node_clients, self.certs.get(node_id), fallbacks,
                                          self.conf.get("trusted_xff")))
            if spec["send_through"]:
                outbounds.append(self.freedom("direct-%s" % spec["tag"], spec["send_through"]))
            if spec["relay"]:
                for email in sorted(clients.get(node_id, {})):
                    sub = self.subs.get(node_id, {}).get(email)
                    if sub:
                        out = relay_outbound(spec, sub, email)
                        if out:
                            outbounds.append(out)

        config = {
            "log": {"loglevel": self.conf.get("log_level") or "warning",
                    "access": self.conf.get("access_log") or "none"},
            "api": {"tag": "api", "listen": self.conf["api"],
                    "services": ["HandlerService", "StatsService", "RoutingService", "LoggerService"]},
            "stats": {},
            "policy": {"levels": {"0": policy},
                       "system": {"statsInboundUplink": False, "statsInboundDownlink": False}},
            "inbounds": inbounds,
            "outbounds": outbounds,
            "routing": {"domainStrategy": "AsIs", "rules": self.static_rules()},
        }
        if self.conf.get("dns"):
            config["dns"] = self.conf["dns"]
        return config

    def test_config(self, config):
        folder = os.path.dirname(self.conf["xray_config"])
        os.makedirs(folder, exist_ok=True)
        handle, path = tempfile.mkstemp(dir=folder, prefix=".test-", suffix=".json")
        try:
            with os.fdopen(handle, "w") as out:
                out.write(dumps(config))
            self.xray_cmd("run", "-test", "-c", path, timeout=60)
            return None
        except XrayError as error:
            return str(error)
        finally:
            try:
                os.unlink(path)
            except OSError:
                pass

    def write_config(self, config):
        write_atomic(self.conf["xray_config"], dumps(config))

    # --------------------------------------------------------------- sync

    def sync(self, first=False):
        new_specs, new_subs, fetched = {}, {}, {}
        for node in self.conf["nodes"]:
            node_id = node["id"]
            try:
                raw, subs, _ = self.fetch(node_id)
                spec = parse_node(node_id, raw)
                fetched[node_id] = spec
                new_subs[node_id] = subs
                self.errors.pop(node_id, None)
                notes = node_warnings(spec)
                if notes != self.warnings.get(node_id):
                    for note in notes:
                        log("node %d: %s" % (node_id, note))
                self.warnings[node_id] = notes
            except (PanelError, NodeError) as error:
                if str(error) != self.errors.get(node_id):
                    log("node %d: %s" % (node_id, error))
                self.errors[node_id] = str(error)
                if node_id in self.specs:
                    fetched[node_id] = self.specs[node_id]
                    new_subs[node_id] = [self.subs[node_id][e] for e in self.subs.get(node_id, {})]
        self.save_state()

        for node_id, spec in fetched.items():
            new_specs[node_id] = spec
            self.certs[node_id] = self.cert_for(spec)

        new_clients, new_limits, sub_rows = {}, {}, {}
        for node_id, spec in new_specs.items():
            clients, limits = select_users(spec, new_subs.get(node_id, []), self.last_online.get(node_id, {}))
            new_clients[node_id] = clients
            new_limits.update(limits)
            rows = {}
            for sub in new_subs.get(node_id, []):
                if isinstance(sub, dict):
                    rows[user_email(node_id, sub)] = sub
            sub_rows[node_id] = rows

        # the panel's settings plus the certificates in use; the specs may be
        # trimmed below (rules Xray refused), so compare what the panel said
        panel_fp = fingerprint({"specs": new_specs, "certs": {str(k): list(self.certs.get(k) or []) for k in new_specs}})
        restarted_elsewhere = self.xray_identity is not None and self.xray_ident() != self.xray_identity

        if first or panel_fp != self.applied_fp or not self.xray_active():
            self.applied_fp = panel_fp
            self.apply_full(copy.deepcopy(new_specs), new_clients, sub_rows, first)
        else:
            if restarted_elsewhere:
                log("Xray was restarted outside the agent; its config file already holds every account")
                self.pushed_rules = None
                self.xray_identity = self.xray_ident()
            self.apply_users(new_clients, sub_rows)
        self.limits = new_limits

    def apply_full(self, specs, clients, sub_rows, first):
        """Write the whole config and restart Xray, unless the config on disk
        is already exactly this and Xray runs it (the agent was restarted)."""
        old_specs, old_clients, old_subs = self.specs, self.clients, self.subs
        self.specs, self.clients, self.subs = specs, clients, sub_rows
        config = self.build_config()

        error = self.test_config(config) if specs else None
        if error and any(s["rules"] for s in specs.values()):
            log("Xray refused the config; trying again without the panel's block rules:\n    %s" % error)
            for spec in specs.values():
                spec["rules"] = []
            config = self.build_config()
            error = self.test_config(config)
        if error:
            # take back the nodes whose new settings broke it, keep the rest
            broken = [n for n in specs if fingerprint(specs[n]) != fingerprint(old_specs.get(n))]
            log("Xray refused the new config; keeping the previous settings of node(s) %s:\n    %s"
                % (", ".join(map(str, broken)) or "-", error))
            for node_id in broken:
                self.errors[node_id] = "Xray refused its settings: %s" % error.splitlines()[-1][:300]
                if node_id in old_specs:
                    specs[node_id] = old_specs[node_id]
                else:
                    specs.pop(node_id, None)
                    clients.pop(node_id, None)
            config = self.build_config()
            error = self.test_config(config) if specs else None
            if error:
                log("Xray still refuses the config; leaving it as it runs now:\n    %s" % error)
                self.specs, self.clients, self.subs = old_specs, old_clients, old_subs
                return

        text = dumps(config)
        try:
            with open(self.conf["xray_config"], "r") as handle:
                same = handle.read() == text
        except OSError:
            same = False
        self.write_config(config)

        if first and same and self.xray_active():
            log("Xray already runs this config; not restarting it")
            self.pushed_rules = None
            self.xray_identity = self.xray_ident()
            return
        total = sum(len(c) for c in self.clients.values())
        log("starting Xray: %d node(s), %d account(s)" % (len(self.specs), total))
        # usage counted since the last report would be lost with the restart
        if self.xray_active():
            self.collect_traffic()
        self.xray_restart()
        if not self.xray_active():
            log("Xray did not start - see: journalctl -u %s -n 50" % self.conf["service"])

    def apply_users(self, new_clients, sub_rows):
        """Accounts added / removed / changed, through Xray's API - no restart."""
        changed = False
        failed = False
        for node_id, spec in self.specs.items():
            old = self.clients.get(node_id, {})
            new = new_clients.get(node_id, {})
            removed = [e for e in old if e not in new or old[e] != new[e]]
            added = [e for e in new if e not in old or old[e] != new[e]]
            if not removed and not added:
                continue
            changed = True
            try:
                if spec["relay"]:
                    self.relay_remove(spec, removed)
                if removed:
                    self.remove_users(spec, removed)
                if added:
                    self.add_users(spec, [new[e] for e in added])
                if spec["relay"]:
                    self.relay_add(spec, [e for e in added], sub_rows.get(node_id, {}))
                log("node %d: +%d -%d account(s) (%d in all)" % (
                    node_id, len([e for e in added if e not in old]), len([e for e in removed if e not in new]), len(new)))
            except XrayError as error:
                failed = True
                log("node %d: Xray's API failed while changing accounts: %s" % (node_id, error))
        self.clients = {n: new_clients.get(n, {}) for n in self.specs}
        self.subs = sub_rows
        if changed:
            self.write_config(self.build_config())
            self.push_rules()
        if failed:
            # the config file holds every account; a restart puts Xray in line with it
            if time.time() - self.last_restart >= RESTART_BACKOFF:
                log("restarting Xray so it runs the accounts in its config file")
                self.collect_traffic()
                self.xray_restart()

    def add_users(self, spec, clients):
        for start in range(0, len(clients), 500):
            batch = clients[start:start + 500]
            inbound = build_inbound(spec, batch, self.certs.get(spec["id"]))
            payload = {"inbounds": [inbound]}
            handle, path = tempfile.mkstemp(prefix="adu-", suffix=".json")
            try:
                with os.fdopen(handle, "w") as out:
                    json.dump(payload, out, ensure_ascii=False)
                output = self.api("adu", path, timeout=60)
            finally:
                os.unlink(path)
            match = re.search(r"Added (\d+) user", output)
            added = int(match.group(1)) if match else 0
            if added < len(batch):
                problems = [l for l in output.splitlines() if l.strip() and not l.startswith(("add user", "result: ok", "processing"))]
                log("node %d: %d of %d account(s) not added: %s" % (spec["id"], len(batch) - added, len(batch),
                                                                    " | ".join(problems[-3:])))

    def remove_users(self, spec, emails):
        for start in range(0, len(emails), 500):
            self.api("rmu", "-tag=" + spec["tag"], *emails[start:start + 500], timeout=60)

    def relay_add(self, spec, emails, rows):
        outbounds = []
        for email in emails:
            sub = rows.get(email)
            out = relay_outbound(spec, sub, email) if sub else None
            if out:
                outbounds.append(out)
        if not outbounds:
            return
        handle, path = tempfile.mkstemp(prefix="ado-", suffix=".json")
        try:
            with os.fdopen(handle, "w") as out:
                json.dump({"outbounds": outbounds}, out, ensure_ascii=False)
            self.api("ado", path, timeout=60)
        finally:
            os.unlink(path)

    def relay_remove(self, spec, emails):
        tags = [relay_tag(spec, e) for e in emails]
        if tags:
            # rules first, or they would point at a missing outbound
            self.pushed_rules = None
            wanted = [r for r in self.static_rules() if r.get("ruleTag") not in tags] + self.limit_rules()
            self.set_rules(wanted)
            for start in range(0, len(tags), 200):
                try:
                    self.api("rmo", *tags[start:start + 200], timeout=60)
                except XrayError as error:
                    log("node %d: removing relay outbounds: %s" % (spec["id"], error))

    def set_rules(self, rules):
        handle, path = tempfile.mkstemp(prefix="rules-", suffix=".json")
        try:
            with os.fdopen(handle, "w") as out:
                json.dump({"routing": {"rules": rules}}, out, ensure_ascii=False)
            # without -append the whole rule list is replaced, in one step
            self.api("adrules", path, timeout=60)
        finally:
            os.unlink(path)
        self.pushed_rules = fingerprint(rules)

    def push_rules(self):
        rules = self.static_rules() + self.limit_rules()
        if not rules and self.pushed_rules is None:
            self.pushed_rules = fingerprint(rules)
            return
        if fingerprint(rules) == self.pushed_rules:
            return
        try:
            if rules:
                self.set_rules(rules)
            else:
                # an empty list cannot be sent; one rule that matches nothing clears the rest
                self.set_rules([{"ruleTag": "none", "user": ["nobody|none|0"], "outboundTag": "block"}])
        except XrayError as error:
            self.pushed_rules = None
            log("could not update Xray's routing rules: %s" % error)

    # --------------------------------------------------------- statistics

    def collect_traffic(self):
        """Read and reset Xray's per-account counters into the pending report."""
        try:
            output = self.api("statsquery", "-pattern", "user>>>", "-reset", timeout=30)
        except XrayError as error:
            log("could not read usage from Xray: %s" % error)
            return
        try:
            stats = json.loads(output or "{}").get("stat") or []
        except ValueError:
            log("Xray's usage answer is not JSON: %s" % output[:200])
            return
        pending = self.state["pending"]
        for stat in stats:
            name = as_str(stat.get("name"))
            value = as_int(stat.get("value"))
            parts = name.split(">>>")
            if value <= 0 or len(parts) != 4 or parts[0] != "user" or parts[2] != "traffic":
                continue
            node_id, uid = email_node_uid(parts[1])
            if not node_id or node_id not in self.panels:
                continue
            row = pending.setdefault(str(node_id), {}).setdefault(str(uid), [0, 0])
            if parts[3] == "uplink":
                row[0] += value
            elif parts[3] == "downlink":
                row[1] += value
        self.save_state()

    def report_traffic(self):
        self.collect_traffic()
        pending = self.state["pending"]
        for node_key in list(pending):
            node_id = as_int(node_key)
            rows = pending[node_key]
            if node_id not in self.panels:
                pending.pop(node_key, None)
                continue
            if not rows:
                continue
            data = [{"subscription_id": as_int(uid), "u": ud[0], "d": ud[1]} for uid, ud in rows.items()]
            try:
                self.panels[node_id].post("/api/traffic/%d" % node_id, data)
            except PanelError as error:
                total = sum(ud[0] + ud[1] for ud in rows.values())
                log("node %d: usage not reported, kept for the next try (%d account(s), %.1f MB): %s"
                    % (node_id, len(rows), total / 1e6, error))
                continue
            pending[node_key] = {}
            self.node_status(node_id)["traffic_at"] = int(time.time())
            self.node_status(node_id)["traffic_accounts"] = len(data)
        self.save_state()

    def read_online(self):
        """{email: {ip: last_seen}} of the accounts with live connections."""
        online = {}
        try:
            data = json.loads(self.api("statsonlineiplist", "-all", timeout=30) or "{}")
            for user in data.get("users") or []:
                email = as_str(user.get("email"))
                ips = {}
                for entry in user.get("ips") or []:
                    ip = as_str(entry.get("ip"))
                    if ip:
                        ips[ip] = as_int(entry.get("lastSeen", entry.get("last_seen")))
                if email and ips:
                    online[email] = ips
            return online
        except (XrayError, ValueError, AttributeError):
            pass
        # older Xray: the list of online accounts, then each one's addresses
        data = json.loads(self.api("statsgetallonlineusers", timeout=30) or "{}")
        for name in data.get("users") or []:
            parts = as_str(name).split(">>>")
            email = parts[1] if len(parts) == 3 else as_str(name)
            try:
                answer = json.loads(self.api("statsonlineiplist", "-email", email, timeout=10) or "{}")
            except (XrayError, ValueError):
                continue
            ips = {ip: as_int(ts) for ip, ts in (answer.get("ips") or {}).items()}
            if ips:
                online[email] = ips
        return online

    def enforce_limits(self):
        try:
            online = self.read_online()
        except (XrayError, ValueError) as error:
            log("could not read online addresses from Xray: %s" % error)
            return
        now = time.time()
        use_limit = as_bool(self.conf.get("ip_limit"))
        blocked, allowed_now = {}, {}
        for email, ips in online.items():
            seen = self.ipstate.setdefault(email, {})
            for ip in ips:
                entry = seen.setdefault(ip, {"first": now, "ok": False})
                entry["seen"] = now
            limit = self.limits.get(email, 0) if use_limit else 0
            if limit <= 0:
                for ip in ips:
                    seen[ip]["ok"] = True
                allowed_now[email] = sorted(ips)
                continue
            keep = sorted((ip for ip, e in seen.items() if e.get("ok") and now - e.get("seen", 0) <= IP_GRACE),
                          key=lambda ip: seen[ip]["first"])
            others = sorted((ip for ip in ips if ip not in keep), key=lambda ip: seen[ip]["first"])
            allowed = set((keep + others)[:limit])
            for ip, entry in seen.items():
                entry["ok"] = ip in allowed
            refused = sorted(ip for ip in ips if ip not in allowed)
            if refused:
                blocked[email] = refused
            allowed_now[email] = sorted(ip for ip in ips if ip in allowed)
        # forget addresses long gone
        for email in list(self.ipstate):
            seen = self.ipstate[email]
            for ip in [ip for ip, e in seen.items() if now - e.get("seen", 0) > 3600]:
                del seen[ip]
            if not seen:
                del self.ipstate[email]
        newly = {e: ips for e, ips in blocked.items() if ips != self.blocked.get(e)}
        for email, ips in newly.items():
            log("device limit: %s is over its limit of %d, refusing %s" % (email, self.limits.get(email, 0), ", ".join(ips)))
        self.blocked = blocked
        self.online = allowed_now
        self.push_rules()

    def report_online(self):
        self.enforce_limits()
        per_node = {}
        for email, ips in self.online.items():
            node_id, uid = email_node_uid(email)
            if node_id in self.panels:
                per_node.setdefault(node_id, []).extend({"subscription_id": uid, "ip": ip} for ip in ips)
        for node_id in self.panels:
            rows = per_node.get(node_id, [])
            counts = {}
            for row in rows:
                counts[row["subscription_id"]] = counts.get(row["subscription_id"], 0) + 1
            status = self.node_status(node_id)
            status["online_accounts"] = len(counts)
            status["online_ips"] = len(rows)
            if not rows:
                self.last_online[node_id] = {}
                continue
            try:
                self.panels[node_id].post("/api/onlineip/%d" % node_id, rows)
                self.last_online[node_id] = counts
            except PanelError as error:
                log("node %d: online addresses not reported: %s" % (node_id, error))

    # -------------------------------------------------------------- status

    def node_status(self, node_id):
        return self.state["status"].setdefault(str(node_id), {})

    def write_status(self):
        for node in self.conf["nodes"]:
            node_id = node["id"]
            status = self.node_status(node_id)
            spec = self.specs.get(node_id)
            status["running"] = spec is not None
            status["error"] = self.errors.get(node_id, "")
            status["warnings"] = self.warnings.get(node_id, [])
            status["accounts"] = len(self.clients.get(node_id, {}))
            status["blocked"] = sum(len(v) for e, v in self.blocked.items() if email_node_uid(e)[0] == node_id)
            if spec:
                status["summary"] = "%s %s %s port %s%s" % (
                    spec["type"], spec["network"], spec["security"], spec["port"],
                    (" (%s)" % spec["cert_domain"]) if spec["cert_domain"] else "")
                cert = self.certs.get(node_id)
                status["cert"] = cert_summary(cert[0]) if cert else ""
        self.state["status"]["_agent"] = {"version": VERSION, "at": int(time.time()), "pid": os.getpid()}
        self.save_state()

    # ----------------------------------------------------------------- run

    def guard(self, name, func, *args):
        try:
            func(*args)
        except Exception as error:  # one failing step must not stop the others
            log("%s failed: %s: %s" % (name, type(error).__name__, error))

    def stop(self, *_):
        self.running = False

    def run(self):
        try:
            signal.signal(signal.SIGTERM, self.stop)
            signal.signal(signal.SIGINT, self.stop)
        except ValueError:
            pass  # not the main thread (tests)
        log("digitsell-xray agent %s, Xray %s, node(s) %s" % (
            VERSION, xray_version(self.xray) or "?", ", ".join(str(n["id"]) for n in self.conf["nodes"])))
        # restore what the last run reported, so the device limit starts right
        self.guard("start", self.sync, True)
        self.write_status()
        now = time.time()
        next_sync = now + self.conf["interval"]
        next_limit = now + self.conf["limit_interval"]
        next_cert = now + CERT_CHECK
        while self.running:
            now = time.time()
            if now >= next_sync:
                next_sync = now + self.conf["interval"]
                self.guard("sync", self.sync)
                self.guard("traffic report", self.report_traffic)
                self.guard("online report", self.report_online)
                self.write_status()
                next_limit = time.time() + self.conf["limit_interval"]
            elif now >= next_limit:
                next_limit = now + self.conf["limit_interval"]
                if any(self.limits.values()):
                    self.guard("device limit", self.enforce_limits)
            if now >= next_cert:
                # a certificate not had yet is retried by sync; this renews the ones in place
                next_cert = now + CERT_CHECK
                self.guard("certificate renewal", self.renew_certs)
            time.sleep(1)
        log("stopping; reporting the last usage")
        self.guard("traffic report", self.report_traffic)
        if self.conf["xray_manager"] == "process":
            self.xray_stop()


# ----------------------------------------------------------------- helpers

def xray_version(binary):
    try:
        out = subprocess.run([binary, "version"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             universal_newlines=True, timeout=10).stdout
        match = re.search(r"Xray (\S+)", out)
        return match.group(1) if match else None
    except (OSError, subprocess.TimeoutExpired):
        return None


def cert_days_left(path):
    if not path or not os.path.isfile(path):
        return None
    try:
        out = subprocess.run(["openssl", "x509", "-enddate", "-noout", "-in", path], stdout=subprocess.PIPE,
                             stderr=subprocess.DEVNULL, universal_newlines=True, timeout=10).stdout
        end = out.strip().split("=", 1)[1]
        expires = time.mktime(time.strptime(end.replace(" GMT", ""), "%b %d %H:%M:%S %Y")) - time.timezone
        return int((expires - time.time()) // 86400)
    except (OSError, IndexError, ValueError, subprocess.TimeoutExpired):
        return None


def cert_summary(path):
    days = cert_days_left(path)
    if days is None:
        return path
    kind = "self-signed" if "self-signed" in path else "valid"
    return "%s, %d day(s) left" % (kind, days)


# ------------------------------------------------------------- commands

def cmd_check(conf, render_only=False):
    agent = Agent(conf)
    ok = True
    specs, clients = {}, {}
    for node in conf["nodes"]:
        node_id = node["id"]
        try:
            raw, subs, _ = agent.fetch(node_id, fresh=True)
            spec = parse_node(node_id, raw)
        except (PanelError, NodeError) as error:
            ok = False
            if not render_only:
                print("node %d: ERROR %s" % (node_id, error))
            continue
        chosen, limits = select_users(spec, subs, {})
        specs[node_id] = spec
        clients[node_id] = chosen
        agent.subs[node_id] = {user_email(node_id, s): s for s in subs if isinstance(s, dict)}
        if render_only:
            continue
        print("node %d: %s / %s / %s, port %s%s" % (
            node_id, spec["type"], spec["network"], spec["security"], spec["port"],
            (", listen " + spec["listen"]) if spec["listen"] else ""))
        if spec["security"] == "tls":
            print("    certificate: %s mode, domain %s" % (spec["certmode"], spec["cert_domain"] or "-"))
        if spec["network"] in ("ws", "xhttp", "httpupgrade"):
            print("    path %s, host %s%s" % (as_str(spec["net"].get("path")) or "/", as_str(spec["net"].get("host")) or "-",
                                         (", mode " + (as_str(spec["net"].get("mode")) or "auto")) if spec["network"] == "xhttp" else ""))
        print("    accounts: %d from the panel, %d let on (%d with a device limit)" % (
            len(subs), len(chosen), sum(1 for v in limits.values() if v)))
        if spec["relay"]:
            r = spec["relay"]
            print("    relay to %s:%d (%s / %s / %s)" % (r["address"], r["port"], r["type"], r["network"], r["security"]))
        if spec["rules"]:
            print("    %d block rule(s) from the panel" % len(spec["rules"]))
        for note in node_warnings(spec):
            print("    note: " + note)
    if render_only:
        agent.specs, agent.clients = specs, clients
        for node_id, spec in specs.items():
            if spec["security"] == "tls" and spec["certmode"] != "none":
                crt, key = agent.lego_paths(spec["cert_domain"]) if spec["certmode"] in ("http", "tls", "dns") else \
                    (os.path.join(ETC, "certs", spec["cert_domain"] + ".crt"), os.path.join(ETC, "certs", spec["cert_domain"] + ".key"))
                agent.certs[node_id] = (crt, key)
        print(dumps(agent.build_config()), end="")
    return 0 if ok else 1


def cmd_status(conf):
    path = os.path.join(conf["state_dir"], "state.json")
    try:
        with open(path) as handle:
            state = json.load(handle)
    except (OSError, ValueError):
        print("no status yet (%s) - is digitsell-xray-agent running?" % path)
        return 1
    status = state.get("status") or {}
    agent = status.get("_agent") or {}
    age = int(time.time()) - as_int(agent.get("at"))
    print("agent %s, last update %ds ago" % (agent.get("version", "?"), age))
    for node in conf["nodes"]:
        st = status.get(str(node["id"])) or {}
        line = "node %d: " % node["id"]
        if st.get("running"):
            line += "%s, %d account(s), %d online from %d address(es)" % (
                st.get("summary", ""), st.get("accounts", 0), st.get("online_accounts", 0), st.get("online_ips", 0))
            if st.get("blocked"):
                line += ", %d address(es) refused by the device limit" % st["blocked"]
        else:
            line += "NOT RUNNING"
        print(line)
        if st.get("cert"):
            print("    certificate: " + st["cert"])
        if st.get("traffic_at"):
            print("    usage last reported %ds ago (%d account(s))" % (int(time.time()) - st["traffic_at"], st.get("traffic_accounts", 0)))
        if st.get("error"):
            print("    error: " + st["error"])
        for note in st.get("warnings") or []:
            print("    note: " + note)
    pending = state.get("pending") or {}
    waiting = sum(len(v) for v in pending.values())
    if waiting:
        print("usage waiting for the panel: %d account(s)" % waiting)
    return 0


def cmd_doctor(conf):
    problems = 0

    def say(ok, text):
        nonlocal problems
        if not ok:
            problems += 1
        print(("  ok   " if ok else "  FAIL ") + text)

    print("services")
    for unit in (conf["service"], "digitsell-xray-agent"):
        active = subprocess.run(["systemctl", "is-active", unit], stdout=subprocess.PIPE,
                                universal_newlines=True).stdout.strip()
        say(active == "active", "%s: %s" % (unit, active))

    print("xray")
    version = xray_version(conf["xray"])
    say(version is not None, "binary %s: %s" % (conf["xray"], version or "missing"))
    agent = Agent(conf)
    try:
        agent.api("statsquery", "-pattern", "nothing>>>", timeout=3)
        say(True, "API answers at %s" % conf["api"])
    except XrayError as error:
        say(False, "API at %s: %s" % (conf["api"], error))
    if os.path.isfile(conf["xray_config"]):
        try:
            with open(conf["xray_config"]) as handle:
                error = agent.test_config(json.load(handle))
        except ValueError as exc:
            error = str(exc)
        say(error is None, "config %s %s" % (conf["xray_config"], "is valid" if error is None else ": " + error))
    else:
        say(False, "config %s is missing (the agent writes it)" % conf["xray_config"])

    print("panel")
    listening = subprocess.run(["ss", "-Hltnu"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                               universal_newlines=True).stdout
    for node in conf["nodes"]:
        node_id = node["id"]
        try:
            raw, _ = agent.panels[node_id].get_json("/api/server/%d" % node_id)
            spec = parse_node(node_id, raw)
            answer, _ = agent.panels[node_id].get_json("/api/subscriptions/%d" % node_id)
            subs = answer.get("subscriptions") or [] if isinstance(answer, dict) else []
            say(True, "node %d: %s %s %s port %s, %d account(s)" % (
                node_id, spec["type"], spec["network"], spec["security"], spec["port"], len(subs)))
        except (PanelError, NodeError) as error:
            say(False, "node %d: %s" % (node_id, error))
            continue
        first = spec["port"].split("-")[0]
        say(re.search(r"[:\]]%s\s" % re.escape(first), listening) is not None, "node %d: something listens on port %s" % (node_id, first))
        if spec["security"] == "tls" and spec["certmode"] != "none":
            crt = agent.lego_paths(spec["cert_domain"])[0] if spec["certmode"] in ("http", "tls", "dns") else None
            if crt and os.path.isfile(crt):
                days = cert_days_left(crt)
                say(days is not None and days > 7, "node %d: certificate for %s, %s day(s) left" % (node_id, spec["cert_domain"], days))
            elif spec["certmode"] in ("http", "tls", "dns"):
                say(False, "node %d: no Let's Encrypt certificate for %s yet (see: journalctl -u digitsell-xray-agent)" % (node_id, spec["cert_domain"]))
            try:
                resolved = sorted({a[4][0] for a in socket.getaddrinfo(spec["cert_domain"], None)})
                print("       %s resolves to %s" % (spec["cert_domain"], ", ".join(resolved)))
            except OSError as error:
                say(False, "node %d: %s does not resolve: %s" % (node_id, spec["cert_domain"], error))
        for note in node_warnings(spec):
            print("       note: " + note)

    print("system")
    try:
        with open("/proc/sys/net/ipv4/tcp_congestion_control") as handle:
            cc = handle.read().strip()
        say(cc == "bbr", "TCP congestion control: %s" % cc)
    except OSError:
        pass
    ntp = subprocess.run(["timedatectl", "show", "-p", "NTPSynchronized", "--value"], stdout=subprocess.PIPE,
                         stderr=subprocess.DEVNULL, universal_newlines=True).stdout.strip()
    if ntp:
        say(ntp == "yes", "clock synchronised (VMess and REALITY need the right time): %s" % ntp)
    print()
    print("all good" if problems == 0 else "%d problem(s)" % problems)
    return 0 if problems == 0 else 1


def main():
    args = sys.argv[1:]
    path = DEFAULT_CONFIG
    if "--config" in args:
        i = args.index("--config")
        path = args[i + 1]
        del args[i:i + 2]
    command = args[0] if args else "run"
    try:
        conf = load_config(path)
    except (OSError, ValueError) as error:
        print("cannot read %s: %s" % (path, error), file=sys.stderr)
        return 2
    if command == "run":
        Agent(conf).run()
        return 0
    if command == "check":
        return cmd_check(conf)
    if command == "render":
        return cmd_check(conf, render_only=True)
    if command == "status":
        return cmd_status(conf)
    if command == "doctor":
        return cmd_doctor(conf)
    if command in ("version", "--version"):
        print(VERSION)
        return 0
    print(__doc__.strip().split("Usage:")[1], file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
