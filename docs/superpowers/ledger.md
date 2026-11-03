# OmaDocks build ledger

The user requested direct execution: brainstorming questions were opted out.
Work is in the requested dedicated checkout `~/Projects/OmaDocks`, branch
`feat/folder-stacks`; no second checkout is needed for an initially empty repo.

Tasks 1–2 complete: inherited dock copied with MIT attribution; independent
state migration, directory reader, pure folder/geometry model, 9 JS tests and
6 Python directory/state tests pass.

Task 3 implemented: Fan/Grid/List with overflow, scrolling, hover cascades,
animations, icon opening, native drag sources and drop targets, GIO Move/Copy,
folder pinning/reordering/unpinning, integrated Omarchy settings and outside
dismissal. Live Quickshell loads successfully; native drag and recursive
navigation validation still in progress. Current suite: 9 JS, 11 Python,
9 Qt Quick assertions including suite lifecycle.

Ruling: use the user's dedicated empty checkout in place — user explicitly
requested Projects/OmaDocks — no existing branch/work is affected.
Ruling: use the active customized Dockseid source as the base — preserves the
actual running dock — older archives may contain additional dormant changes.
Ruling: retain wallpaper blur as the portable fallback — inherited dock uses
it and no compositor settings need to change — windows behind the panel are
not visible through that fallback.

An early live test hit a Qt icon-loader pure-virtual abort on the background
pixmap thread. Core showed QQuickPixmapReader -> QIcon::pixmap. System icon
provider loads now run synchronously; local bitmap assets remain asynchronous.
Subsequent reloads have not crashed. Original desktop shell was unaffected.

User refinements: no plus button; no generic Linux settings dialog; compact
Omarchy settings in the bar; clicking outside retracts the dock. Drag folders
to pin; files move to/from folders, Ctrl copies, terminal gets a path only.

2026-11-03 installed milestone: dedicated plugin is now loaded in the normal
Omarchy shell. `omarchy-shell io.github.viniabdalla.omadocks status` returns
loaded=true with user's folders and 6 apps. Original dock disabled; original
checkout/state retained. Existing bar indicator uses compatibility IPC route.
Current passing suites: 9 JS, 14 Python, 12 QML (including lifecycle).

User latest refinement: remove the top view toolbar; Fan/Grid/List and Open
in file manager now live in an Omarchy-styled right-click menu on the pinned
folder icon and the open stack. Generic settings dialog and plus removed.

Independent reviewer findings addressed: side-edge Fan pointer targets, List
selection after shrinking, no-clobber pin action, cross-filesystem folder
move fallback retaining original until copy success, visible error toasts,
correct copied/moved wording. Regression tests observed RED then GREEN.

Live QA evidence: native outbound Move into Nautilus succeeded (source gone,
destination content intact). Three hover-only cascade levels and outside
dismissal passed. Ctrl-copy offer has Qt pointer-modifier regression coverage;
several live Ctrl attempts were invalidated by target being in closed
scratchpad / changing window geometry. Do NOT claim end-to-end Ctrl or terminal
verification yet. User needs their computer: stop all host mouse/keyboard tests.
Any further native checks must be isolated offscreen. All uinput devices were
closed and no wtype process remains.

Development runtime moved to /run/user/1000/omadocks-dev-1000, linking only runtime
assets. Earlier .runtime project-root symlink created recursive watching and
reloads during QA changes. It was removed, and QA artifacts moved to
/tmp/omadocks-qa-artifacts-1793733483. The normal shell was restarted once and
is responsive with no Hyprland config errors. Dev instance stopped.

Pending: finish isolated native protocol checks (Ctrl and terminal), verify
right-click full integration without host automation, finalize docs/installer
handling, push repository to main and full completion audit.

Isolated Weston follow-up: Ctrl-copy into Nautilus was verified with the
original retained. Both-action native offers can be selected as Copy by the
destination even though OmaDocks proposes Move. A Move-only offer moved in
Nautilus but was rejected by foot, so that experiment was reverted to retain
terminal compatibility. Native outbound default-Move across receivers remains
an unresolved limitation; do not claim the entire original goal complete.
The toolbar removal and right-click folder menu are installed and pushed on
main in d5aaa2d. No host pointer or keyboard automation was used in this follow-up.
