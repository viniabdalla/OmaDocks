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
