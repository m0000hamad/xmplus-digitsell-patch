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


def source_nodes(conf, explicit=None):
    """Read membership/certificate references from the user's local XMPlus YAML."""
    paths = [Path(explicit)] if explicit else [Path(p) for p in [
        conf.get('source_config', ''), '/etc/XMPlus/config.yml', '/etc/XMPlus/config.yaml',
        '/usr/local/XMPlus/config.yml', '/usr/local/XMPlus/config.yaml',
        '/root/config.yml', '/root/config.yaml', str(Path.cwd() / 'config.yml'),
        str(Path.cwd() / 'config.yaml')] if p]
    source = next((p for p in paths if p.is_file()), None)
    if source is None:
        if explicit:
            raise ValueError('Configuration file not found: %s' % explicit)
        return None, []
    try:
        import yaml
    except ImportError as error:
        raise ValueError('Reading %s requires python3-yaml; run dxray update first.' % source) from error
    try:
        raw = yaml.safe_load(source.read_text()) or {}
    except yaml.YAMLError as error:
        raise ValueError('Invalid YAML configuration: %s' % source) from error
    if not isinstance(raw, dict) or not isinstance(raw.get('Nodes'), list):
        raise ValueError('Configuration has no Nodes list: %s' % source)
    nodes = []
    seen = set()
    for item in raw['Nodes']:
        api = (item or {}).get('ApiConfig') or {}
        nid = int(api.get('NodeID') or 0)
        if nid <= 0 or nid in seen:
            raise ValueError('Invalid or duplicate NodeID in %s' % source)
        seen.add(nid)
        node = {'id': nid}
        for key, name in [('ApiHost', 'panel'), ('ApiKey', 'key')]:
            if api.get(key):
                node[name] = str(api[key]).rstrip('/') if name == 'panel' else str(api[key])
        ctl = (item or {}).get('ControllerConfig') or {}
        cert = ctl.get('CertConfig') or {}
        for key, name in [('CertFile', 'cert_file'), ('KeyFile', 'key_file')]:
            if cert.get(key):
                file = Path(str(cert[key])).expanduser()
                node[name] = str(file if file.is_absolute() else source.resolve().parent / file)
        if ctl.get('EnableFallback'):
            fallbacks = []
            for fb in ctl.get('FallBackConfigs') or []:
                if fb.get('Dest') in (None, ''):
                    continue
                entry = {'dest': fb['Dest']}
                for src, dst in [('SNI', 'name'), ('Alpn', 'alpn'), ('Path', 'path'), ('ProxyProtocolVer', 'xver')]:
                    if fb.get(src) not in (None, '', 0):
                        entry[dst] = fb[src]
                fallbacks.append(entry)
            if fallbacks:
                node['fallbacks'] = fallbacks
        nodes.append(node)
    return source.resolve(), nodes


def add_selection(conf, imported, values):
    defaults = list(dict.fromkeys([node_id(n) for n in conf.get('nodes', [])] +
                                 [node_id(n) for n in imported]))
    ids = parse_ids(values) if any(v.strip() for v in values) else defaults
    if not ids:
        raise ValueError('No nodes selected.')
    candidate = change_nodes(conf, 'add', ids)
    old = {node_id(n) for n in conf.get('nodes', [])}
    overrides = {node_id(n): n for n in imported}
    candidate['nodes'] = [copy.deepcopy(overrides.get(node_id(n), n))
                          if node_id(n) not in old else n for n in candidate['nodes']]
    return ids, candidate


def show_choices(conf, imported, servers):
    installed = {node_id(n) for n in conf.get('nodes', [])}
    configured = {node_id(n) for n in imported}
    rows = {int(s['id']): str(s.get('name', '')) for s in servers}
    print('Nodes: [installed] already here; [config NEW] selected from YAML; [available] other panel nodes')
    for nid in sorted(set(rows) | installed | configured):
        flags = []
        if nid in installed:
            flags.append('installed')
        if nid in configured:
            flags.append('config' if nid in installed else 'config NEW')
        print('  %s  %s  [%s]' % (nid, rows.get(nid, ''), ', '.join(flags) or 'available'))
    return list(dict.fromkeys([node_id(n) for n in conf.get('nodes', [])] +
                              [node_id(n) for n in imported]))


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
                entry = conf['nodes'][index]
                entry = dict(entry) if isinstance(entry, dict) else {'id': entry}
                entry.update(cert_file=crt, key_file=key)
                conf['nodes'][index] = entry
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
    parser.add_argument('--from', dest='source', help='XMPlus YAML to read node defaults/certificates from')
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
        imported = []
        source = None
        if args.action == 'add':
            source, imported = source_nodes(conf, args.source)
            if source:
                print('Reading node defaults and certificate paths from: %s' % source)
        if args.action == 'add' and not args.ids:
            servers = []
            if conf.get('panel') and conf.get('key'):
                try:
                    result = agent.Panel(conf['panel'], conf['key'], 15).patch_call('node.list', {})
                    servers = result.get('servers', [])
                except agent.PanelError:
                    print('Panel list unavailable; enter IDs manually (each addition is checked).')
            defaults = show_choices(conf, imported, servers)
            values = [input('Node IDs [%s] (Enter = use config; q = cancel): ' % ','.join(map(str, defaults)))]
        else:
            values = args.ids or [input('Node IDs to %s (Enter to cancel): ' % args.action)]
        if values == ['q'] or (args.action != 'add' and not any(v.strip() for v in values)):
            print('Cancelled; nothing changed.')
            return 0
        if args.action == 'add':
            ids, candidate = add_selection(conf, imported, values)
        else:
            ids = parse_ids(values)
            candidate = change_nodes(conf, args.action, ids)
        added_ports = []
        if candidate == conf:
            print('These nodes are already configured; nothing changed.')
            return 0
        if args.action == 'add':
            added = set(ids) - {node_id(n) for n in conf.get('nodes', [])}
            try:
                added_ports = validate_additions(agent, path, candidate, added)
            except (agent.PanelError, agent.NodeError) as error:
                raise ValueError(str(error)) from error
            if source:
                candidate['source_config'] = str(source)
        print('After change: ' + ', '.join(str(node_id(n)) for n in candidate['nodes']))
        print('Changing node membership can reconnect current users.')
        answer = input('Apply this change? %s: ' % ('[Y/n]' if args.action == 'add' else '[y/N]')).strip().lower()
        if answer not in ('y', 'yes', 'بله') and not (args.action == 'add' and not answer):
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
