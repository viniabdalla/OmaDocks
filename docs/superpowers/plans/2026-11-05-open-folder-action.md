# Open folder action implementation plan

**Goal:** Implement the approved macOS-style action in Fan and Grid.
**Architecture:** Shared QML icon, existing view delegates, common FolderStack.openCurrentFolder().
**Tech Stack:** Qt Quick, Quickshell, JavaScript.
**Spec:** ../specs/2026-11-05-open-folder-action.md

- [x] Add failing model/view checks for Fan action at 0/2/30 entries, Grid final cell and keyboard activation, and opening/closing the current nested folder in the hidden overlay harness.
- [x] Implement OpenFolderIcon.qml, reserve the Fan final slot in StackModel.js, and connect StackFan/StackGrid.openFolder to FolderStack.openCurrentFolder(). Remove FolderMenu's action and its DockSurface signal handler.
- [x] Run bash scripts/test.sh and git diff --check; inspect offscreen Fan/Grid images and update README.

Review focus: empty folders, overflow within available height, Grid End/Return, actual nested path, synthetic actions must not become file drags/drop destinations. Preserve the existing uncommitted drag-preview changes. Execute inline; user already approved implementation.

Validation: 10 JavaScript tests, 15 Python tests and 16 Qt Quick results passed. Inspected /tmp/omadocks-open-folder-preview.png from an offscreen fixture. Its Fan file icons use the existing shadow effect unsupported by this software renderer; the new circled-arrow control renders in both views. No app launch/restart or native cross-client interaction was performed.
