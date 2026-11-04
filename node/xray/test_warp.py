import importlib.util
from pathlib import Path
import types
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('warp_agent_test', Path(__file__).with_name('xray-agent.py'))
agent = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agent)


class WarpTests(unittest.TestCase):
    def instance(self):
        a = agent.Agent.__new__(agent.Agent)
        a.conf = {'nodes': [{'id': 1}, {'id': 2}]}
        a.node_conf = {1: {}, 2: {}}
        a.exit_current = {}
        a.exit_wants = {}
        a.warp_wants = {1: True, 2: False}
        a.warp = agent.WarpWorker()
        return a

    def test_selection_readiness_failure_and_disable(self):
        a = self.instance()
        self.assertEqual(a.compute_exits()[1][0], {})
        a.warp.ready = True
        exits = a.compute_exits()
        self.assertEqual(exits[1], ({'proxy': agent.WARP_PROXY}, 'warp'))
        self.assertEqual(exits[2][0], {})
        a.exit_current = exits
        a.warp.ready = False
        self.assertEqual(a.compute_exits()[1], exits[1])
        a.warp_wants[1] = False
        self.assertEqual(a.compute_exits()[1][0], {})

    def test_disable_restores_explicit_tor_selection(self):
        a = self.instance()
        a.exit_current[1] = ({'proxy': agent.WARP_PROXY}, 'warp')
        a.warp_wants[1] = False
        a.exit_wants[1] = 'de'
        a.torexit = types.SimpleNamespace(usable=lambda cc: 'de1')
        self.assertEqual(a.compute_exits()[1][0], {'tor': 'de1'})

    def test_udp_is_blocked_only_for_warp_node(self):
        a = self.instance()
        a.exit_current[1] = ({'proxy': agent.WARP_PROXY}, 'warp')
        specs = {i: {'tag': 'n%d' % i, 'send_through': ''} for i in (1, 2)}
        rules = a.exit_rules(specs, {'exit-n1'})
        self.assertEqual(rules[0]['ip'], ['::/0'])
        self.assertEqual(rules[1]['network'], 'udp')
        self.assertEqual(rules[0]['outboundTag'], 'block')
        self.assertEqual(rules[0]['inboundTag'], ['n1'])

    def test_probe_rejects_nonwarp_and_retries(self):
        w = agent.WarpWorker()
        w.wanted = True
        with patch.object(w, 'ensure'), patch.object(w, 'run_command', return_value=types.SimpleNamespace(stdout='warp=off\nip=192.0.2.1')):
            w.step()
        self.assertFalse(w.ready)
        self.assertEqual(w.report['state'], 'failed')
        with patch.object(w, 'ensure'), patch.object(w, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=192.0.2.1')):
            w.step()
        self.assertTrue(w.ready)

    def test_ipv4_target_strategy_only_on_warp(self):
        a = self.instance()
        a.exit_errors = {}
        a.exit_current[1] = ({'proxy': agent.WARP_PROXY}, 'warp')
        a.exit_current[2] = ({'proxy': 'socks5://127.0.0.1:1080'}, 'agent.json')
        self.assertEqual(a.exit_outbound({'id': 1, 'tag': 'n1'})['targetStrategy'], 'ForceIPv4')
        self.assertNotIn('targetStrategy', a.exit_outbound({'id': 2, 'tag': 'n2'}))

    def test_ipv4_probe_uses_local_resolution_and_rejects_ipv6(self):
        w = agent.WarpWorker()
        with patch.object(w, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=192.0.2.1')) as command:
            self.assertEqual(w.probe(), '192.0.2.1')
            args = command.call_args[0][0]
            self.assertIn('-4', args)
            self.assertIn('--socks5', args)
            self.assertNotIn('--socks5-hostname', args)
        with patch.object(w, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=2001:db8::1')):
            with self.assertRaisesRegex(RuntimeError, 'IPv4'):
                w.probe()

    def test_off_never_installs(self):
        w = agent.WarpWorker()
        with patch.object(w, 'ensure') as ensure:
            w.step()
            ensure.assert_not_called()

    def test_excluded_exit_fails_closed_until_allowed_probe(self):
        a = self.instance()
        a.warp = agent.WarpWorker(['192.0.2.81'])
        a.exit_errors = {}
        a.exit_current = a.compute_exits()
        self.assertEqual(a.exit_outbound({'id': 1, 'tag': 'n1'})['protocol'], 'blackhole')
        self.assertEqual(a.exit_current[2][0], {})
        with patch.object(a.warp, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=192.0.2.81')):
            with self.assertRaisesRegex(RuntimeError, 'blocked'):
                a.warp.probe()
        self.assertTrue(a.warp.blocked)
        with patch.object(a.warp, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=192.0.2.82')):
            a.warp.probe()
        a.warp.ready = True
        a.exit_current = a.compute_exits()
        self.assertEqual(a.exit_outbound({'id': 1, 'tag': 'n1'})['protocol'], 'socks')
        # A later denied exit changes the config fingerprint back to blackhole.
        with patch.object(a.warp, 'run_command', return_value=types.SimpleNamespace(stdout='warp=on\nip=192.0.2.81')):
            a.warp.wanted = True
            a.warp.step()
        self.assertTrue(a.warp.blocked)
        self.assertFalse(a.warp.ready)
        a.exit_current = a.compute_exits()
        self.assertEqual(a.exit_outbound({'id': 1, 'tag': 'n1'})['protocol'], 'blackhole')

    def test_exclusion_survives_health_failure_and_disable_restores_direct(self):
        a = self.instance()
        a.warp = agent.WarpWorker(['192.0.2.81'])
        a.warp.wanted = True
        with patch.object(a.warp, 'ensure', side_effect=RuntimeError('offline')):
            a.warp.step()
        self.assertTrue(a.warp.blocked)
        a.exit_current = a.compute_exits()
        a.warp_wants[1] = False
        self.assertEqual(a.compute_exits()[1][0], {})

    def test_exclusion_configuration_validation(self):
        for value in ['192.0.2.81', ['not-an-ip'], ['2001:db8::1']]:
            with self.assertRaises(ValueError):
                agent.WarpWorker(value)

    def test_unmanaged_installation_is_untouched(self):
        w = agent.WarpWorker()
        with patch.object(agent._warp_module.os.path, 'exists', return_value=False), patch.object(agent._warp_module.shutil, 'which', return_value='/usr/bin/warp-cli'):
            with self.assertRaisesRegex(RuntimeError, 'unmanaged'):
                w.ensure()

    def test_proxy_mode_precedes_connect_and_registration_is_reused(self):
        w = agent.WarpWorker()
        calls = []
        def command(args, **kwargs):
            calls.append(args)
            return types.SimpleNamespace(returncode=0, stdout='')
        with patch.object(agent._warp_module.os.path, 'exists', return_value=True), patch.object(agent._warp_module.shutil, 'which', return_value='/usr/bin/warp-cli'), patch.object(w, 'run_command', side_effect=command):
            w.ensure()
        mode = ['warp-cli', '--accept-tos', 'mode', 'proxy']
        connect = ['warp-cli', '--accept-tos', 'connect']
        self.assertLess(calls.index(mode), calls.index(connect))
        self.assertNotIn(['warp-cli', '--accept-tos', 'registration', 'new'], calls)

    def test_healthy_poll_does_not_reconfigure_service(self):
        w = agent.WarpWorker()
        w.wanted = w.ready = True
        with patch.object(w, 'ensure') as ensure, patch.object(w, 'probe', return_value='192.0.2.1'):
            w.step()
            ensure.assert_not_called()
        self.assertEqual(w.report['state'], 'ready')


if __name__ == '__main__':
    unittest.main()
