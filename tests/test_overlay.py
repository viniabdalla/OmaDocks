"""Run the actual Quickshell overlay hidden; no pointer or keyboard injection."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class OverlayTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('WAYLAND_DISPLAY') and shutil.which('quickshell'),
                         'requires a Wayland session and Quickshell')
    def test_outgoing_drag_releases_and_hides_the_complete_overlay(self):
        env = dict(os.environ, QT_QPA_PLATFORM='wayland', QT_QUICK_BACKEND='software')
        project = Path(__file__).resolve().parents[1]
        template = (project / 'tests/overlay-regression/shell.qml').read_text()
        with tempfile.TemporaryDirectory(prefix='omadocks-overlay-test-') as fixture:
            # A file URL avoids Quickshell scanning unrelated dock components.
            (Path(fixture) / 'shell.qml').write_text(template.replace('"OMADOCKS_TEST_MODULE"',
                                                                  json.dumps(project.as_uri())))
            result = subprocess.run(['quickshell', '-p', fixture, '--no-color'],
                                    env=env, stdin=subprocess.DEVNULL, capture_output=True,
                                    text=True, timeout=15)
        output = result.stdout + result.stderr
        self.assertEqual(result.returncode, 0, output)
        marker = 'QA_OVERLAY_RESULT '
        matches = [line.split(marker, 1)[1] for line in output.splitlines() if marker in line]
        self.assertTrue(matches, output)
        self.assertEqual(json.loads(matches[-1]), [], output)
