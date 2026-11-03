#!/usr/bin/env python3
"""Read directories as JSON. Paths are argv values; no shell is involved."""
import argparse
import json
import mimetypes
import os
import re
from pathlib import Path


def natural_key(name):
    return [int(part) if part.isdigit() else part.casefold() for part in re.split(r'(\d+)', name)]


def icon_name(path, is_dir):
    if is_dir:
        return 'folder'
    mime = mimetypes.guess_type(path)[0] or 'application/octet-stream'
    if mime == 'application/pdf':
        return 'application-pdf'
    if mime.startswith(('image/', 'audio/', 'video/', 'text/')):
        return mime.split('/')[0] + '-x-generic'
    if Path(path).suffix.casefold() in {'.zip', '.gz', '.xz', '.7z', '.rar', '.tar'}:
        return 'package-x-generic'
    return 'application-x-generic'


def list_folder(path, hidden=False, sort='name'):
    result = {'path': os.path.abspath(os.path.expanduser(path)), 'entries': [], 'total': 0, 'error': ''}
    try:
        with os.scandir(result['path']) as contents:
            for entry in contents:
                if not hidden and entry.name.startswith('.'):
                    continue
                try:
                    is_dir = entry.is_dir(follow_symlinks=True)
                    modified = entry.stat(follow_symlinks=True).st_mtime
                except OSError:
                    is_dir, modified = False, 0
                result['entries'].append({
                    'name': entry.name, 'path': entry.path, 'url': Path(entry.path).as_uri(),
                    'isDir': is_dir, 'icon': icon_name(entry.path, is_dir), 'modified': modified,
                })
        if sort == 'modified':
            result['entries'].sort(key=lambda e: (-e['modified'], natural_key(e['name'])))
        else:
            result['entries'].sort(key=lambda e: (not e['isDir'], natural_key(e['name'])))
        result['total'] = len(result['entries'])
    except OSError as exc:
        result['error'] = exc.strerror or str(exc)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['list', 'inspect'])
    parser.add_argument('path', nargs='+')
    parser.add_argument('--hidden', action='store_true')
    parser.add_argument('--sort', choices=['name', 'modified'], default='name')
    args = parser.parse_args()
    if args.action=='inspect':
        entries=[]
        for raw in args.path:
            path=Path(raw)
            if not path.exists(): continue
            entries.append({'path':str(path),'name':path.name,'isDir':path.is_dir(),
                            'appId':path.stem if path.suffix=='.desktop' else ''})
        result={'entries':entries}
    else:
        result=list_folder(args.path[0], args.hidden, args.sort)
    print(json.dumps(result, ensure_ascii=True))


if __name__ == '__main__':
    main()
