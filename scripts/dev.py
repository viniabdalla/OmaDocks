#!/usr/bin/env python3
"""Run the checkout as a separate Quickshell config for development."""
import os
from pathlib import Path

project=Path(__file__).resolve().parents[1]
runtime=Path(os.environ.get('XDG_RUNTIME_DIR','/tmp'))/('omadocks-dev-'+str(os.getuid()))
runtime.mkdir(exist_ok=True)
shell=Path(os.environ.get('OMARCHY_PATH','/usr/share/omarchy'))/'shell'
for source in shell.iterdir():
    if source.is_dir() and source.name not in {'plugins','tests'}:
        target=runtime/source.name
        if not target.exists(): target.symlink_to(source,target_is_directory=True)
package=runtime/'OmaDocks'
package.mkdir(exist_ok=True)
# Link only runtime assets. A symlink to the entire repository would also
# watch QA fixture writes and trigger reloads in the middle of native drags.
for source in project.iterdir():
    if source.suffix in {'.qml','.js'} or source.name in {'icons','helpers'}:
        target=package/source.name
        if not target.exists(): target.symlink_to(source,target_is_directory=source.is_dir())
(runtime/'shell.qml').write_text('import QtQuick\nimport Quickshell\nimport "OmaDocks" as OmaDocks\nShellRoot { OmaDocks.Dock {} }\n')
os.execvp('quickshell',['quickshell','--no-color','-p',str(runtime)])
