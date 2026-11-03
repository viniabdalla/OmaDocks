#!/usr/bin/env python3
"""Run the checkout as a separate Quickshell config for development."""
import os
from pathlib import Path

project=Path(__file__).resolve().parents[1]
runtime=project/'.runtime'
runtime.mkdir(exist_ok=True)
shell=Path(os.environ.get('OMARCHY_PATH','/usr/share/omarchy'))/'shell'
for source in shell.iterdir():
    if source.is_dir() and source.name not in {'plugins','tests'}:
        target=runtime/source.name
        if not target.exists(): target.symlink_to(source,target_is_directory=True)
target=runtime/'OmaDocks'
if not target.exists(): target.symlink_to(project,target_is_directory=True)
(runtime/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "OmaDocks" as OmaDocks\nShellRoot { OmaDocks.Dock {} }\n')
os.execvp('quickshell',['quickshell','--no-color','-p',str(runtime)])
