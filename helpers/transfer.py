#!/usr/bin/env python3
"""Move dropped local files without overwriting existing destinations."""
import argparse
import json
import os
import shutil
from pathlib import Path


def copy_entry(source,target,Gio):
    if source.is_dir() and not source.is_symlink():
        target.mkdir()
        for child in source.iterdir(): copy_entry(child,target/child.name,Gio)
    else:
        Gio.File.new_for_path(str(source)).copy(
            Gio.File.new_for_path(str(target)),Gio.FileCopyFlags.NOFOLLOW_SYMLINKS,None,None)


def move_files(sources, destination, copy=False):
    result={'moved':[], 'errors':[]}
    dest=Path(destination)
    if not dest.is_dir():
        return {'moved':[], 'errors':['Destination is not an accessible folder']}
    for raw in sources:
        source=Path(raw)
        target=dest/source.name
        try:
            if not os.path.lexists(source):
                raise FileNotFoundError(f'File no longer exists: {source.name}')
            if source.absolute()==target.absolute():
                continue
            if source.is_dir() and not source.is_symlink() and dest.resolve().is_relative_to(source.resolve()):
                raise ValueError(f'Cannot move a folder into itself: {source.name}')
            if os.path.lexists(target):
                raise FileExistsError(f'Already exists: {source.name}. Nothing overwritten.')
            import gi
            gi.require_version('Gio','2.0')
            from gi.repository import Gio
            # No OVERWRITE flag: GIO atomically refuses a destination collision.
            if copy:
                copy_entry(source,target,Gio)
            else:
                try:
                    Gio.File.new_for_path(str(source)).move(
                        Gio.File.new_for_path(str(target)), Gio.FileCopyFlags.NOFOLLOW_SYMLINKS,
                        None, None)
                except Exception as exc:
                    if not (source.is_dir() and not source.is_symlink() and
                            getattr(exc,'code',None)==Gio.IOErrorEnum.WOULD_RECURSE):
                        raise
                    # GIO does not recursively move a directory between
                    # filesystems. Keep the entire original until copying
                    # succeeds; copy_entry creates the destination exclusively.
                    before=tree_stamp(source)
                    copy_entry(source,target,Gio)
                    if tree_stamp(source)!=before:
                        raise OSError('Source changed while copying; original retained')
                    shutil.rmtree(source)
            result['moved'].append(str(target))
        except Exception as exc:
            result['errors'].append(str(exc))
    return result


def tree_stamp(directory):
    paths=[directory]+list(directory.rglob('*'))
    return sorted((str(p.relative_to(directory)),p.lstat().st_ino,p.lstat().st_size,p.lstat().st_mtime_ns)
                  for p in paths)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination')
    parser.add_argument('sources',nargs='+')
    parser.add_argument('--copy',action='store_true')
    args=parser.parse_args()
    print(json.dumps(move_files(args.sources,args.destination,copy=args.copy)))
