"""Distinct inbounds must share credentials, limits and quota, without mixing usage."""
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import Mock

loader = importlib.util.spec_from_file_location('profile_agent_test', Path(__file__).with_name('xray-agent.py'))
m = importlib.util.module_from_spec(loader)
loader.loader.exec_module(m)


class ProfileTests(unittest.TestCase):
    def spec(self):
        return {'id': 25, 'tag': 'n25', 'port': '443', 'profile_billing': {
            'enabled': True, 'ports': {'1': 443, '2': 8443}, 'revision': 'a' * 64}}

    def test_two_ports_keep_same_credential_and_separate_counter_names(self):
        variants = m.profile_specs(self.spec())
        self.assertEqual([v['port'] for v in variants], ['443', '8443'])
        client = {'id': 'fixed-uuid', 'email': 'n25|fixture|7'}
        emails = []
        for spec in variants:
            child = m.profile_clients([client], spec)[0]
            self.assertEqual(child['id'], client['id'])
            self.assertEqual(m.email_node_uid(child['email']), (25, 7))
            self.assertEqual(m.profile_identity(child['email'])[0], client['email'])
            emails.append(child['email'])
        self.assertNotEqual(*emails)

    def test_block_exit_and_relay_rules_cover_both_ports(self):
        rules = [{'inboundTag': ['n25'], 'outboundTag': 'block'},
                 {'user': ['n25|fixture|7'], 'outboundTag': 'shared-relay'}]
        result = m.profile_rules(rules, {25: self.spec()})
        self.assertEqual(result[0]['inboundTag'], ['n25p1', 'n25p2'])
        self.assertEqual(len(result[1]['user']), 2)
        self.assertEqual(result[1]['outboundTag'], 'shared-relay')
        self.assertEqual(rules[0]['inboundTag'], ['n25'])

    def test_counter_retry_keeps_frozen_batch_and_never_uses_legacy_endpoint(self):
        agent = m.Agent.__new__(m.Agent)
        agent.panels = {25: Mock()}
        agent.state = {'pending': {}, 'status': {}}
        agent.save_state = Mock(return_value=True)
        variants = m.profile_specs(self.spec())
        stats = [{'name': 'user>>>%s>>>traffic>>>downlink' % m.profile_email('n25|fixture|7', spec),
                  'value': 100} for spec in variants]
        agent.api = Mock(side_effect=[json.dumps({'stat': stats}), '{}'])
        agent.panels[25].patch_call.side_effect = [m.PanelError('lost response'), {'accepted': True}]
        agent.report_traffic()
        frozen = dict(agent.state['profile_batches']['25'])
        agent.report_traffic()
        self.assertEqual(agent.panels[25].patch_call.call_args_list[0].args[1], frozen)
        self.assertEqual(agent.panels[25].patch_call.call_args_list[1].args[1], frozen)
        self.assertEqual([r['profile'] for r in frozen['data']], [1, 2])
        self.assertFalse(agent.state['profile_batches'])
        agent.panels[25].post.assert_not_called()

    def test_same_device_across_two_ports_uses_one_ip_slot(self):
        agent = m.Agent.__new__(m.Agent)
        variants = m.profile_specs(self.spec())
        agent.read_online = Mock(return_value={m.profile_email('n25|fixture|7', spec): {'198.51.100.1': 1} for spec in variants})
        agent.conf = {'ip_limit': True}; agent.ipstate = {}; agent.limits = {'n25|fixture|7': 1}
        agent.blocked = {}; agent.push_rules = Mock()
        self.assertTrue(agent.enforce_limits())
        self.assertEqual(agent.online, {'n25|fixture|7': ['198.51.100.1']})
        self.assertEqual(agent.blocked, {})

    def test_legacy_node_remains_single_inbound(self):
        spec = {'id': 25, 'tag': 'n25', 'port': '443'}
        self.assertEqual(m.profile_specs(spec), [spec])

    def test_full_generated_config_has_two_inbounds_with_shared_credentials(self):
        raw = {'server': {'type': 'Trojan', 'listeningport': '443', 'networkSettings': {'transport': 'tcp'}, 'security': 'none'},
               'profile_billing': self.spec()['profile_billing']}
        spec = m.parse_node(25, raw)
        agent = m.Agent.__new__(m.Agent)
        agent.conf = dict(m.DEFAULTS)
        agent.specs = {25: spec}; agent.node_conf = {25: {}}; agent.certs = {25: None}; agent.subs = {}
        agent.clients = {25: {'n25|fixture|7': {'password': 'fixed-password', 'email': 'n25|fixture|7'}}}
        agent.exit_outbound = Mock(return_value=None)
        config = agent.build_config()
        self.assertEqual([str(i['port']) for i in config['inbounds']], ['443', '8443'])
        self.assertEqual([i['tag'] for i in config['inbounds']], ['n25p1', 'n25p2'])
        self.assertEqual([i['settings']['clients'][0]['password'] for i in config['inbounds']], ['fixed-password'] * 2)

    def test_unpersisted_batch_is_never_sent_for_billing(self):
        agent = m.Agent.__new__(m.Agent)
        agent.collect_traffic = Mock(); agent.save_state = Mock(return_value=False)
        agent.panels = {25: Mock()}
        key = '7:1:' + 'a' * 64
        agent.state = {'pending': {'25': {key: [100, 200]}}}
        agent.report_traffic()
        agent.panels[25].patch_call.assert_not_called()


if __name__ == '__main__':
    unittest.main()
