"""Managed local WARP proxy. No host default-route or DNS changes."""
import os
import shutil
import subprocess
import threading
import time

PROXY = 'socks5://127.0.0.1:40000'
MARKER = '/etc/digitsell-xray/warp-managed'
INSTALL = r'''set -eu
. /etc/os-release
case "$ID:$VERSION_CODENAME" in
 ubuntu:jammy|ubuntu:noble|ubuntu:resolute|debian:bookworm|debian:trixie) ;;
 *) echo 'Automatic WARP installation requires supported Debian/Ubuntu'; exit 1;;
esac
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y ca-certificates curl gnupg
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL --retry 3 https://pkg.cloudflareclient.com/pubkey.gpg -o "$tmp"
gpg --batch --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg "$tmp"
printf 'deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ %s main\n' "$VERSION_CODENAME" > /etc/apt/sources.list.d/cloudflare-client.list
apt-get update -qq
apt-get install -y cloudflare-warp
'''


class WarpWorker(threading.Thread):
    def __init__(self):
        super().__init__(name='warp', daemon=True)
        self.wanted = False
        self.report = {'state': 'off', 'error': '', 'ip': ''}
        self.ready = False

    def run_command(self, args, timeout=60, check=True):
        result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                universal_newlines=True, timeout=timeout)
        if check and result.returncode:
            raise RuntimeError(result.stdout[-300:] or 'WARP command failed')
        return result

    def cli(self, *args, check=True):
        return self.run_command(['warp-cli', '--accept-tos'] + list(args), check=check)

    def ensure(self):
        if not os.path.exists(MARKER):
            if shutil.which('warp-cli'):
                raise RuntimeError('Existing unmanaged WARP detected; refusing to change its configuration')
            # Persist ownership before installation, allowing interrupted package installs to retry.
            with open(MARKER, 'w') as handle:
                handle.write('digitsell managed local proxy\n')
        if not shutil.which('warp-cli'):
            self.run_command(['bash', '-c', INSTALL], timeout=900)
        self.run_command(['systemctl', 'enable', '--now', 'warp-svc'])
        for _ in range(15):
            if self.cli('registration', 'show', check=False).returncode == 0:
                break
            time.sleep(2)
        else:
            self.cli('registration', 'new')
        # Always set proxy mode BEFORE connect. Never use the default full tunnel.
        self.cli('mode', 'proxy')
        self.cli('proxy', 'port', '40000')
        self.cli('connect')

    def probe(self):
        result = self.run_command(['curl', '-fsS', '--max-time', '20', '--socks5-hostname',
                                  '127.0.0.1:40000', 'https://www.cloudflare.com/cdn-cgi/trace'], timeout=25)
        fields = dict(line.split('=', 1) for line in result.stdout.splitlines() if '=' in line)
        if fields.get('warp') not in ('on', 'plus'):
            raise RuntimeError('Proxy answered without an active WARP tunnel')
        return fields.get('ip', '')

    def step(self):
        if not self.wanted:
            # Leave the shared proxy alive: other processes or an in-flight Xray config may use it.
            self.ready = False
            self.report = {'state': 'off', 'error': '', 'ip': ''}
            return
        try:
            if self.ready:
                ip = self.probe()
                self.report = {'state': 'ready', 'error': '', 'ip': ip}
                return
            self.report = {'state': 'connecting' if self.ready else 'installing', 'error': '', 'ip': ''}
            self.ensure()
            ip = self.probe()
            self.ready = True
            self.report = {'state': 'ready', 'error': '', 'ip': ip}
        except Exception as error:
            self.ready = False
            self.report = {'state': 'failed', 'error': str(error)[-300:], 'ip': ''}

    def run(self):
        while True:
            self.step()
            time.sleep(30)
