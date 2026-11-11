#!/usr/bin/env python3
"""Read default app IDs without starting either application."""
import json
import subprocess


def desktop_id(command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=5, check=False)
        if result.returncode:
            return ''
        value = result.stdout.strip().splitlines()[0].split(':', 1)[0]
        return value.removesuffix('.desktop')
    except (OSError, subprocess.TimeoutExpired, IndexError):
        return ''


def discover(terminal='xdg-terminal-exec', browser='omarchy-cmd-default-browser'):
    return {'terminal': desktop_id([terminal, '--print-id']),
            'browser': desktop_id([browser]), 'herdr': 'herdr'}


if __name__ == '__main__':
    print(json.dumps(discover()))
