"""PTY tests exercise the same terminal handling as bash <(curl ...)."""
import fcntl
import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import termios
import time
import unittest

HERE = Path(__file__).parent.resolve()


def terminal_run(args, answers, downloads=None):
    master, slave = pty.openpty()
    def child():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)
    with tempfile.TemporaryDirectory() as folder:
        # No test can start/stop services, install packages or download software.
        for command in ('systemctl', 'apt-get', 'curl', 'journalctl'):
            file = Path(folder) / command
            file.write_text('#!/bin/sh\necho UNEXPECTED_MUTATION >&2\nexit 99\n')
            file.chmod(0o755)
        if downloads:
            file = Path(folder) / 'curl'
            file.write_text('''#!/bin/bash
while [ $# -gt 0 ]; do
    case "$1" in
        -o) out="$2"; shift 2 ;;
        http*) url="$1"; shift ;;
        *) shift ;;
    esac
done
case "${url##*/}" in
    digitsell-xray|node-manager.py) cp "$DXRAY_TEST_DOWNLOADS/${url##*/}" "$out" ;;
    *) echo UNEXPECTED_MUTATION >&2; exit 99 ;;
esac
''')
            file.chmod(0o755)
        file = Path(folder) / 'id'
        file.write_text('#!/bin/sh\necho 0\n')
        file.chmod(0o755)
        env = dict(os.environ, PATH=folder + ':' + os.environ['PATH'])
        if downloads:
            env['DXRAY_TEST_DOWNLOADS'] = str(downloads)
        process = subprocess.Popen(args, stdin=slave, stdout=slave, stderr=slave,
                                   preexec_fn=child, env=env)
        os.close(slave)
        output = b''
        deadline = time.monotonic() + 10
        sent = False
        try:
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        break
                    output += chunk
                    if b'Choice:' in output and not sent:
                        os.write(master, answers.encode())
                        sent = True
                if process.poll() is not None:
                    break
            if process.poll() is None:
                process.kill()
                raise AssertionError('Menu timed out: ' + output.decode(errors='replace'))
            return process.wait(), output.decode(errors='replace')
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)


class MenuTests(unittest.TestCase):
    def test_cli_default_menu_and_cancel_destructive_actions(self):
        code, out = terminal_run(['bash', str(HERE / 'digitsell-xray')], '12\nn\n16\n\n0\n')
        self.assertEqual(code, 0, out)
        self.assertIn('Add node(s)', out)
        self.assertIn('Stop all configured nodes?', out)
        self.assertIn('Uninstall mode', out)
        self.assertNotIn('UNEXPECTED_MUTATION', out)

    def test_installer_process_substitution_opens_menu_without_installing(self):
        # /dev/fd script path: bootstrap fetches manager files, not the installer.
        code, out = terminal_run(['bash', '-c', 'bash <(cat "$1")',
                                  'test', str(HERE / 'install.sh')], '0\n', HERE)
        self.assertEqual(code, 0, out)
        self.assertIn('Add node(s)', out)
        self.assertNotIn('UNEXPECTED_MUTATION', out)

    def test_noninteractive_menu_fails_without_installing(self):
        result = subprocess.run(['bash', str(HERE / 'digitsell-xray'), 'menu'],
                                stdin=subprocess.DEVNULL, capture_output=True, text=True,
                                start_new_session=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('terminal', result.stderr)


if __name__ == '__main__':
    unittest.main()
