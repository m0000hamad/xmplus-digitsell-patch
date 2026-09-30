#!/usr/bin/env python3
"""
Digitsell OpenVPN agent - ties an OpenVPN server to the XMPlus panel.

Runs next to OpenVPN (installed by install.sh) and holds the management
interface of each OpenVPN instance - one for UDP and one for TCP with
--proto both - started with --management-client-auth, so every login is
decided here:

  * a connecting client's username / password go to the panel
    (xmplus-patch.php?do=ovpn.auth); the panel says whether the account may
    connect (plan running, data left, group, device limit);
  * once a minute every session's running byte counters go to ovpn.push; the
    panel adds the growth to the account's usage, the same traffic the Xray
    nodes report, and answers which sessions must be cut (plan over, data used
    up, account disabled) - the agent kills those;
  * a disconnect's final counters are sent with the next push.

The counters are running totals per session, so a push that is sent twice, or
after the panel was unreachable for a while, is counted exactly once.

If the panel cannot be reached, a login that succeeded in the last few hours
with the same password is let in, so a panel outage does not take the VPN
down; usage keeps accumulating and is reported when the panel is back.

Python 3.6+, standard library only. Configuration: a JSON file, see
install.sh (default /etc/digitsell-ovpn/agent.json).
"""

import concurrent.futures
import hashlib
import json
import os
import queue
import re
import socket
import ssl
import sys
import threading
import time
import urllib.error
import urllib.request

VERSION = "1.2.0"

DEFAULT_CONFIG = "/etc/digitsell-ovpn/agent.json"
AUTH_CACHE_SECONDS = 6 * 3600
HELLO_EVERY = 600
MAX_CLOSED_BACKLOG = 20000


def log(*parts):
    print(time.strftime("%Y-%m-%d %H:%M:%S"), *parts, flush=True)


def read_file(path):
    with open(path, "r") as handle:
        return handle.read()


# --------------------------------------------------------------------- panel

class Panel:
    def __init__(self, config):
        self.base = config["panel"].rstrip("/") + "/xmplus-patch.php?do="
        self.headers = {
            "Content-Type": "application/json",
            "X-Ovpn-Node": str(config["node"]),
            "X-Ovpn-Key": config["key"],
            "User-Agent": "digitsell-ovpn-agent/" + VERSION,
        }
        self.context = ssl.create_default_context()
        if config.get("insecure_tls"):
            self.context.check_hostname = False
            self.context.verify_mode = ssl.CERT_NONE

    def call(self, action, payload, timeout=10):
        request = urllib.request.Request(
            self.base + action,
            data=json.dumps(payload).encode("utf-8"),
            headers=self.headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=timeout, context=self.context) as response:
                body = response.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as error:
            body = error.read().decode("utf-8", "replace")
            raise RuntimeError("HTTP %s from panel: %s" % (error.code, body[:200]))

        try:
            answer = json.loads(body)
        except ValueError:
            raise RuntimeError("panel answered something that is not JSON: %s" % body[:200])

        if not answer.get("ok"):
            raise RuntimeError("panel refused %s: %s" % (action, answer.get("error")))

        return answer


# ---------------------------------------------------------------- management

class ManagementError(Exception):
    pass


class Management:
    """One connection to OpenVPN's management interface.

    A reader thread splits what arrives into real-time notifications (lines
    starting with '>', CLIENT notifications gathered with their ENV block) and
    command replies, which go to a queue read by command().
    """

    def __init__(self, host, port, password, on_notice):
        self.host = host
        self.port = port
        self.password = password
        self.on_notice = on_notice
        self.sock = None
        self.replies = queue.Queue()
        self.command_lock = threading.Lock()
        self.write_lock = threading.Lock()
        self.alive = False

    def connect(self):
        self.sock = socket.create_connection((self.host, self.port), timeout=10)
        self.sock.settimeout(None)
        self.file = self.sock.makefile("rb")

        if self.password:
            # the prompt has no newline after it
            prompt = b""
            while b"ENTER PASSWORD:" not in prompt and len(prompt) < 256:
                chunk = self.sock.recv(1)
                if not chunk:
                    raise ManagementError("management socket closed during login")
                prompt += chunk
            self.write(self.password)

        self.alive = True
        self.reader = threading.Thread(target=self.read_loop, daemon=True)
        self.reader.start()

    def close(self):
        self.alive = False
        try:
            self.sock.close()
        except Exception:
            pass
        # wake anybody waiting on a reply
        self.replies.put(None)

    def write(self, line):
        with self.write_lock:
            self.sock.sendall((line + "\n").encode("utf-8"))

    def read_loop(self):
        client = None  # the CLIENT notification whose ENV block is being read
        try:
            while self.alive:
                raw = self.file.readline()
                if not raw:
                    break
                line = raw.decode("utf-8", "replace").rstrip("\r\n")

                if line.startswith(">CLIENT:ENV,"):
                    pair = line[len(">CLIENT:ENV,"):]
                    if pair == "END":
                        if client is not None:
                            self.on_notice(client)
                        client = None
                    elif client is not None and "=" in pair:
                        name, value = pair.split("=", 1)
                        client["env"][name] = value
                    continue

                if line.startswith(">CLIENT:"):
                    head = line[len(">CLIENT:"):].split(",")
                    notice = {"type": head[0], "args": head[1:], "env": {}}
                    if head[0] in ("CONNECT", "REAUTH", "ESTABLISHED", "DISCONNECT", "CR_RESPONSE"):
                        client = notice  # an ENV block follows
                    else:
                        self.on_notice(notice)
                    continue

                if line.startswith(">"):
                    continue  # INFO, LOG, STATE, HOLD, BYTECOUNT: nothing to do

                self.replies.put(line)
        except Exception as error:
            log("management read failed:", error)
        finally:
            self.alive = False
            self.replies.put(None)

    def command(self, line, multiline=False, timeout=15):
        """Send one command and return its reply (a list of lines when multiline)."""
        with self.command_lock:
            if not self.alive:
                raise ManagementError("not connected")
            # drop anything left over from a command that timed out
            while not self.replies.empty():
                self.replies.get_nowait()
            self.write(line)
            lines = []
            while True:
                try:
                    reply = self.replies.get(timeout=timeout)
                except queue.Empty:
                    raise ManagementError("no answer to %s" % line.split(" ")[0])
                if reply is None:
                    raise ManagementError("management connection lost")
                if not multiline:
                    if reply.startswith("ERROR:"):
                        raise ManagementError(reply)
                    return reply
                if reply == "END":
                    return lines
                if reply.startswith("ERROR:"):
                    raise ManagementError(reply)
                lines.append(reply)


# --------------------------------------------------------------------- agent

def client_ip(address):
    """'1.2.3.4:51820' -> '1.2.3.4'; tolerates a 'udp4:' prefix and IPv6."""
    address = re.sub(r"^(udp|tcp)[46]?(-server|-client)?:", "", address or "")
    if address.startswith("["):
        return address[1:address.find("]")] if "]" in address else address.strip("[]")
    if address.count(":") == 1:
        return address.split(":")[0]
    return address


class Instance:
    """One OpenVPN process - one protocol - and the management connection to it.

    install.sh runs a UDP and a TCP instance side by side (--proto both), each
    on its own management port. Session ids of the UDP instance keep the form
    agents before 1.2.0 used; the TCP instance prefixes its own with "t", so
    the two never collide in the panel.
    """

    def __init__(self, agent, spec):
        config = agent.config
        self.agent = agent
        self.proto = "tcp" if str(spec.get("proto", "udp")).startswith("tcp") else "udp"
        self.port = int(spec.get("port", config.get("port", 1194)))
        self.mgmt_port = int(spec.get("mgmt_port", 7505))
        self.excluded_file = spec.get("excluded_file", "")
        self.tag = "" if self.proto == "udp" else "t"
        self.mgmt = None
        self.known = {}  # client id -> session id, from the last status

    def connected(self):
        return self.mgmt is not None and self.mgmt.alive

    def excluded_ports(self):
        try:
            return [int(p) for p in read_file(self.excluded_file).split() if p.isdigit()]
        except Exception:
            return []

    def keep_connected(self):
        """Thread: hold the management connection, reconnecting after OpenVPN restarts."""
        config = self.agent.config
        while True:
            if not self.connected():
                try:
                    mgmt = Management(
                        config.get("mgmt_host", "127.0.0.1"),
                        self.mgmt_port,
                        read_file(config["mgmt_password_file"]).strip()
                        if config.get("mgmt_password_file") else "",
                        lambda notice: self.agent.on_notice(self, notice),
                    )
                    mgmt.connect()
                    self.mgmt = mgmt
                    log("connected to OpenVPN (%s) management on port %d" % (self.proto, self.mgmt_port))
                except Exception as error:
                    log("cannot reach OpenVPN (%s) management (%s); retrying" % (self.proto, error))
                    time.sleep(5)
                    continue
            time.sleep(2)

    def sessions(self):
        """Live sessions from 'status 3', with their running byte counters."""
        lines = self.mgmt.command("status 3", multiline=True)
        columns = None
        rows = []
        for line in lines:
            fields = line.split("\t")
            if fields[0] == "HEADER" and len(fields) > 1 and fields[1] == "CLIENT_LIST":
                columns = fields[2:]
            elif fields[0] == "CLIENT_LIST" and columns:
                row = dict(zip(columns, fields[1:]))
                cid = row.get("Client ID", "")
                since = row.get("Connected Since (time_t)", "0")
                user = row.get("Username", "")
                if user in ("", "UNDEF"):
                    user = row.get("Common Name", "")
                rows.append({
                    "instance": self,
                    "cid": cid,
                    "sid": "%s%s-%s" % (self.tag, cid, since),
                    "user": user,
                    "ip": client_ip(row.get("Real Address", "")),
                    "vip": row.get("Virtual Address", ""),
                    "rx": int(row.get("Bytes Received", "0") or 0),
                    "tx": int(row.get("Bytes Sent", "0") or 0),
                })
        self.known = {row["cid"]: row["sid"] for row in rows}
        return rows


class Agent:
    def __init__(self, config):
        self.config = config
        self.panel = Panel(config)
        self.interval = int(config.get("interval", 60))
        self.pool = concurrent.futures.ThreadPoolExecutor(max_workers=int(config.get("workers", 8)))
        self.closed = []            # final counters of sessions that ended, waiting for a push
        self.closed_lock = threading.Lock()
        self.auth_cache = {}        # (user, sha256(password)) -> time of the last panel "yes"
        self.last_hello = 0

        # configs written before 1.2.0 describe a single instance at the top level
        specs = config.get("instances") or [{
            "proto": config.get("proto", "udp"),
            "port": config.get("port", 1194),
            "mgmt_port": config.get("mgmt_port", 7505),
            "excluded_file": config.get("excluded_file", ""),
        }]
        self.instances = [Instance(self, spec) for spec in specs]

    # -- panel ------------------------------------------------------------

    def hello(self):
        first = self.instances[0]
        listen = {}
        for instance in self.instances:
            listen[instance.proto] = {
                "port": instance.port,
                # every port redirected to OpenVPN except these (digitsell-ovpn-nat)
                "all_ports": bool(self.config.get("all_ports")),
                "excluded": instance.excluded_ports(),
            }
        payload = {
            "host": self.config.get("host", ""),
            "ca": read_file(self.config["ca"]),
            "tls_crypt": read_file(self.config["tls_crypt"]),
            "version": VERSION,
            "listen": listen,
            # what panels before 1.14.0 read
            "port": first.port,
            "proto": first.proto,
            "all_ports": bool(self.config.get("all_ports")),
            "excluded": first.excluded_ports(),
        }
        answer = self.panel.call("ovpn.hello", payload)
        self.interval = int(answer.get("interval", self.interval)) or 60
        self.last_hello = time.time()
        log("registered with the panel as node", answer.get("node"), repr(answer.get("name")),
            "(%s)" % ", ".join(sorted(listen)))

    # -- logins -----------------------------------------------------------

    def on_notice(self, instance, notice):
        kind = notice["type"]
        if kind in ("CONNECT", "REAUTH"):
            self.pool.submit(self.decide, instance, notice)
        elif kind == "DISCONNECT":
            self.remember_closed(instance, notice)

    def decide(self, instance, notice):
        cid = notice["args"][0] if notice["args"] else ""
        kid = notice["args"][1] if len(notice["args"]) > 1 else "0"
        env = notice["env"]
        user = env.get("username", "") or env.get("common_name", "")
        password = env.get("password", "")
        ip = env.get("untrusted_ip", "") or env.get("trusted_ip", "")
        reauth = notice["type"] == "REAUTH"

        allow, reason = False, "denied"

        if reauth and not password:
            # a renegotiation of a session that already signed in; the push
            # loop cuts it if the account runs out
            allow, reason = True, ""
        else:
            key = (user, hashlib.sha256(password.encode("utf-8")).hexdigest())
            try:
                answer = self.panel.call("ovpn.auth", {"user": user, "pass": password, "ip": ip})
                allow, reason = bool(answer.get("allow")), answer.get("reason") or "denied"
                if allow:
                    self.auth_cache[key] = time.time()
                else:
                    self.auth_cache.pop(key, None)
            except Exception as error:
                cached = self.auth_cache.get(key, 0)
                allow = reauth or time.time() - cached < AUTH_CACHE_SECONDS
                reason = "" if allow else "panel unreachable"
                log("auth for", user, "could not reach the panel (%s);" % error,
                    "let in from cache" if allow else "refused")

        try:
            if allow:
                instance.mgmt.command("client-auth-nt %s %s" % (cid, kid))
            else:
                message = {
                    "password": "wrong username or password",
                    "expired": "subscription expired",
                    "quota": "no data left on the subscription",
                    "disabled": "account disabled",
                    "group": "this server is not part of your plan",
                    "iplimit": "device limit reached",
                    "off": "OpenVPN is switched off",
                    "node": "this server is switched off",
                }.get(reason, "not allowed")
                instance.mgmt.command('client-deny %s %s "%s" "%s"' % (cid, kid, reason, message))
            if not allow or not reauth:
                log("login", user, "from", ip, "over", instance.proto, "->",
                    "allowed" if allow else "denied (%s)" % reason)
        except Exception as error:
            log("could not answer the login of", user, ":", error)

    # -- usage ------------------------------------------------------------

    def remember_closed(self, instance, notice):
        env = notice["env"]
        cid = notice["args"][0] if notice["args"] else ""
        sid = instance.known.pop(cid, None)
        rx = int(env.get("bytes_received", "0") or 0)
        tx = int(env.get("bytes_sent", "0") or 0)
        if sid is None:
            if rx + tx == 0:
                return  # a refused login, or a session that never carried traffic
            sid = "%s%s-%s" % (instance.tag, cid, env.get("time_unix", "0"))
        record = {
            "sid": sid,
            "user": env.get("username", "") or env.get("common_name", ""),
            "ip": env.get("trusted_ip", "") or env.get("untrusted_ip", ""),
            "vip": env.get("ifconfig_pool_remote_ip", ""),
            "rx": rx,
            "tx": tx,
        }
        with self.closed_lock:
            self.closed.append(record)
            del self.closed[:-MAX_CLOSED_BACKLOG]

    def push(self):
        live = []
        for instance in self.instances:
            if not instance.connected():
                continue
            try:
                live.extend(instance.sessions())
            except ManagementError as error:
                log("management (%s):" % instance.proto, error)
                instance.mgmt.close()

        with self.closed_lock:
            closed = list(self.closed)

        answer = self.panel.call("ovpn.push", {
            "version": VERSION,
            "sessions": [{k: row[k] for k in ("sid", "user", "ip", "vip", "rx", "tx")} for row in live],
            "closed": closed,
        }, timeout=30)

        with self.closed_lock:
            # only what was sent is settled; anything newer waits for the next push
            sent = {id(record) for record in closed}
            self.closed = [record for record in self.closed if id(record) not in sent]

        self.interval = int(answer.get("interval", self.interval)) or 60

        by_sid = {row["sid"]: row for row in live}
        for item in answer.get("kick", []):
            row = by_sid.get(item.get("sid"))
            if row is None:
                continue
            try:
                row["instance"].mgmt.command("client-kill %s" % row["cid"])
                log("cut", row["user"], "(%s)" % item.get("reason", ""))
            except Exception as error:
                log("could not cut", row["user"], ":", error)

    # -- main loop --------------------------------------------------------

    def run(self):
        for instance in self.instances:
            threading.Thread(target=instance.keep_connected, daemon=True).start()

        next_push = time.time() + 5  # give the connections a moment
        while True:
            now = time.time()
            if now - self.last_hello > HELLO_EVERY:
                try:
                    self.hello()
                except Exception as error:
                    log("hello failed:", error)
                    self.last_hello = now - HELLO_EVERY + 60  # try again in a minute
            if now >= next_push:
                # with no OpenVPN reachable there is nothing true to report;
                # the panel then sees the node as down
                if any(instance.connected() for instance in self.instances):
                    try:
                        self.push()
                    except Exception as error:
                        log("push failed:", error)
                next_push = time.time() + self.interval
            time.sleep(1)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_CONFIG
    with open(path) as handle:
        config = json.load(handle)

    for name in ("panel", "node", "key", "ca", "tls_crypt"):
        if not config.get(name):
            sys.exit("config %s: %s is missing" % (path, name))

    if "--check" in sys.argv:
        agent = Agent(config)
        agent.hello()
        print("ok")
        return

    log("digitsell-ovpn-agent", VERSION, "starting for", config["panel"])
    Agent(config).run()


if __name__ == "__main__":
    main()
