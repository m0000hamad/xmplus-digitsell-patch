#!/usr/bin/env python3
"""
Digitsell WireGuard agent - ties a WireGuard server to the XMPlus panel.

Runs next to the wg-quick interface (installed by install.sh). WireGuard has
no login to ask about, so there is less to do than on the OpenVPN node and
more to apply:

  * once a minute every peer's running byte counters go to wg.push. The panel
    adds the growth to the account's usage, the same traffic the Xray nodes
    report, and answers with the peers to add (a customer who has just been
    given a file) and the peers to remove (plan over, data used up, account
    disabled, or moved to another group). The agent applies both;
  * the answer also carries the panel's direct-route list - the Iran ranges
    and whatever the admin added - as CIDRs. The agent keeps an ipset with
    them and two iptables rules, so those destinations leave this server
    directly instead of through the tunnel. That is why a customer's .conf
    file is the same on every client: it holds no route lines.

The counters are running totals per peer, so a push that is sent twice, or
after the panel was unreachable for a while, is counted exactly once.

Peers are not removed from the interface just because they stop sending: a
customer who closes the app keeps their peer, and it answers again on the next
push. The panel decides that; this agent only does what it is told.

Python 3.6+, standard library only. Configuration: the JSON file install.sh
writes (default /etc/digitsell-wg/agent.json).

Two subcommands, both used by install.sh:
  wg-agent.py bypass-start <config>   put the routing mark, table and ipset up
  wg-agent.py bypass-stop  <config>   take them down again
"""

import json
import os
import re
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.request

VERSION = "1.0.0"

DEFAULT_CONFIG = "/etc/digitsell-wg/agent.json"
PUSH_INTERVAL = 60
HELLO_EVERY = 600
KEEPALIVE = 25

# a WireGuard key: 32 bytes, base64 with one padding character
KEY_RE = re.compile(r"^[A-Za-z0-9+/]{43}=$")
CIDR_RE = re.compile(r"^\d{1,3}(\.\d{1,3}){3}/(\d{1,2})$")
# the tunnel address the panel reserved: 10.<node>.<a>.<b>, a /32 in the node's /16
ADDRESS_RE = re.compile(r"^10\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$")


def log(*parts):
    print(time.strftime("%Y-%m-%d %H:%M:%S"), *parts, flush=True)


def run(*args, **kwargs):
    """Run a command; return (returncode, stdout). input_lines feeds stdin."""
    check = kwargs.pop("check", True)
    input_lines = kwargs.pop("input_lines", None)
    if kwargs:
        raise TypeError("run() got an unexpected argument: %s" % ", ".join(kwargs))

    try:
        done = subprocess.run(
            args,
            input=input_lines,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
    except (OSError, subprocess.SubprocessError) as error:
        if check:
            raise RuntimeError("%s: %s" % (args[0], error))
        return 1, str(error)
    return done.returncode, done.stdout or ""


def valid_key(text):
    return bool(KEY_RE.match((text or "").strip()))


def valid_cidr(text):
    match = CIDR_RE.match((text or "").strip())
    if not match:
        return False
    bits = int(match.group(2))
    return 8 <= bits <= 32


# --------------------------------------------------------------------- panel

class Panel:
    def __init__(self, config):
        self.base = config["panel"].rstrip("/") + "/xmplus-patch.php?do="
        self.headers = {
            "Content-Type": "application/json",
            "X-Wg-Node": str(config["node"]),
            "X-Wg-Key": config["key"],
            "User-Agent": "digitsell-wg-agent/" + VERSION,
        }
        self.context = ssl.create_default_context()
        if config.get("insecure_tls"):
            self.context.check_hostname = False
            self.context.verify_mode = ssl.CERT_NONE

    def call(self, action, payload, timeout=15):
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
            raise RuntimeError("panel refused %s: %s" % (action, answer.get("error", "no reason")))

        return answer


# ------------------------------------------------------------------ interface

class Interface:
    """`wg show` for one interface, and the `wg set` calls that change it."""

    def __init__(self, name):
        self.name = name
        self.gone = False

    def check(self):
        code, _ = run("wg", "show", self.name, check=False)
        if code != 0:
            if not self.gone:
                log("interface", self.name, "is not up yet; waiting")
                self.gone = True
            return False
        if self.gone:
            log("interface", self.name, "is up")
            self.gone = False
        return True

    def dump(self):
        """
        `wg show <if> dump`, whose first line is the interface itself and whose
        later lines are one peer each:
            public-key  preshared-key  endpoint  allowed-ips  latest-handshake
            rx  tx  keepalive
        """
        code, out = run("wg", "show", self.name, "dump", check=False)
        if code != 0:
            return {}
        peers = {}
        for line in out.splitlines()[1:]:
            parts = line.split("\t")
            if len(parts) < 8 or not valid_key(parts[0]):
                continue
            try:
                peers[parts[0].strip()] = {
                    "endpoint": parts[2].strip(),
                    "allowed": parts[3].strip(),
                    "handshake": int(parts[4] or 0),
                    "rx": int(parts[5] or 0),
                    "tx": int(parts[6] or 0),
                }
            except ValueError:
                continue
        return peers

    def set_peer(self, pubkey, address):
        """Add a peer, or give an existing one its address again."""
        run("wg", "set", self.name, "peer", pubkey,
            "allowed-ips", address + "/32",
            "persistent-keepalive", str(KEEPALIVE))

    def drop_peer(self, pubkey):
        run("wg", "set", self.name, "peer", pubkey, "remove", check=False)


# --------------------------------------------------------- direct-route list
#
# What the panel sends as `bypass`: a list of CIDRs that must leave this server
# directly instead of through the tunnel. They go into an ipset, and two rules
# in the mangle table decide their fate:
#
#   - a packet to a set address is RETURNed before the mark is set, so it
#     keeps the route it already had and goes out of the ordinary interface;
#   - everything else that comes in on the interface is marked, and
#     `ip rule` sends the marked traffic to a table whose default route is this
#     server's own gateway. Because the peers carry `Table = off`, no traffic
#     is routed by WireGuard itself: the table is the only way out.
#
# The two rules are in a chain of their own, so they can be rebuilt from
# scratch every time the list changes without touching the firewall's own rules.

class Bypass:
    CHAIN = "DSBYPASS"

    def __init__(self, config):
        self.config = config
        self.iface = config.get("interface", "wg0")
        self.set_name = config.get("bypass_set", "ds-bypass")
        self.mark = config.get("bypass_mark", "0x51820")
        self.table = str(config.get("bypass_table", "51820"))
        self._gateway = None

    # ------------------------------------------------------------- the set

    def ensure_set(self):
        code, out = run("ipset", "create", self.set_name,
                        "hash:net", "family", "inet", "-exist", check=False)
        if code != 0:
            raise RuntimeError("cannot create ipset %s: %s" % (self.set_name, out.strip()))

    def flush_set(self):
        run("ipset", "flush", self.set_name, check=False)

    def replace_set(self, cidrs):
        """
        Load a whole list at once. `ipset restore` reads it from stdin and is
        the only way to swap thousands of networks atomically, so a customer is
        never routed by a list that is half old and half new.
        """
        wanted = set()
        for text in cidrs or []:
            text = str(text).strip()
            if valid_cidr(text):
                wanted.add(text)

        code, out = run("ipset", "list", self.set_name, "-o", "save", check=False)
        have = set()
        if code == 0:
            for line in out.splitlines():
                if line.startswith("add "):
                    have.add(line.split()[2])

        if wanted == have:
            return len(wanted), 0

        if wanted:
            lines = ["create %s hash:net family inet -exist" % self.set_name]
            lines += ["add %s %s" % (self.set_name, cidr) for cidr in sorted(wanted)]
            run("ipset", "restore", input_lines="\n".join(lines) + "\n")
        else:
            self.flush_set()

        return len(wanted), len(have - wanted)

    # ---------------------------------------------------------- the routing

    def get_gateway(self):
        if self._gateway:
            return self._gateway
        code, out = run("ip", "route", "show", "default", check=False)
        match = re.search(r"default via (\d+\.\d+\.\d+\.\d+)", out)
        if not match:
            code2, out2 = run("ip", "-4", "route", "get", "1.1.1.1", check=False)
            match2 = re.search(r"via (\d+\.\d+\.\d+\.\d+)", out2)
            if match2:
                self._gateway = match2.group(1)
                return self._gateway
            raise RuntimeError("this server has no default route, so the direct list cannot be used")
        self._gateway = match.group(1)
        return self._gateway

    def start(self):
        """
        Put the chain, the mark, the table and the rule up. Runs before
        wg-quick, so it is cheap and does not depend on the interface.
        """
        self.ensure_set()

        gateway = self.get_gateway()
        node_id = int(self.config.get("node", 1))
        subnet = "10.%d.0.0/16" % node_id

        run("iptables", "-t", "mangle", "-N", self.CHAIN, check=False)
        # drop anything left over by an earlier run before rebuilding
        while True:
            code, _ = run("iptables", "-t", "mangle", "-C", "PREROUTING",
                          "-j", self.CHAIN, check=False)
            if code != 0:
                break
            run("iptables", "-t", "mangle", "-D", "PREROUTING", "-j", self.CHAIN)
        run("iptables", "-t", "mangle", "-I", "PREROUTING", "1", "-j", self.CHAIN)

        # a listed destination: no mark, so it keeps the route it already has
        run("iptables", "-t", "mangle", "-F", self.CHAIN)
        run("iptables", "-t", "mangle", "-A", self.CHAIN,
            "-m", "set", "--match-set", self.set_name, "dst", "-j", "RETURN")
        # everything else on the interface goes through the table
        run("iptables", "-t", "mangle", "-A", self.CHAIN,
            "-i", self.iface, "-j", "MARK", "--set-mark", self.mark)
        # and the marked traffic is answered from the main routing table
        run("ip", "rule", "add", "fwmark", self.mark, "table", self.table, check=False)
        run("ip", "route", "replace", "default", "via", gateway, "table", self.table)

        # NAT for WireGuard subnet
        while run("iptables", "-t", "nat", "-D", "POSTROUTING", "-s", subnet, "-j", "MASQUERADE", check=False)[0] == 0:
            pass
        run("iptables", "-t", "nat", "-A", "POSTROUTING", "-s", subnet, "-j", "MASQUERADE")

        # Forwarding rules
        while run("iptables", "-D", "FORWARD", "-i", self.iface, "-j", "ACCEPT", check=False)[0] == 0:
            pass
        run("iptables", "-A", "FORWARD", "-i", self.iface, "-j", "ACCEPT")

        while run("iptables", "-D", "FORWARD", "-o", self.iface, "-m", "state", "--state", "RELATED,ESTABLISHED", "-j", "ACCEPT", check=False)[0] == 0:
            pass
        run("iptables", "-A", "FORWARD", "-o", self.iface, "-m", "state", "--state", "RELATED,ESTABLISHED", "-j", "ACCEPT")

        log("direct routes: table", self.table, "via", gateway, "for everything not in",
            self.set_name)

    def stop(self):
        node_id = int(self.config.get("node", 1))
        subnet = "10.%d.0.0/16" % node_id

        while True:
            code, _ = run("iptables", "-t", "mangle", "-C", "PREROUTING",
                          "-j", self.CHAIN, check=False)
            if code != 0:
                break
            run("iptables", "-t", "mangle", "-D", "PREROUTING", "-j", self.CHAIN)
        run("iptables", "-t", "mangle", "-F", self.CHAIN, check=False)
        run("iptables", "-t", "mangle", "-X", self.CHAIN, check=False)
        run("ip", "rule", "del", "fwmark", self.mark, "table", self.table, check=False)
        run("ip", "route", "flush", "table", self.table, check=False)
        run("ipset", "destroy", self.set_name, check=False)

        run("iptables", "-t", "nat", "-D", "POSTROUTING", "-s", subnet, "-j", "MASQUERADE", check=False)
        run("iptables", "-D", "FORWARD", "-i", self.iface, "-j", "ACCEPT", check=False)
        run("iptables", "-D", "FORWARD", "-o", self.iface, "-m", "state", "--state", "RELATED,ESTABLISHED", "-j", "ACCEPT", check=False)

    # ------------------------------------------------------------ the agent

    def refresh(self, cidrs):
        """Bring the list up to what the panel just sent. Never fatal."""
        try:
            self.ensure_set()
            kept, dropped = self.replace_set(cidrs)
        except Exception as error:
            log("direct routes: not updated:", error)
            return False
        if kept or dropped:
            log("direct routes:", kept, "networks in", self.set_name,
                "(+%d, -%d)" % (max(0, kept - (kept - dropped)), dropped))
        return True


# --------------------------------------------------------------------- agent

class Agent:
    def __init__(self, config):
        self.config = config
        self.panel = Panel(config)
        self.iface = Interface(config.get("interface", "wg0"))
        self.bypass = Bypass(config)
        self.peers = {}      # pubkey -> address we gave it
        self.next_hello = 0

    def hello(self):
        payload = {
            "host": self.config.get("host", ""),
            "port": int(self.config.get("listen_port", 0)),
            "pubkey": self.config["public_key"],
            "dns": self.config.get("dns", ""),
            "mtu": int(self.config.get("mtu", 1420) or 1420),
            "version": VERSION,
        }
        return self.panel.call("wg.hello", payload)

    def run(self):
        log("digitsell-wg-agent", VERSION, "starting for", self.config["panel"])

        # the routing has to exist before the first customer connects
        try:
            self.bypass.start()
        except Exception as error:
            log("direct routes: not set up:", error)

        while True:
            if time.time() >= self.next_hello:
                self.next_hello = time.time() + HELLO_EVERY
                try:
                    self.hello()
                except Exception as error:
                    log("hello failed:", error)

            if not self.iface.check():
                time.sleep(5)
                continue

            try:
                self.push()
            except Exception as error:
                log("push failed:", error)

            time.sleep(PUSH_INTERVAL)

    def push(self):
        dump = self.iface.dump()
        peers, closed = [], []

        for pubkey, item in dump.items():
            # the interface itself, not a customer
            if not valid_key(pubkey):
                continue
            address = item["allowed"].split(",")[0].split("/")[0].strip()
            row = {
                "pubkey": pubkey,
                "ip": address,
                "endpoint": item["endpoint"],
                "rx": item["rx"],
                "tx": item["tx"],
            }
            # a peer that has never said anything and was just added by us is
            # not a connection; the panel should not be told about it yet
            if item["handshake"] > 0 or item["rx"] > 0 or item["tx"] > 0:
                peers.append(row)
            else:
                closed.append(row)

        answer = self.panel.call("wg.push", {"peers": peers, "closed": closed})
        self.apply(answer)
        self.bypass.refresh(answer.get("bypass"))

    def apply(self, answer):
        """
        The panel's answers: peers to add, peers to remove. A peer that is
        added is one a customer has just been given a file for, so it gets its
        address; a peer that is removed is one whose account may no longer
        connect.
        """
        for item in answer.get("add", []):
            pubkey = str(item.get("pubkey", "")).strip()
            address = str(item.get("address", "")).strip()
            if not valid_key(pubkey) or not ADDRESS_RE.match(address):
                continue
            try:
                self.iface.set_peer(pubkey, address)
                self.peers[pubkey] = address
                log("peer added:", pubkey[:12] + "…", address)
            except Exception as error:
                log("peer", pubkey[:12] + "…", "not added:", error)

        for item in answer.get("remove", []):
            pubkey = str(item.get("pubkey", "")).strip()
            if not valid_key(pubkey):
                continue
            try:
                self.iface.drop_peer(pubkey)
                self.peers.pop(pubkey, None)
                log("peer removed:", pubkey[:12] + "…", item.get("reason", ""))
            except Exception as error:
                log("peer", pubkey[:12] + "…", "not removed:", error)


# ----------------------------------------------------------------------- main

def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("bypass-start", "bypass-stop"):
        command = sys.argv[1]
        path = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_CONFIG
    elif len(sys.argv) > 2 and sys.argv[2] in ("bypass-start", "bypass-stop"):
        command = sys.argv[2]
        path = sys.argv[1]
    else:
        path = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else DEFAULT_CONFIG
        command = ""

    with open(path) as handle:
        config = json.load(handle)

    if command == "bypass-start":
        Bypass(config).start()
        return
    if command == "bypass-stop":
        Bypass(config).stop()
        return

    for name in ("panel", "node", "key", "public_key"):
        if not config.get(name):
            sys.exit("config %s: %s is missing" % (path, name))

    if "--check" in sys.argv:
        Agent(config).hello()
        print("ok")
        return

    Agent(config).run()


if __name__ == "__main__":
    main()