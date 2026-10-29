"""Online reporting must never renew a cached observation after an API failure."""
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import Mock

spec = importlib.util.spec_from_file_location('online_agent_test', Path(__file__).with_name('xray-agent.py'))
agent_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agent_module)


class OnlineReportingTests(unittest.TestCase):
    def make_agent(self):
        agent = agent_module.Agent.__new__(agent_module.Agent)
        agent.conf = {'ip_limit': True}
        agent.panels = {59: Mock()}
        agent.state = {'status': {}}
        agent.limits = {}
        agent.last_online = {}
        agent.online_snapshot = {59: False}
        agent.ipstate = {}
        agent.blocked = {}
        agent.online = {}
        agent.push_rules = Mock()
        return agent

    def test_failed_poll_does_not_report_old_online_users_again(self):
        agent = self.make_agent()
        email = 'n59|user_7@xmplus.user|7'
        agent.read_online = Mock(return_value={email: {'198.51.100.7': 1}})
        agent.report_online()
        agent.panels[59].post.assert_called_once_with('/api/onlineip/59',
            [{'subscription_id': 7, 'ip': '198.51.100.7'}])
        agent.read_online.side_effect = agent_module.XrayError('synthetic API outage')
        for _ in range(3):
            agent.report_online()
        self.assertEqual(agent.panels[59].post.call_count, 1,
                         'An API outage must not refresh the old users in the panel')

    def test_successful_empty_poll_expires_local_presence_and_recovers(self):
        agent = self.make_agent()
        email = 'n59|user_7@xmplus.user|7'
        agent.read_online = Mock(side_effect=[{email: {'198.51.100.7': 1}}, {},
                                             {email: {'198.51.100.8': 2}}])
        agent.report_online()
        agent.report_online()
        self.assertEqual(agent.online, {})
        self.assertEqual(agent.last_online[59], {})
        self.assertEqual(agent.state['status']['59']['online_accounts'], 0)
        agent.report_online()
        self.assertEqual(agent.last_online[59], {7: 1})
        self.assertEqual(agent.panels[59].post.call_args.args[1],
                         [{'subscription_id': 7, 'ip': '198.51.100.8'}])

    def test_old_connection_start_time_is_not_a_disconnect(self):
        agent = self.make_agent()
        email = 'n59|user_7@xmplus.user|7'
        agent.api = Mock(return_value=json.dumps({'users': [
            {'email': email, 'ips': [{'ip': '198.51.100.7', 'lastSeen': '1'}]}]}))
        agent.report_online()
        self.assertEqual(agent.online, {email: ['198.51.100.7']})

    def test_empty_snapshot_clears_node_and_never_uses_legacy_api(self):
        agent = self.make_agent()
        agent.online_snapshot = {}
        agent.read_online = Mock(return_value={})
        agent.report_online()
        agent.panels[59].patch_call.assert_called_once_with('node.online', {'node_id': 59, 'data': []})
        agent.panels[59].post.assert_not_called()
        self.assertEqual(agent.last_online[59], {})

    def test_unknown_endpoint_falls_back_but_outage_does_not(self):
        agent = self.make_agent()
        agent.online_snapshot = {}
        email = 'n59|user_7@xmplus.user|7'
        agent.read_online = Mock(return_value={email: {'198.51.100.7': 1}})
        agent.panels[59].patch_call.side_effect = agent_module.PanelError('node.online: unknown node action')
        agent.report_online()
        self.assertFalse(agent.online_snapshot[59])
        agent.panels[59].post.assert_called_once()
        agent.online_snapshot[59] = True
        agent.panels[59].patch_call.side_effect = agent_module.PanelError('network unavailable')
        agent.report_online()
        self.assertEqual(agent.panels[59].post.call_count, 1)


if __name__ == '__main__':
    unittest.main()
