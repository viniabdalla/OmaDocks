import importlib.util
import unittest
from pathlib import Path

SCRIPT=Path(__file__).resolve().parents[1]/'scripts/install.py'

class InstallTests(unittest.TestCase):
    def test_migration_preserves_other_plugins_and_reuses_existing_settings_button(self):
        self.assertTrue(SCRIPT.exists(),'Installer is not implemented')
        spec=importlib.util.spec_from_file_location('install',SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        cfg={'plugins':[{'id':'io.github.silkvain.dockseid'},{'id':'other'}],
             'bar':{'layout':{'center':[{'id':'viniabdalla.indicators'}],'left':[{'id':'omarchy.workspaces'}]}},
             'idle':{'lock':900}}
        out=module.configure(cfg)
        self.assertEqual(out['idle'],{'lock':900})
        self.assertEqual(out['plugins'],[{'id':'other'},{'id':module.PLUGIN_ID}])
        self.assertEqual(out['bar'],cfg['bar'])
        self.assertIn('io.github.silkvain.dockseid',out['disabledPlugins'])
        self.assertEqual(module.configure(out),out)

    def test_clean_install_adds_settings_widget(self):
        self.assertTrue(SCRIPT.exists(),'Installer is not implemented')
        spec=importlib.util.spec_from_file_location('install',SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        out=module.configure({})
        self.assertEqual(out['bar']['layout']['center'],[{'id':module.PLUGIN_ID}])
