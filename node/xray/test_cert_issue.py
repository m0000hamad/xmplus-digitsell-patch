import importlib.util
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

loader = importlib.util.spec_from_file_location('cert_agent', Path(__file__).with_name('xray-agent.py'))
module = importlib.util.module_from_spec(loader)
loader.loader.exec_module(module)

class CertificateIssueTests(unittest.TestCase):
    def test_missing_file_can_issue_without_changing_panel_mode(self):
        agent = module.Agent.__new__(module.Agent)
        agent.node_conf = {59: {'cert_issue_mode': 'http'}}
        agent.conf = {'cert': {}}
        agent.cert_failed = {}
        agent.lego_paths = Mock(return_value=('/missing/cert', '/missing/key'))
        agent.lego_run = Mock(return_value=True)
        spec = {'id': 59, 'security': 'tls', 'certmode': 'file', 'cert_domain': 'example.test'}
        self.assertEqual(agent.cert_for(spec), ('/missing/cert', '/missing/key'))
        agent.lego_run.assert_called_once_with('example.test', 'http', spec)
        self.assertEqual(spec['certmode'], 'file')

    def test_issued_file_override_is_renewed(self):
        agent = module.Agent.__new__(module.Agent)
        spec = {'id': 59, 'security': 'tls', 'certmode': 'file', 'cert_domain': 'example.test'}
        agent.specs = {59: spec}
        agent.node_conf = {59: {'cert_issue_mode': 'http'}}
        agent.conf = {'cert': {}}
        agent.lego_paths = Mock(return_value=('/cert', '/key'))
        agent.lego_run = Mock()
        with patch.object(module, 'cert_days_left', return_value=5):
            agent.renew_certs()
        agent.lego_run.assert_called_once_with('example.test', 'http', spec)

class ImportCertificatesTests(unittest.TestCase):
    def test_missing_second_node_certificate_does_not_abort_import(self):
        import tempfile
        import os
        script = Path(__file__).with_name('install.sh').read_text()
        source = script.split('def from_xmplus(file):', 1)[1].split('\nif os.environ.get("FROM"):', 1)[0]
        namespace = {'os': os, 'sys': __import__('sys'), 'json': __import__('json')}
        exec('def from_xmplus(file):' + source, namespace)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'existing.crt').write_text('fixture')
            config = root / 'config.yml'
            config.write_text("Nodes:\n  - ApiConfig: {NodeID: 59, ApiHost: 'https://example.test', ApiKey: fixture}\n    ControllerConfig:\n      CertConfig: {CertFile: existing.crt}\n  - ApiConfig: {NodeID: 73, ApiHost: 'https://example.test', ApiKey: fixture}\n    ControllerConfig:\n      CertConfig: {CertFile: missing.crt}\n")
            result = namespace['from_xmplus'](str(config))
            self.assertEqual(result['nodes'][0]['cert_file'], str(root / 'existing.crt'))
            self.assertEqual(result['nodes'][1], 73)
