# Independent bar favorites — verified 2026-11-10

Current behavior supersedes the shared-selection prototype documented under
../bar-favorites/. Main dock uses `pinned`; the bar uses `barPinned`.

Verification:
- Full scripts/test.sh: 15 Node tests, 16 Python tests, 16 Qt Quick results passed.
- New state tests cover independent lists, deduplication, old states, round trips.
- Real hidden Quickshell settings/context-menu test covers separate dock/bar
  signals, built-in Choose bar favorites button, empty search, add/remove labels,
  and context action emission.
- Live existing configuration menu: Bar favorites search accepted Oracle; Enter
  removed Oracle only from barPinned, leaving main pins intact. Repeated Enter
  restored it; Esc dismissed the native panel. Initial bar order restored.
- Restarted shell and re-read state: main pins Chrome/Ghostty; bar favorites
  Oracle/Artemis/CRM/Scraper. Existing folders and other settings match backup.
- Independent final review found no actionable issues. git diff --check clean.

Settings uses native KeyboardPanel for working Wayland keyboard focus and
outside-click dismissal. The existing context PopupWindow avoids the invalid
xdg grab on its invisible anchor and catches outside clicks on its own monitor.
Context routing/labels were exercised in the real QML fixture; a live mouse click
on a running dock app was not independently repeated. Multi-monitor context-menu
dismissal and every dock edge were not tested in this session.

Source remains local/uncommitted in ~/Projects/OmaDocks. No push performed.
State backup: ~/.local/state/omadocks/before-independent-bar-favorites.json.
