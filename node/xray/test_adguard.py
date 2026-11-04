import importlib.util
from pathlib import Path
import types
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('adguard_agent_test', Path(__file__).with_name('xray-agent.py'))
agent = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agent)


class AdguardTests(unittest.TestCase):
    def instance(self):
        a = agent.Agent.__new__(agent.Agent)
        a.conf = {}
        a.specs = {i: {'tag': 'n%d' % i, 'rules': [], 'relay': False} for i in (1, 2)}
        a.adguard_wants = {1: True, 2: False}
        a.adguard = agent.AdguardWorker()
        a.adguard_applied = set()
        return a

    def test_per_server_readiness_and_disable(self):
        a = self.instance()
        self.assertEqual(a.adguard_rules(a.specs), [])
        a.adguard.ready = True
        rule, = a.adguard_rules(a.specs)
        self.assertEqual(rule['inboundTag'], ['n1'])
        self.assertEqual(rule['port'], '53')
        self.assertEqual(rule['network'], 'tcp,udp')
        a.adguard_wants[1] = False
        self.assertEqual(a.adguard_rules(a.specs), [])

    def test_security_blocks_precede_dns(self):
        a = self.instance()
        a.adguard.ready = True
        a.specs[1]['rules'] = ['forbidden']
        rules = a.static_rules()
        self.assertEqual(rules[0]['outboundTag'], 'block')
        self.assertEqual(rules[1]['outboundTag'], 'adguard-dns')

    def test_off_never_installs_and_failure_is_reported(self):
        w = agent.AdguardWorker()
        with patch.object(w, 'ensure') as ensure:
            w.step()
            ensure.assert_not_called()
        w.wanted = True
        with patch.object(w, 'ensure', side_effect=RuntimeError('download failed')):
            w.step()
        self.assertFalse(w.ready)
        self.assertEqual(w.report['state'], 'failed')

    def test_health_recovery_and_shared_service_retained(self):
        w = agent.AdguardWorker()
        w.wanted = True
        with patch.object(w, 'ensure'), patch.object(w, 'probe'):
            w.step()
        self.assertTrue(w.ready)
        with patch.object(w, 'ensure') as ensure, patch.object(w, 'probe'):
            w.step()
            ensure.assert_not_called()
        w.wanted = False
        with patch.object(w, 'command') as command:
            w.step()
            command.assert_not_called()
        self.assertFalse(w.ready)

    def test_active_requires_applied_running_xray(self):
        a = self.instance()
        a.adguard.report = {'state': 'ready', 'error': ''}
        a.xray_active = lambda: True
        self.assertEqual(a.adguard_report(1)['state'], 'ready')
        a.adguard_applied.add(1)
        self.assertEqual(a.adguard_report(1)['state'], 'active')
        a.xray_active = lambda: False
        self.assertEqual(a.adguard_report(1)['state'], 'ready')
        self.assertEqual(a.adguard_report(2)['state'], 'off')


if __name__ == '__main__':
    unittest.main()
