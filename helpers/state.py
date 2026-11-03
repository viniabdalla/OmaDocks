#!/usr/bin/env python3
"""Initialize independent OmaDocks state without modifying Dockseid."""
import json
import os
import sys
from pathlib import Path


def initialize(directory, legacy):
    directory.mkdir(parents=True, exist_ok=True)
    target=directory/'state.json'
    if target.exists():
        return
    try:
        state=json.loads((legacy/'state.json').read_text())
        if not isinstance(state,dict):
            state={}
    except (OSError, ValueError):
        state={}
    downloads=Path.home()/'Downloads'
    folder=downloads if downloads.is_dir() else Path.home()
    state['folders']=[{'path':str(folder),'name':folder.name,'view':'fan','sort':'name','showHidden':False}]
    # Exclusive creation keeps a second startup from overwriting the first.
    try:
        with target.open('x') as out:
            json.dump(state,out,indent=2)
            out.write('\n')
    except FileExistsError:
        pass


if __name__=='__main__':
    initialize(Path(sys.argv[1]),Path(sys.argv[2]))
