"""Run on Linux: python3 -m unittest discover -s node/xray -p 'test_*.py'."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import types
import sys
import contextlib
import io
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('node_manager', Path(__file__).with_name('node-manager.py'))
manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manager)


class MembershipTests(unittest.TestCase):
    def test_enter_adds_yaml_node_with_its_certificate_and_preserves_installed(self):
        spec = importlib.util.spec_from_file_location('agent_add_test', Path(__file__).with_name('xray-agent.py'))
        agent = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(agent)
        class Panel:
            def __init__(self, *args): pass
            def patch_call(self, *args):
                return {'servers': [{'id': n, 'name': 'S%s' % n} for n in (59, 73, 74, 75)]}
            def get_json(self, endpoint):
                nid = int(endpoint.rsplit('/', 1)[1])
                return {'server': {'type': 'vless', 'listeningport': str(20000 + nid),
                        'security': 'tls' if nid == 74 else 'none', 'certmode': 'file',
                        'securitySettings': {'serverName': 's6.example'},
                        'networkSettings': {'transport': 'ws'}}}, ''
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = root / 'config.yml'
            source.write_text('synthetic fixture')
            (root / 's6.crt').write_text('synthetic certificate')
            (root / 's6.key').write_text('synthetic key')
            fixture = {'Nodes': [{'ApiConfig': {'NodeID': n, 'ApiHost': 'https://panel.example', 'ApiKey': 'fixture'},
                                  'ControllerConfig': {'CertConfig': {'CertFile': 's6.crt', 'KeyFile': 's6.key'}}}
                                 for n in (59, 73, 74)]}
            path = root / 'agent.json'
            original = {'panel': 'https://panel.example', 'key': 'fixture',
                        'nodes': [{'id': 59, 'tor': 'us', 'cert_file': '/existing/s3.crt'}, 73]}
            path.write_text(json.dumps(original))
            yaml = types.SimpleNamespace(safe_load=lambda handle: fixture, YAMLError=ValueError)
            output = io.StringIO()
            with patch.dict(sys.modules, {'yaml': yaml}), patch.object(agent, 'Panel', Panel), \
                 patch.object(manager, 'load_agent', return_value=agent), \
                 patch.object(sys, 'argv', ['node-manager.py', '--config', str(path), '--from', str(source), 'add']), \
                 patch('builtins.input', side_effect=['', '']) as ask, \
                 patch.object(manager.subprocess, 'run') as restart, \
                 patch.object(manager, 'open_firewall') as firewall, contextlib.redirect_stdout(output):
                self.assertEqual(manager.main(), 0)
            result = json.loads(path.read_text())
            self.assertEqual(result['nodes'][:2], original['nodes'])
            self.assertEqual(result['nodes'][2], {'id': 74, 'panel': 'https://panel.example', 'key': 'fixture',
                                                'cert_file': str(root / 's6.crt'), 'key_file': str(root / 's6.key')})
            self.assertEqual(result['source_config'], str(source))
            self.assertEqual(ask.call_count, 2)
            self.assertIn('[59,73,74]', ask.call_args_list[0].args[0])
            self.assertIn('[config NEW]', output.getvalue())
            self.assertIn('[available]', output.getvalue())
            self.assertEqual(json.loads(path.with_name('agent.json.before-nodes').read_text()), original)
            restart.assert_called_once_with(['systemctl', 'restart', 'digitsell-xray-agent'], check=True)
            firewall.assert_called_once_with(['20074'])

    def test_enter_defaults_never_remove_existing_nodes_or_import_other_ids(self):
        conf = {'nodes': [{'id': 59, 'tor': 'us'}, 73]}
        imported = [{'id': 59, 'cert_file': '/new-cert'}, {'id': 74, 'cert_file': '/s6.crt', 'key_file': '/s6.key'}]
        ids, candidate = manager.add_selection(conf, imported, [''])
        self.assertEqual(ids, [59, 73, 74])
        self.assertEqual(candidate['nodes'], conf['nodes'] + [imported[1]])
        ids, candidate = manager.add_selection(conf, imported, ['75'])
        self.assertEqual(candidate['nodes'], conf['nodes'] + [75])
        self.assertEqual(manager.add_selection(conf, [], [''])[1], conf)

    def test_yaml_certificate_paths_resolve_next_to_config_and_missing_fails(self):
        source = Path(__file__).with_name('install.sh').read_text()
        code = source.split('def from_xmplus(file):', 1)[1].split('\nif os.environ.get("FROM"):', 1)[0]
        namespace = {'os': os, 'sys': sys, 'json': json}
        exec('def from_xmplus(file):' + code, namespace)
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'certs').mkdir()
            (root / 'certs' / 'server.crt').write_text('test-cert')
            (root / 'certs' / 'server.key').write_text('test-key')
            file = root / 'config.yml'
            file.write_text('fixture')
            fixture = {'Nodes': [{'ApiConfig': {'NodeID': 74, 'ApiHost': 'https://panel.example', 'ApiKey': 'test'},
                                  'ControllerConfig': {'CertConfig': {'CertFile': 'certs/server.crt',
                                                                     'KeyFile': 'certs/server.key'}}}]}
            with patch.dict(sys.modules, {'yaml': types.SimpleNamespace(safe_load=lambda handle: fixture)}):
                conf = namespace['from_xmplus'](str(file))
                self.assertEqual(conf['nodes'][0]['cert_file'], str(root / 'certs' / 'server.crt'))
                self.assertEqual(conf['nodes'][0]['key_file'], str(root / 'certs' / 'server.key'))
                (root / 'certs' / 'server.key').unlink()
                with self.assertRaisesRegex(SystemExit, 'KeyFile does not exist'):
                    namespace['from_xmplus'](str(file))

    def setUp(self):
        self.conf = {'panel': 'https://panel.example', 'key': 'test-key',
                     'nodes': [{'id': 58, 'tor': 'us', 'cert_file': '/tmp/cert',
                                'key_file': '/tmp/key', 'panel': 'https://other.example'}, 59],
                     'cert': {'env': {'TEST_TOKEN': 'unchanged'}}, 'ip_limit': True}

    def test_add_keeps_custom_settings_and_deduplicates(self):
        candidate = manager.change_nodes(self.conf, 'add', manager.parse_ids(['58,60', '60 61']))
        self.assertEqual(candidate['nodes'], self.conf['nodes'] + [60, 61])
        self.assertEqual(candidate['cert'], self.conf['cert'])
        self.assertEqual(self.conf['nodes'][1], 59)

    def test_remove_keeps_remaining_node_objects(self):
        candidate = manager.change_nodes(self.conf, 'remove', [59])
        self.assertEqual(candidate['nodes'], self.conf['nodes'][:1])

    def test_reject_invalid_unknown_and_last_node_removal(self):
        for values in (['-1'], ['0'], ['58,no'], ['58;reboot'], ['']):
            with self.assertRaises(ValueError):
                manager.parse_ids(values)
        for ids in ([60], [58, 59]):
            with self.assertRaises(ValueError):
                manager.change_nodes(self.conf, 'remove', ids)

    def test_save_backup_private_and_rollback(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'agent.json'
            original = json.dumps(self.conf).encode()
            path.write_bytes(original)
            candidate = manager.change_nodes(self.conf, 'add', [60])
            attempts = []
            def restart():
                attempts.append(1)
                if len(attempts) == 1:
                    raise RuntimeError('mock restart failure')
            with self.assertRaises(RuntimeError):
                manager.save_config(path, original, candidate, restart)
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual(path.with_name('agent.json.before-nodes').read_bytes(), original)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            manager.save_config(path, original, candidate, lambda: None)
            self.assertEqual(json.loads(path.read_bytes()), candidate)
            with self.assertRaises(ValueError):
                manager.save_config(path, original, self.conf, lambda: None)

    def test_conflicting_ports_rejected_before_saving(self):
        class Agent:
            @staticmethod
            def load_config(path):
                return {'nodes': [{'id': n, 'panel': 'test', 'key': 'test'} for n in (58, 60)]}
            class Panel:
                def __init__(self, *args): pass
                def get_json(self, *args): return {}, ''
            @staticmethod
            def parse_node(nid, raw): return {'port': '2096'}
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, 'share a listening port'):
                manager.validate_additions(Agent, Path(folder) / 'agent.json', self.conf, {60})

    def test_validate_addition_with_real_agent_parser_and_preserve_original(self):
        spec = importlib.util.spec_from_file_location('agent_test', Path(__file__).with_name('xray-agent.py'))
        agent = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(agent)
        class Panel:
            calls = []
            def __init__(self, base, key, timeout):
                self.base = base
            def get_json(self, path):
                self.calls.append((self.base, path))
                return {'server': {'type': 'vless', 'listeningport': '2096' if path.endswith('/58') else '8443',
                                   'security': 'none', 'networkSettings': {'transport': 'ws'}}}, ''
        conf = json.loads(json.dumps(self.conf))
        # Include a default key for the migrated per-node panel, as the agent does.
        candidate = manager.change_nodes(conf, 'add', [60])
        candidate['nodes'] = [candidate['nodes'][0], 60]
        with tempfile.TemporaryDirectory() as folder, patch.object(agent, 'Panel', Panel):
            ports = manager.validate_additions(agent, Path(folder) / 'agent.json', candidate, {60})
        self.assertEqual(ports, ['8443'])
        self.assertEqual(candidate['nodes'][0], self.conf['nodes'][0])
        self.assertEqual(Panel.calls, [('https://other.example', '/api/server/58'),
                                       ('https://panel.example', '/api/server/60')])


if __name__ == '__main__':
    unittest.main()
