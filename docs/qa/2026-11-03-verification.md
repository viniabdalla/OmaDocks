# OmaDocks verification — 2026-11-03

This audit follows the user's final preferences, including right-click view
controls, Escape cancellation and keeping terminal compatibility even when an
external file manager chooses Copy. The native tests use the actual complete
Dock component, not a replacement drag-source window.

## Automated checks

`bash scripts/test.sh`: 10 JavaScript tests, 15 Python tests, and 13 Qt Quick
results (including two lifecycle hooks), all passing. The Python overlay test
constructs the real FolderStack **without mapping a window**. It checks the
empty outgoing input region, hidden contents, dock release, cancellation
cleanup and keyboard-focus release before the closing animation ends.

The new pointer regression activates a real DragHandler, delivers native
completion, and starts another gesture. It failed before the fix: the handler
remained active after the native release was consumed outside the source.
Recreating the gesture handlers after completion/cancellation makes repeated
drags work. Merely toggling `enabled` did not reset Qt's active grab.

## Native Hyprland checks

A separate Hyprland 0.56.2 instance runs on a private Wayland socket with a
1280×720 headless output. Foot and the complete OmaDocks component run inside
it with their own fixture state. Virtual pointer/keyboard clients connect only
to that socket. No host input is injected or host test window opened.

The NVIDIA driver required a **test-only** buffer-allocation adapter for the
headless monitor; the parent Weston server required newer optional protocol
version announcements. Neither adapter is used in the installed dock or user
session. Hyprland's input and drag/cancellation code and the production dock
QML are unchanged by those rendering adapters.

For **each of Fan, Grid and List**, native tests verify:

1. Start a drag from the actual stack's file item.
2. Confirm the outgoing gesture is active and the auto-hide dock has retracted.
3. Drop on the terminal, including the area formerly covered by the stack.
4. Confirm the received quoted path and unchanged original file contents.
5. Reopen the same view, begin another drag, and press Escape while holding
   the mouse button down. Confirm the stack is closed **before** mouse release.
6. Release the mouse and type into Foot. Confirm keyboard input works and no
   file path was inserted by the cancelled gesture. Hyprland may also forward
   the Escape key itself to the terminal; this is not a file transfer.

Additional live checks cover Ctrl at native drag start, right-clicking the
pinned folder and persisting List selection, three hover-only cascade levels,
Escape during a drag from the third cascade, dragging a folder to pin it while retaining the source directory, reordering
pinned folders and dragging away to unpin without deleting the directory.

A separate native source window also drops actual files onto the pinned
folder. Ctrl at source start advertises Copy only: the destination file appears
and the original remains. The normal Copy/Move offer moves the file: the
destination appears and the original is removed. Full destination contents are
checked in both cases. Qt Quick DropEvent exposes action flags, **not** a
`modifiers` property; both receivers now use the same supported-action policy.
A default Qt Copy proposal alone does not override OmaDocks' Move default.

Sanitized case data and hashes of the tested production files are stored in
[native-results.json](native-results.json). The original terminal fixture has
known content; tests compare the complete content after every operation.

## Requirement audit

| Requested behavior | Evidence |
| --- | --- |
| Own repo under Projects; retain existing dock features | Dedicated OmaDocks checkout and main branch; copied customized Dockseid source with original MIT/icon attribution; own plugin ID and state. |
| Preserve existing pins, ordering and appearance | State import/round-trip tests; installed status retains the user's applications and Downloads stack. Original plugin/state and installer backup retained. |
| Fan arc, perspective, elastic motion, shadows, overflow | StackFan/StackModel implementation; geometry, all-edge click-target, animation and overflow tests; user-provided live view images; native Fan drag/drop/cancel checks. |
| Grid expansion, frosted panel, hover and scrolling | StackGrid/StackBackdrop; animation/scroll/activation tests, user-provided live images and native Grid checks. Frosting uses the documented wallpaper-crop fallback, not sampling other application windows. |
| List slide and recursive hover subfolders | StackList/FolderStack; hover, shrinking-list and activation tests; three native hover-only levels and cancellation from the leaf. |
| Views on right-click; no top toolbar | FolderMenu and DockSurface wiring; actual pinned-icon right click, menu rendering and persisted view selection. |
| No plus on dock; compact themed settings in bar | Removed plus; Omarchy Ui/Commons components in SettingsPopup and StackSettings; installer reuses the existing bar settings IPC route. |
| Outside click/Escape close and retract | Common close/release path; hidden-overlay lifecycle regression, earlier live outside-click check, and native Escape checks in all three views. |
| Pin, reorder and remove folders by dragging | Native pin retains source; actual pointer drags reorder folders and unpin without deleting the directory. |
| Drop files into folders: Move; Ctrl: Copy | FileDrop/DockSurface honor Copy-only intent and default to Move when available; actual cross-client native copy/move checks plus no-clobber and cross-filesystem tests. |
| Outgoing native drag; terminal receives path only | All three views' actual native drops and Ctrl drop into Foot; original contents retained. User accepted external destination choosing Copy for compatibility. |
| Escape cancels before dropping and does not trap keys | Actual Hyprland native cancellation before mouse release, including a leaf cascade; terminal accepts subsequent typing. Hidden/closing overlay has no keyboard focus. |
| Installed desktop and saved source | User plugin symlink, independent state, existing settings-bar compatibility; responsive installed status and no Hyprland config errors; main branch pushed to the requested GitHub repo. |

Escape cancels an in-progress gesture. It cannot undo a transfer already
started by the receiving application after a completed drop.
