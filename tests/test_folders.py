import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[1] / 'helpers/folders.py'
STATE_HELPER = HELPER.with_name('state.py')

class FolderTests(unittest.TestCase):
    def test_inspect_distinguishes_dropped_folders_and_apps(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); (p/'Folder').mkdir(); (p/'steam.desktop').touch(); (p/'note.txt').touch()
            proc=subprocess.run([sys.executable,str(HELPER),'inspect',str(p/'Folder'),str(p/'steam.desktop'),str(p/'note.txt')],capture_output=True,text=True)
            self.assertEqual(proc.returncode,0,proc.stderr)
            entries=json.loads(proc.stdout)['entries']
            self.assertTrue(entries[0]['isDir'])
            self.assertEqual(entries[1]['appId'],'steam')
            self.assertFalse(entries[2]['isDir'])

    def read(self, path, *options):
        proc = subprocess.run([sys.executable, str(HELPER), 'list', str(path), *options], capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        return json.loads(proc.stdout)

    def test_natural_sort_hidden_and_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)
            for name in ['file10.txt','file2.txt','.secret','file1.txt']:
                (p/name).touch()
            (p/'Zoo').mkdir()
            self.assertEqual([x['name'] for x in self.read(p)['entries']], ['Zoo','file1.txt','file2.txt','file10.txt'])
            self.assertEqual(self.read(p,'--hidden')['total'],5)

    def test_literal_filename_uri_and_symlink_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp); name='héllo #?\n"$(touch BAD).txt'
            (p/name).touch(); (p/'target').mkdir(); (p/'link').symlink_to(p/'target',target_is_directory=True)
            data=self.read(p); entry=next(x for x in data['entries'] if x['name']==name)
            self.assertEqual(entry['path'],str(p/name))
            self.assertIn('%23%3F%0A%22%24%28touch%20BAD%29',entry['url'])
            self.assertTrue(next(x for x in data['entries'] if x['name']=='link')['isDir'])

    def test_missing_and_nondirectory_paths_report_errors(self):
        self.assertTrue(self.read('/nonexistent/omadocks-test')['error'])
        with tempfile.NamedTemporaryFile() as f:
            self.assertTrue(self.read(f.name)['error'])

    def test_modified_sort_and_large_folder_are_not_truncated(self):
        import os
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)
            for n in range(220):
                f=p/f'file{n}.txt'; f.touch(); os.utime(f,(100+n,100+n))
            data=self.read(p,'--sort','modified')
            self.assertEqual(data['total'],220)
            self.assertEqual(len(data['entries']),220)
            self.assertEqual(data['entries'][0]['name'],'file219.txt')

    def test_first_start_migrates_without_changing_original_or_overwriting_new_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); old=root/'dockseid'; new=root/'omadocks'
            old.mkdir(); original='{"pinned":["steam"],"settings":{"size":0.85}}'
            (old/'state.json').write_text(original)
            proc=subprocess.run([sys.executable,str(STATE_HELPER),str(new),str(old)],capture_output=True,text=True)
            self.assertEqual(proc.returncode,0,proc.stderr)
            data=json.loads((new/'state.json').read_text())
            self.assertEqual(data['pinned'],['steam']); self.assertEqual(data['settings']['size'],0.85)
            self.assertTrue(data['folders'][0]['path'].startswith('/'))
            self.assertEqual((old/'state.json').read_text(),original)
            (new/'state.json').write_text('{"folders":[]}')
            subprocess.run([sys.executable,str(STATE_HELPER),str(new),str(old)],check=True)
            self.assertEqual((new/'state.json').read_text(),'{"folders":[]}')

if __name__ == '__main__': unittest.main()
