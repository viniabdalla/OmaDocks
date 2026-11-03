#!/usr/bin/env python3
"""Install this checkout in Omarchy; save the previous shell configuration."""
import argparse
import copy
import json
import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

PLUGIN_ID='io.github.viniabdalla.omadocks'
OLD_ID='io.github.silkvain.dockseid'


def configure(original):
    cfg=copy.deepcopy(original)
    cfg['plugins']=[p for p in cfg.get('plugins',[]) if (p.get('id') if isinstance(p,dict) else p) not in {OLD_ID,PLUGIN_ID}]
    cfg['plugins'].append({'id':PLUGIN_ID})
    cfg['disabledPlugins']=[p for p in cfg.get('disabledPlugins',[]) if p!=PLUGIN_ID]
    if OLD_ID not in cfg['disabledPlugins']: cfg['disabledPlugins'].append(OLD_ID)
    layout=cfg.setdefault('bar',{}).setdefault('layout',{})
    ids=[entry.get('id') for entries in layout.values() if isinstance(entries,list) for entry in entries if isinstance(entry,dict)]
    if 'viniabdalla.indicators' not in ids and PLUGIN_ID not in ids:
        layout.setdefault('center',[]).append({'id':PLUGIN_ID})
    return cfg


def install():
    project=Path(__file__).resolve().parents[1]
    home=Path.home()
    config=home/'.config/omarchy/shell.json'
    original=json.loads(config.read_text()) if config.exists() else {}
    backup=home/'.local/state/omadocks/install-backups'/datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    (backup/'shell.json').write_text(json.dumps(original,indent=2)+'\n')
    link=home/'.config/omarchy/plugins'/PLUGIN_ID
    link.parent.mkdir(parents=True,exist_ok=True)
    if link.is_symlink() and link.resolve()==project:
        pass
    else:
        if os.path.lexists(link): shutil.move(str(link),str(backup/'previous-plugin'))
        link.symlink_to(project,target_is_directory=True)
    updated=configure(original)
    config.parent.mkdir(parents=True,exist_ok=True)
    tmp=config.with_name('shell.json.omadocks-tmp')
    tmp.write_text(json.dumps(updated,indent=2)+'\n')
    tmp.replace(config)
    print('Installed:',project)
    print('Configuration backup:',backup/'shell.json')
    ipc_env=os.environ.copy()
    ipc_env['OMARCHY_SHELL_IPC_TIMEOUT']='3s'
    try:
        rescan=subprocess.run(['omarchy-shell','shell','rescanPlugins'],env=ipc_env,
                              timeout=5,check=False)
        refreshed=rescan.returncode==0
    except (OSError,subprocess.TimeoutExpired):
        refreshed=False
    if refreshed:
        print('The existing bar dock-settings button now opens OmaDocks.')
    else:
        print('Files and configuration are installed; the running shell did not confirm the refresh.')
        print('When convenient, run: omarchy restart shell')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.parse_args()
    install()
