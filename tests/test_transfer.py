import importlib.util
import tempfile
import unittest
from pathlib import Path

HELPER=Path(__file__).resolve().parents[1]/'helpers/transfer.py'

class TransferTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(HELPER.exists(),'Move helper is not implemented')
        spec=importlib.util.spec_from_file_location('transfer',HELPER)
        self.transfer=importlib.util.module_from_spec(spec); spec.loader.exec_module(self.transfer)

    def test_move_removes_source_and_preserves_literal_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); src=p/'a #?é.txt'; src.write_text('hello'); dest=p/'destination'; dest.mkdir()
            result=self.transfer.move_files([str(src)],str(dest))
            self.assertFalse(src.exists()); self.assertEqual((dest/src.name).read_text(),'hello')
            self.assertEqual(result['errors'],[])

    def test_collision_never_overwrites_either_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); src=p/'note'; src.write_text('original'); dest=p/'destination'; dest.mkdir(); (dest/'note').write_text('existing')
            result=self.transfer.move_files([str(src)],str(dest))
            self.assertTrue(result['errors']); self.assertEqual(src.read_text(),'original'); self.assertEqual((dest/'note').read_text(),'existing')

    def test_same_folder_is_noop_and_cannot_move_folder_inside_itself(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); src=p/'note'; src.write_text('hello')
            self.assertEqual(self.transfer.move_files([str(src)],str(p))['errors'],[])
            nested=p/'nested'; nested.mkdir(); (nested/'child').mkdir()
            self.assertTrue(self.transfer.move_files([str(nested)],str(nested/'child'))['errors'])
            self.assertTrue((nested/'child').is_dir())

    def test_symlink_moves_as_link(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); target=p/'target'; target.write_text('data'); link=p/'link'; link.symlink_to(target); dest=p/'dest'; dest.mkdir()
            self.assertEqual(self.transfer.move_files([str(link)],str(dest))['errors'],[])
            self.assertTrue((dest/'link').is_symlink()); self.assertTrue(target.exists()); self.assertFalse(link.is_symlink())

    def test_ctrl_copy_keeps_source_and_copies_folder_contents(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); src=p/'source'; src.mkdir(); (src/'nested').mkdir(); (src/'nested'/'note').write_text('keep me')
            dest=p/'destination'; dest.mkdir()
            result=self.transfer.move_files([str(src)],str(dest),copy=True)
            self.assertEqual(result['errors'],[])
            self.assertEqual((src/'nested'/'note').read_text(),'keep me')
            self.assertEqual((dest/'source'/'nested'/'note').read_text(),'keep me')

    def test_cross_device_folder_move_and_copy_failure_preserve_data(self):
        import os
        from unittest.mock import patch
        with tempfile.TemporaryDirectory(dir='/tmp') as tmp, tempfile.TemporaryDirectory(dir='/dev/shm') as other:
            p=Path(tmp); dest=Path(other)
            if os.stat(p).st_dev==os.stat(dest).st_dev: self.skipTest('Requires two filesystems')
            src=p/'source'; src.mkdir(); (src/'nested').mkdir(); (src/'nested'/'note').write_text('all bytes')
            result=self.transfer.move_files([str(src)],str(dest))
            self.assertEqual(result['errors'],[])
            self.assertFalse(src.exists()); self.assertEqual((dest/'source'/'nested'/'note').read_text(),'all bytes')
            failed=p/'failed'; failed.mkdir(); (failed/'note').write_text('retain original')
            with patch.object(self.transfer,'copy_entry',side_effect=OSError('simulated disk full')):
                result=self.transfer.move_files([str(failed)],str(dest))
            self.assertTrue(result['errors']); self.assertEqual((failed/'note').read_text(),'retain original')
