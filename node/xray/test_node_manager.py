"""Run on Linux: python3 -m unittest discover -s node/xray -p 'test_*.py'."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('node_manager', Path(__file__).with_name('node-manager.py'))
manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(manager)


class MembershipTests(unittest.TestCase):
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
