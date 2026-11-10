# Bar favorites validation — 2026-11-10
Historical shared-selection prototype; superseded by independent barPinned selection in docs/qa/independent-bar-favorites/README.md.


`bash scripts/test.sh`: 13 Node tests, 15 Python tests, 16 Qt Quick results passed.
`git diff --check`: clean. Independent review completed; selection reset and
empty-search activation findings corrected. Existing left-click settings action
preserved; right-click uses the native KeyboardPanel app chooser.

Live shell: four Trópico favorites displayed inline beside the OmaDocks button.
Shared state contains the four apps plus existing Chrome and Ghostty pins;
Downloads folder and earlier dock settings retained. Search Oracle + Enter
removed its shared pin; repeated Enter restored it; intended ordering restored.
Empty search results + Up + Enter produced no errors. Esc closed the panel.
State and enabled setting survived shell restarts. Live scrolling through the
same function used by the arrows produced offsets 0, 1, 2 and clamped at both
ends. Automated compositor mouse injection did not demonstrate arrow clicks;
scroll behavior was verified through the widget IPC and model tests.

Chooser uses a native KeyboardPanel because the existing PopupWindow settings
anchor cannot reliably acquire focus from a bar-triggered IPC request on this
Wayland session. The existing dock settings popup was not otherwise redesigned.

Installed link now targets ~/Projects/OmaDocks, origin viniabdalla/OmaDocks.
Old source copy retained at ~/Projects/desktop-customizations/OmaDocks.
Config/state backups: ~/.local/state/omadocks/bar-favorites-backup-20261110/.
No push or commit performed.
