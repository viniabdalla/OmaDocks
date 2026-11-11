"""Exercise installed companion-widget imports and file watching while hidden."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class ToolbarTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('WAYLAND_DISPLAY') and shutil.which('quickshell'), 'requires Wayland and Quickshell')
    def test_companion_widget_file_watching_and_empty_layout(self):
        project=Path(__file__).resolve().parents[1]
        template=(project/'tests/toolbar-regression/shell.qml').read_text()
        with tempfile.TemporaryDirectory(prefix='omadocks-toolbar-test-') as directory:
            fixture=Path(directory)
            state=fixture/'state'; state.mkdir()
            (state/'state.json').write_text(json.dumps({'pinned':['main-only'],'barPinned':['bar-only']}))
            for module in ('Commons','Ui'):
                (fixture/module).symlink_to(Path('/usr/share/omarchy/shell')/module,target_is_directory=True)
            # Load through a separate symlink just like the installed companion
            # plugin: imports must not accidentally resolve to its parent's path.
            (fixture/'toolbar-plugin').symlink_to(project/'toolbar',target_is_directory=True)
            source=template.replace('"OMADOCKS_TEST_MODULE"',json.dumps(project.as_uri()))
            source=source.replace('"TOOLBAR_TEST_MODULE"',json.dumps((fixture/'toolbar-plugin').as_uri()))
            (fixture/'shell.qml').write_text(source)
            env=dict(os.environ,QT_QPA_PLATFORM='wayland',QT_QUICK_BACKEND='software',OMADOCKS_STATE_DIR=str(state))
            result=subprocess.run(['quickshell','-p',str(fixture),'--no-color'],env=env,
                                  capture_output=True,text=True,timeout=15)
            output=result.stdout+result.stderr
            self.assertEqual(result.returncode,0,output)
            marker='QA_TOOLBAR_RESULT '
            matches=[line.split(marker,1)[1] for line in output.splitlines() if marker in line]
            self.assertTrue(matches,output)
            self.assertEqual(json.loads(matches[-1]),[],output)
            saved=json.loads((state/'state.json').read_text())
            self.assertEqual(saved['pinned'],['main-only'])
            self.assertEqual(saved['barPinned'],['bar-only'])
            self.assertEqual(saved['toolbarPinned'],['omadocks-default-terminal','omadocks-herdr','omadocks-default-browser'])
            # New QML must not silently warn about failed imports/properties.
            unexpected=[line for line in output.splitlines() if 'WARN scene:' in line and any(name in line for name in ('Toolbar','BarShortcut','BarInputPriority'))]
            self.assertEqual(unexpected,[],output)
