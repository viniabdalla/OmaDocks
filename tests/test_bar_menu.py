"""Exercise real settings and context-menu components without mapping windows."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class BarMenuTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('WAYLAND_DISPLAY') and shutil.which('quickshell'),
                         'requires a Wayland session and Quickshell')
    def test_settings_and_context_actions_keep_selections_separate(self):
        env = dict(os.environ, QT_QPA_PLATFORM='wayland', QT_QUICK_BACKEND='software')
        project = Path(__file__).resolve().parents[1]
        template = (project / 'tests/bar-menu-regression/shell.qml').read_text()
        with tempfile.TemporaryDirectory(prefix='omadocks-bar-menu-test-') as fixture:
            # Use the installed shell's real UI and theme components.
            for module in ('Commons', 'Ui'):
                (Path(fixture) / module).symlink_to(Path('/usr/share/omarchy/shell') / module, target_is_directory=True)
            (Path(fixture) / 'shell.qml').write_text(template.replace('"OMADOCKS_TEST_MODULE"',
                                                                  json.dumps(project.as_uri())))
            result = subprocess.run(['quickshell', '-p', fixture, '--no-color'],
                                    env=env, stdin=subprocess.DEVNULL, capture_output=True,
                                    text=True, timeout=15)
        output = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, output)
        marker = 'QA_BAR_RESULT '
        matches = [line.split(marker, 1)[1] for line in output.splitlines() if marker in line]
        self.assertTrue(matches, output)
        self.assertEqual(json.loads(matches[-1]), [], output)
