# OmaDocks

Build the user's own dock in `~/Projects/OmaDocks`, connected to
`viniabdalla/OmaDocks`. The user explicitly requested proceeding with the build.

## Approach

Extend the currently running customized Dockseid checkout (commit 64f0701).
Keep its MIT license and attribution. A rewrite would discard working Omarchy
integration; an external file browser would not provide the requested dock
animations. Use QML/Quickshell and a small Python standard-library directory
reader. Preserve app pinning, ordering, grouping, agent and web app icons,
minimize/restore, placement, multi-monitor support, theme, glass, magnification,
auto-hide, settings and the bar settings entry.

Give OmaDocks its own plugin ID, IPC target and state directory. Import the
existing Dockseid state on first use without changing the original. Include
Downloads as the initial folder stack, with controls to add arbitrary folders,
choose a view per folder, rename and remove stacks. Open files with their normal
desktop application. Folder contents refresh while open; inaccessible, empty,
large and changing directories have explicit states.

## Folder views

* Fan: files spring outward in a curved diagonal arc with elastic motion,
  increasing icon scale, soft shadows and smooth hover highlights. The last
  slot becomes Show all when there are more files than fit, opening Grid.
* Grid: a dark translucent, blurred panel expands from the folder icon. Icons
  fade and scale in together, in regular rows. A gray selection follows hover;
  large folders scroll inside the panel.
* List: a narrow vertical menu slides from the folder icon. Names and small
  icons align left. Hovering a subfolder opens a cascading menu to the side,
  recursively, without clicks. Menus flip or slide to stay on screen.

Close with Escape, outside click or repeat click. Keep the dock revealed while
a stack is open. Opening files closes the stack. Account for all four dock
edges and multiple monitors. Provide keyboard navigation in Grid/List, an
Open folder action, view switching and explicit loading/error messages.

## Verification and delivery

Unit tests exercise real directory enumeration, filename/URI safety, symlinks,
sorting and truncation. JavaScript tests exercise folder normalization, state
round trips, fan overflow and screen-aware geometry. QML integration and live
Quickshell runs cover loading, view changes, navigation, animations and the
inherited dock. Install reversibly after verification, retaining the original
plugin and state. Commit the complete source and documentation to this repo.

Implementation choices: own state under `~/.local/state/omadocks`; natural
name sorting; hidden files off by default; approximately 8 Fan slots, adjusted
to screen space; 240–420 ms Fan/Grid animations and 120 ms List animation.
True compositor blur is used where the installed Hyprland supports it, with a
blurred wallpaper fallback. Do not silently claim visual verification from
unit tests alone.

## User refinements during the build

Remove the plus button from the dock. Folder administration belongs in the
bar's existing Omarchy-styled settings popover, as a compact Folders tab;
do not use a generic Linux configuration dialog. Clicking outside a folder
view dismisses it and immediately retracts an auto-hide dock.

Drag folders onto the dock to pin them. Reorder folder icons by dragging and
unpin by dragging away. Dropping files onto a folder moves them by default;
holding Ctrl copies them. Files can be dragged out of every stack view to
other applications using native Wayland drag and drop. A file manager moves
by default, Ctrl requests Copy, and a terminal receives the file path without
moving the source. Never delete sources on a drag-finished callback: the
destination file manager performs its own move. Never overwrite a colliding
destination. Use GIO for filesystem transfers (available on this machine).
