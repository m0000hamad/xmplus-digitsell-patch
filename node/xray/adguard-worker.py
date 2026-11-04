"""Private managed AdGuard Home. Only tunneled plain DNS is intercepted."""
import hashlib
import io
import json
import os
import platform
import socket
import struct
import subprocess
import tarfile
import threading
import time
import urllib.request

ROOT = '/opt/digitsell-adguard'
SERVICE = 'digitsell-adguard'
PORT = 55353


class AdguardWorker(threading.Thread):
    def __init__(self):
        super().__init__(name='adguard', daemon=True)
        self.wanted = False
        self.ready = False
        self.report = {'state': 'off', 'error': ''}

    def command(self, args):
        return subprocess.run(args, check=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=90)

    def download(self, url, maximum):
        if not url.startswith('https://github.com/AdguardTeam/AdGuardHome/') and not url.startswith('https://api.github.com/repos/AdguardTeam/AdGuardHome/'):
            raise RuntimeError('Unexpected AdGuard download source')
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'digitsell-adguard'}), timeout=60) as response:
            data = response.read(maximum + 1)
        if len(data) > maximum:
            raise RuntimeError('AdGuard download exceeds size limit')
        return data

    def ensure(self):
        if platform.system() != 'Linux':
            raise RuntimeError('AdGuard automatic setup requires Linux/systemd')
        marker = ROOT + '/managed'
        if os.path.exists(ROOT) and not os.path.isfile(marker):
            raise RuntimeError('Unmanaged AdGuard directory; refusing to overwrite')
        os.makedirs(ROOT, mode=0o700, exist_ok=True)
        with open(marker, 'a'):
            pass
        binary = ROOT + '/AdGuardHome'
        if not os.path.isfile(binary):
            arch = {'x86_64': 'amd64', 'aarch64': 'arm64'}.get(platform.machine())
            if not arch:
                raise RuntimeError('Unsupported AdGuard architecture')
            release = json.loads(self.download('https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest', 2000000))
            name = 'AdGuardHome_linux_%s.tar.gz' % arch
            assets = {item['name']: item['browser_download_url'] for item in release['assets']}
            archive = self.download(assets[name], 60000000)
            checks = self.download(assets['checksums.txt'], 1000000).decode()
            expected = next((line.split()[0] for line in checks.splitlines() if line.split()[-1].lstrip('*./') == name), '')
            if len(expected) != 64 or hashlib.sha256(archive).hexdigest() != expected:
                raise RuntimeError('AdGuard archive checksum mismatch')
            with tarfile.open(fileobj=io.BytesIO(archive), mode='r:gz') as package:
                member = next(m for m in package.getmembers() if m.name in ('AdGuardHome/AdGuardHome', './AdGuardHome/AdGuardHome'))
                if not member.isfile() or member.size > 150000000:
                    raise RuntimeError('Invalid AdGuard binary archive')
                data = package.extractfile(member).read()
            with open(binary + '.tmp', 'wb') as handle:
                handle.write(data)
            os.chmod(binary + '.tmp', 0o700)
            os.replace(binary + '.tmp', binary)
        config = ROOT + '/AdGuardHome.yaml'
        if not os.path.isfile(config):
            # JSON is valid YAML. Bind DNS and admin to loopback only; never expose setup UI.
            settings = {'http': {'address': '127.0.0.1:55354'},
                        'dns': {'bind_hosts': ['127.0.0.1'], 'port': PORT,
                                'upstream_dns': ['https://dns.cloudflare.com/dns-query'],
                                'bootstrap_dns': ['1.1.1.1', '9.9.9.9'], 'ratelimit': 0},
                        'filtering': {'protection_enabled': True, 'filtering_enabled': True,
                                      'filters_update_interval': 24},
                        'filters': [{'enabled': True, 'url': 'https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt',
                                     'name': 'AdGuard DNS filter', 'id': 1}],
                        'user_rules': ['||digitsell-adguard-check.invalid^'],
                        'querylog': {'enabled': False}, 'statistics': {'enabled': False},
                        'schema_version': 29}
            with open(config, 'w') as handle:
                json.dump(settings, handle)
            os.chmod(config, 0o600)
        unit = '/etc/systemd/system/%s.service' % SERVICE
        if os.path.isfile(unit):
            with open(unit) as handle:
                if '# digitsell-managed-adguard' not in handle.read():
                    raise RuntimeError('Unmanaged AdGuard unit; refusing to overwrite')
        else:
            self.command([binary, '--check-config', '-c', config, '-w', ROOT])
            with open(unit, 'w') as handle:
                handle.write('# digitsell-managed-adguard\n[Unit]\nAfter=network-online.target\n'
                             '[Service]\nExecStart=%s -c %s -w %s --no-check-update\n'
                             'Restart=on-failure\nUMask=0077\n[Install]\nWantedBy=multi-user.target\n' % (binary, config, ROOT))
            self.command(['systemctl', 'daemon-reload'])
        self.command(['systemctl', 'enable', '--now', SERVICE])

    def probe(self):
        if not os.path.isfile(ROOT + '/data/filters/1.txt') or os.path.getsize(ROOT + '/data/filters/1.txt') < 1000:
            raise RuntimeError('AdGuard DNS filter is still downloading or unavailable')
        name = 'digitsell-adguard-check.invalid'
        ident = os.urandom(2)
        question = b''.join(bytes([len(p)]) + p.encode() for p in name.split('.')) + b'\0\0\1\0\1'
        query = ident + b'\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00' + question
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.settimeout(4)
            sock.connect(('127.0.0.1', PORT))
            sock.send(query)
            answer = sock.recv(4096)
        if len(answer) < 12 or answer[:2] != ident or not answer[2] & 128:
            raise RuntimeError('Invalid AdGuard DNS response')
        # Default AdGuard blocking mode returns 0.0.0.0; allow NXDOMAIN too.
        if answer[3] & 15 != 3 and not (struct.unpack('!H', answer[6:8])[0] and answer.endswith(b'\0\0\0\0')):
            raise RuntimeError('AdGuard DNS filtering probe failed')

    def step(self):
        if not self.wanted:
            self.ready = False
            self.report = {'state': 'off', 'error': ''}
            return
        try:
            if not self.ready:
                self.report = {'state': 'installing', 'error': ''}
                self.ensure()
            self.probe()
            self.ready = True
            self.report = {'state': 'ready', 'error': ''}
        except Exception as error:
            self.ready = False
            self.report = {'state': 'failed', 'error': str(error)[-300:]}

    def run(self):
        while True:
            self.step()
            time.sleep(30)
