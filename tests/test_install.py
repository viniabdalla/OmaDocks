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
        self.assertEqual(out['plugins'],[{'id':'other'},{'id':module.PLUGIN_ID},{'id':module.TOOLBAR_ID}])
        self.assertEqual(out['bar']['layout']['left'],cfg['bar']['layout']['left'])
        self.assertEqual(out['bar']['layout']['center'],[{'id':'viniabdalla.indicators'},{'id':module.TOOLBAR_ID}])
        self.assertIn('io.github.silkvain.dockseid',out['disabledPlugins'])
        self.assertEqual(module.configure(out),out)

    def test_clean_install_adds_settings_widget(self):
        self.assertTrue(SCRIPT.exists(),'Installer is not implemented')
        spec=importlib.util.spec_from_file_location('install',SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        out=module.configure({})
        self.assertEqual(out['bar']['layout']['center'],[{'id':module.PLUGIN_ID},{'id':module.TOOLBAR_ID}])

    def test_toolbar_is_adjacent_independent_and_keeps_user_placement(self):
        spec=importlib.util.spec_from_file_location('install',SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        toolbar='io.github.viniabdalla.omadocks.toolbar'
        cfg={'bar':{'layout':{'left':[{'id':'other'},{'id':module.PLUGIN_ID},{'id':module.TOOLBAR_ID}]}},'plugins':[]}
        out=module.configure(cfg)
        self.assertEqual(out['bar']['layout']['left'],[{'id':'other'},{'id':module.PLUGIN_ID},{'id':toolbar}])
        self.assertIn({'id':toolbar},out['plugins'])
        self.assertEqual(module.configure(out),out)
        out['bar']['layout']['left'].pop()
        out['bar']['layout']['right']=[{'id':toolbar}]
        moved=module.configure(out)
        self.assertEqual(moved['bar'],out['bar'])

    def test_toolbar_prefers_the_actual_shortcut_group_over_legacy_indicator(self):
        spec=importlib.util.spec_from_file_location('install',SCRIPT)
        module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        cfg={'bar':{'layout':{'centerBegin':[{'id':'viniabdalla.indicators'}],
                             'centerEnd':[{'id':module.PLUGIN_ID}]}}}
        out=module.configure_toolbar(cfg)
        self.assertEqual(out['bar']['layout']['centerBegin'],cfg['bar']['layout']['centerBegin'])
        self.assertEqual(out['bar']['layout']['centerEnd'],[{'id':module.PLUGIN_ID},{'id':module.TOOLBAR_ID}])
