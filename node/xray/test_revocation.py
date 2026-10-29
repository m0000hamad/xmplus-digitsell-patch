"""Credential resets must revoke already authenticated sessions, not just login."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('revocation_agent', Path(__file__).with_name('xray-agent.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class CredentialRevocationTests(unittest.TestCase):
    def test_agent_restart_retains_full_quota_users_on_this_node(self):
        agent = module.Agent.__new__(module.Agent)
        agent.panels = {59: Mock()}
        agent.read_online = Mock(return_value={'n59|fixture|7': {'198.51.100.1': 1, '198.51.100.2': 1}})
        agent.last_online = {}
        spec = {'id': 59, 'type': 'vless', 'flow': ''}
        subs = [{'id': 7, 'email': 'fixture', 'uuid': 'fixture', 'iplimit': 2, 'ipcount': 2}]
        self.assertEqual(module.select_users(spec, subs, {})[0], {})
        agent.restore_online_capacity()
        clients, limits = module.select_users(spec, subs, agent.last_online[59])
        self.assertIn('n59|fixture|7', clients)
        self.assertEqual(limits['n59|fixture|7'], 2)

    def test_restore_does_not_credit_other_nodes_or_duplicate_ip_entries(self):
        agent = module.Agent.__new__(module.Agent)
        agent.panels = {59: Mock(), 73: Mock()}
        agent.read_online = Mock(return_value={'n59|fixture|7': {'198.51.100.1': 1},
                                              'n59|alias|7': {'198.51.100.1': 1},
                                              'n58|fixture|7': {'198.51.100.2': 1}})
        agent.restore_online_capacity()
        self.assertEqual(agent.last_online, {59: {7: 1}, 73: {}})

    def agent(self, clients):
        agent = module.Agent.__new__(module.Agent)
        agent.specs = {node: {'relay': None} for node in clients}
        agent.clients = clients
        agent.subs = {}
        agent.last_restart = 100
        for name in ('remove_users', 'add_users', 'write_config', 'push_rules',
                     'collect_traffic', 'xray_restart', 'build_config'):
            setattr(agent, name, Mock())
        return agent

    def test_uuid_reset_closes_old_sessions_once_even_during_error_backoff(self):
        agent = self.agent({59: {'user': {'id': 'old'}}, 73: {'user2': {'id': 'old2'}}})
        events = []
        agent.collect_traffic.side_effect = lambda: events.append('traffic')
        agent.xray_restart.side_effect = lambda: events.append('restart')
        with patch.object(module.time, 'time', return_value=101):
            agent.apply_users({59: {'user': {'id': 'new'}}, 73: {'user2': {'id': 'new2'}}}, {})
        self.assertEqual(events, ['traffic', 'restart'])
        agent.write_config.assert_called_once()
        self.assertEqual(agent.clients[59]['user']['id'], 'new')

    def test_password_reset_also_revokes(self):
        agent = self.agent({59: {'user': {'password': 'old'}}})
        agent.apply_users({59: {'user': {'password': 'new'}}}, {})
        agent.xray_restart.assert_called_once()

    def test_full_quota_cannot_hide_a_reset_from_revocation(self):
        agent = self.agent({59: {}})
        agent.subs = {59: {'user': {'uuid': 'old', 'ipcount': 2}}}
        agent.apply_users({59: {}}, {59: {'user': {'uuid': 'new', 'ipcount': 2}}})
        agent.write_config.assert_called_once()
        agent.xray_restart.assert_called_once()

    def test_regular_addition_limit_removal_and_nonsecret_change_do_not_restart(self):
        for before, after in [({}, {'user': {'id': 'same'}}),
                              ({'user': {'id': 'same'}}, {}),
                              ({'user': {'id': 'same', 'flow': ''}}, {'user': {'id': 'same', 'flow': 'new'}}),
                              ({'user': {'id': 'same'}}, {'user': {'id': 'same'}})]:
            agent = self.agent({59: before})
            agent.apply_users({59: after}, {})
            agent.xray_restart.assert_not_called()


if __name__ == '__main__':
    unittest.main()
