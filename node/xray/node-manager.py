#!/usr/bin/env python3
"""Manage this machine's node membership without reinstalling Xray."""
import argparse
import copy
import fcntl
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


def node_id(entry):
    return int(entry['id'] if isinstance(entry, dict) else entry)


def parse_ids(values):
    parts = re.split(r'[\s,]+', ' '.join(values).strip())
    if not parts or any(not p.isascii() or not p.isdigit() or int(p) <= 0 for p in parts):
        raise ValueError('Enter positive node IDs, separated by spaces or commas.')
    return list(dict.fromkeys(map(int, parts)))


def change_nodes(conf, action, ids):
    result = copy.deepcopy(conf)
    old = conf.get('nodes') or []
    existing = {node_id(n) for n in old}
    if action == 'add':
        result['nodes'] = old + [n for n in ids if n not in existing]
    else:
        missing = set(ids) - existing
        if missing:
            raise ValueError('Not configured here: ' + ', '.join(map(str, sorted(missing))))
        result['nodes'] = [n for n in old if node_id(n) not in ids]
        if not result['nodes']:
            raise ValueError('Cannot remove every node. Use Stop or Uninstall instead.')
    return result


def atomic_write(path, data):
    fd, name = tempfile.mkstemp(prefix='.node-manager-', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'wb') as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def save_config(path, original, conf, restart):
    if path.read_bytes() != original:
        raise ValueError('Configuration changed while answering; run again.')
    # The backup includes credentials, so both files are private (mkstemp: 0600).
    backup = path.with_name(path.name + '.before-nodes')
    atomic_write(backup, original)
    atomic_write(path, (json.dumps(conf, indent=2, ensure_ascii=False) + '\n').encode())
    try:
        restart()
    except Exception:
        atomic_write(path, original)
        restart()
        raise
    print('Saved; agent restarted. Backup: %s' % backup)
    print('Run dxray status / dxray log -n 50 to check node activation.')


def load_agent():
    spec = importlib.util.spec_from_file_location('dxray_agent',
        '/usr/local/lib/digitsell-xray/xray-agent.py')
    agent = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(agent)
    return agent


def show_nodes(conf):
    print('Nodes configured on this machine (panel records are not changed):')
    for entry in conf.get('nodes', []):
        extra = ''
        if isinstance(entry, dict):
            extra = '  exit: ' + str(entry.get('tor') or ('SOCKS5' if entry.get('proxy') else 'direct'))
        print('  %s%s' % (node_id(entry), extra))


def validate_additions(agent, path, conf, ids):
    # Normalize exactly as the running agent does, including per-node panel/key.
    fd, name = tempfile.mkstemp(suffix='.json', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'w') as handle:
            json.dump(conf, handle)
        normalized = agent.load_config(name)
    finally:
        os.unlink(name)
    occupied = []
    added_ports = []
    for node in normalized['nodes']:
        panel = agent.Panel(node['panel'], node['key'], 15)
        raw, _ = panel.get_json('/api/server/%d' % node['id'])
        spec = agent.parse_node(node['id'], raw)
        ports = list(map(int, spec['port'].split('-')))
        low, high = ports[0], ports[-1]
        if not 1 <= low <= high <= 65535:
            raise ValueError('Invalid port range on node %s.' % node['id'])
        for other, start, end in occupied:
            if max(start, low) <= min(end, high):
                raise ValueError('Nodes %s and %s share a listening port.' % (other, node['id']))
        occupied.append((node['id'], low, high))
        if node['id'] not in ids:
            continue
        print('  Add %s: %s / %s / %s, port %s' %
              (node['id'], spec['type'], spec['network'], spec['security'], spec['port']))
        added_ports.append(spec['port'].replace('-', ':'))
        for warning in agent.node_warnings(spec):
            print('  warning: ' + warning)
        if spec['security'] == 'tls' and spec['certmode'] == 'file':
            cert = conf.get('cert') or {}
            crt = node.get('cert_file') or cert.get('file') or str(path.parent / 'certs' / (spec['cert_domain'] + '.crt'))
            key = node.get('key_file') or cert.get('key') or str(path.parent / 'certs' / (spec['cert_domain'] + '.key'))
            if not os.path.isfile(crt) or not os.path.isfile(key):
                crt = input('Certificate file for node %s: ' % node['id']).strip()
                key = input('Private key file: ').strip()
                if not os.path.isfile(crt) or not os.path.isfile(key):
                    raise ValueError('Certificate or private key file does not exist.')
                index = next(i for i, n in enumerate(conf['nodes']) if node_id(n) == node['id'])
                conf['nodes'][index] = {'id': node['id'], 'cert_file': crt, 'key_file': key}
    return added_ports


def open_firewall(ports):
    import shutil
    if not ports or not shutil.which('ufw'):
        return
    status = subprocess.run(['ufw', 'status'], capture_output=True, text=True)
    if 'Status: active' not in status.stdout:
        return
    for port in ports:
        for protocol in ('tcp', 'udp'):
            result = subprocess.run(['ufw', 'allow', '%s/%s' % (port, protocol)],
                                    capture_output=True, text=True)
            if result.returncode:
                print('warning: could not open %s/%s in ufw; check the firewall.' % (port, protocol))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', default='/etc/digitsell-xray/agent.json')
    parser.add_argument('action', choices=['list', 'add', 'remove'])
    parser.add_argument('ids', nargs='*')
    args = parser.parse_args()
    path = Path(args.config)
    # Serialize membership changes, and also detect edits by other programs.
    with open(str(path) + '.nodes.lock', 'a') as lock:
        os.chmod(lock.name, 0o600)
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        original = path.read_bytes()
        conf = json.loads(original)
        show_nodes(conf)
        if args.action == 'list':
            return 0
        agent = load_agent() if args.action == 'add' else None
        if args.action == 'add' and not args.ids:
            if conf.get('panel') and conf.get('key'):
                try:
                    result = agent.Panel(conf['panel'], conf['key'], 15).patch_call('node.list', {})
                    print('Available panel servers (create new server records in the panel first):')
                    for server in result.get('servers', []):
                        print('  %s  %s' % (server.get('id'), server.get('name', '')))
                except agent.PanelError:
                    print('Panel list unavailable; enter IDs manually (each addition is checked).')
        values = args.ids or [input('Node IDs to %s (Enter to cancel): ' % args.action)]
        if not any(v.strip() for v in values):
            print('Cancelled; nothing changed.')
            return 0
        ids = parse_ids(values)
        candidate = change_nodes(conf, args.action, ids)
        added_ports = []
        if candidate == conf:
            print('These nodes are already configured; nothing changed.')
            return 0
        if args.action == 'add':
            added = set(ids) - {node_id(n) for n in conf.get('nodes', [])}
            if not conf.get('panel') or not conf.get('key'):
                raise ValueError('Adding by ID requires a default panel/key. Use Install / reconfigure for a different panel.')
            try:
                added_ports = validate_additions(agent, path, candidate, added)
            except (agent.PanelError, agent.NodeError) as error:
                raise ValueError(str(error)) from error
        print('After change: ' + ', '.join(str(node_id(n)) for n in candidate['nodes']))
        print('Changing node membership can reconnect current users.')
        if input('Apply this change? [y/N]: ').strip().lower() not in ('y', 'yes', 'بله'):
            print('Cancelled; nothing changed.')
            return 0
        def restart():
            subprocess.run(['systemctl', 'restart', 'digitsell-xray-agent'], check=True)
        save_config(path, original, candidate, restart)
        open_firewall(added_ports)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, OSError, EOFError, subprocess.CalledProcessError) as error:
        sys.exit('error: %s' % error)
