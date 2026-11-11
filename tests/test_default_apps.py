import importlib.util
from pathlib import Path
import tempfile
import unittest

SCRIPT=Path(__file__).resolve().parents[1]/'helpers/default_apps.py'

class DefaultAppsTests(unittest.TestCase):
    def test_uses_system_resolvers_and_normalizes_ids_without_launching_apps(self):
        self.assertTrue(SCRIPT.exists(), 'default-app discovery missing')
        spec=importlib.util.spec_from_file_location('default_apps', SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            terminal=Path(directory)/'terminal'
            browser=Path(directory)/'browser'
            terminal.write_text('#!/bin/sh\n[ "$1" = --print-id ] || exit 2\nprintf "ghostty.desktop:NewWindow\\n"\n')
            browser.write_text('#!/bin/sh\nprintf "chrome.desktop\\n"\n')
            terminal.chmod(0o755); browser.chmod(0o755)
            self.assertEqual(module.discover(str(terminal),str(browser)),
                             {'terminal':'ghostty','browser':'chrome','herdr':'herdr'})
            self.assertEqual(module.discover('/missing-terminal','/missing-browser'),
                             {'terminal':'','browser':'','herdr':'herdr'})
