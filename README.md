# OmaDocks

An Omarchy dock with macOS-style **Fan, Grid and List folder stacks**.
Built on the customized Dockseid dock, retaining its application grouping,
pinned apps, drag ordering, agent/web-app icons, magnification, glass effects,
theme settings, four-edge placement, multiple monitors and auto-hide.

## Folder stacks

- **Fan:** files spring from the folder in a curved arc, with elastic motion,
  perspective scaling, shadows and hover labels. **Show all** opens Grid when
  the folder contains more items than fit.
- **Grid:** a dark frosted panel expands from the folder icon. File icons fade
  and pop in together, hover selection follows the pointer, and contents scroll.
- **List:** a compact menu slides open. Hover subfolders to open cascading
  menus, continuing through multiple levels without clicks.

Click an item to open it in its usual application. Grid folders open inside
that panel; List folders expand on hover. Escape or a click outside dismisses
all folder panels and retracts an auto-hide dock. Right-click the folder icon or open stack for Fan/Grid/List, Open in file
manager, sorting, hidden files and unpinning. Folder views have no top toolbar.

## Drag and drop

Drag a folder from your file manager onto an empty part of the dock to pin it.
Drag an existing folder icon to reorder it, or away from the dock to unpin it.
Dropping files **on a pinned folder** transfers them into that folder; hovering
first spring-opens it, so you can target a nested folder.

| Drop destination | Default | With Ctrl held |
| --- | --- | --- |
| A folder icon or subfolder inside a stack | Move | Copy |
| A file-manager folder, dragging out of a stack | Offer Move | Offer Copy |
| A terminal | Insert the file path; retain the file | Insert the file path; retain the file |

Native destinations negotiate the final action. OmaDocks never deletes a
source in response to a native drag-finished signal: the destination file
manager performs its own transfer. Existing destination names are never
silently overwritten. Transfer failures produce a desktop notification.

When dragging out, the stack disappears and its entire mouse-input region is
released, so you can drop on the window that was behind it. An auto-hide dock
retracts at the start of the gesture. The overlay releases keyboard focus while
dragging and as soon as closing starts. On Hyprland, **Escape cancels a native
drag before dropping**; it also closes an ordinary open stack. It does not undo
a transfer that the destination has already started after a drop.

Both Copy and Move remain available to native destinations for terminal
compatibility. Some file managers choose Copy even when Move is proposed.
Holding Ctrl when starting the drag offers Copy only. Dropping on folders
inside OmaDocks uses Move by default and Ctrl to copy.

There is **no plus button on the dock**. Manage pinned folders from the
**Folders** tab in the dock-settings popover in the bar. It uses Omarchy's
own themed UI components. Set each folder's display name, default view,
name/newest sorting and hidden-file visibility there.

## Install from this checkout

Requires Omarchy's Quickshell shell, Hyprland, Python 3, `python-gobject`
(GIO), `xdg-open` and `notify-send`. These are available on the development
machine. Run inside your graphical Omarchy session:

```sh
git clone https://github.com/viniabdalla/OmaDocks.git ~/Projects/OmaDocks
cd ~/Projects/OmaDocks
python3 scripts/install.py
```

The installer links this checkout into
`~/.config/omarchy/plugins/io.github.viniabdalla.omadocks`, disables the
original Dockseid plugin, and preserves your other plugins and bar layout.
Your existing customized dock-settings bar indicator continues to work via a
compatibility IPC route. On other bar layouts it adds the OmaDocks settings
widget.

Before changing the shell configuration it saves a timestamped backup under
`~/.local/state/omadocks/install-backups/`. The original Dockseid checkout and
state file are retained. To roll back, restore that backup's `shell.json` to
`~/.config/omarchy/shell.json`, then run `omarchy-shell shell rescanPlugins`.
If the running shell does not confirm the refresh, the installer reports that
separately and gives a restart command to run when convenient.

OmaDocks stores its settings independently in
`~/.local/state/omadocks/state.json`. First start imports your existing
Dockseid app pins, ordering and appearance and adds a Downloads stack. Later
starts preserve your OmaDocks choices, including an intentionally empty folder
list. Set `OMADOCKS_STATE_DIR` to use another directory during development.

## Development and verification

```sh
python3 scripts/dev.py
bash scripts/test.sh
```

The development launcher uses a separate Quickshell configuration under
`$XDG_RUNTIME_DIR/omadocks-dev-<uid>`. Close it before enabling the installed
plugin to avoid two docks. It links only runtime assets, so changing test
fixtures does not reload a native drag in progress.

Tests cover real directory enumeration, literal filenames/URIs, symlinks,
large folders, state migration, app/folder persistence, panel geometry,
Fan overflow and click targets on every edge, Grid scrolling/activation,
List hover and shrinking contents, animation startup, drag MIME/action offers,
copy/move/no-clobber transfers, and cross-filesystem folder moves/failures.
The runner uses Qt 6's `qmltestrunner`; override `QML_TEST_RUNNER` if your Qt 6
installation has a different path.

Useful installed-session diagnostics:

```sh
omarchy-shell io.github.viniabdalla.omadocks status
omarchy-shell io.github.viniabdalla.omadocks folders
omarchy-shell io.github.viniabdalla.omadocks stackStatusOn DP-3
```

## Attribution and rendering notes

OmaDocks derives from [Dockseid by Silkvain](https://github.com/Silkvain/Dockseid)
and Vini's customized checkout at `64f0701`. Original code and icon attribution
are retained in [LICENSE](LICENSE) and [icons/README.md](icons/README.md).
The new folder-stack work is also MIT licensed.

The portable frosted background blurs a correctly positioned wallpaper crop,
as in the inherited dock. It does not sample other application windows behind
it. Native drag offers use [Qt Quick's Drag API](https://doc.qt.io/qt-6/qml-qtquick-drag.html).
