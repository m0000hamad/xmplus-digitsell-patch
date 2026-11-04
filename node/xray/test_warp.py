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
        self.assertEqual(rules[0]['network'], 'udp')
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

    def test_off_never_installs(self):
        w = agent.WarpWorker()
        with patch.object(w, 'ensure') as ensure:
            w.step()
            ensure.assert_not_called()

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
