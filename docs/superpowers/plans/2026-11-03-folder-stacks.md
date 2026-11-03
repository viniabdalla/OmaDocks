# OmaDocks Folder Stacks Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. The user requested immediate execution in this session.

**Goal:** Preserve the user's running dock and add macOS-style Fan, Grid and cascading List folder stacks.

**Architecture:** Fork the active QML plugin into this dedicated repository. A Python JSON helper enumerates directories asynchronously; focused QML components render the three views. The existing dock controller owns persisted folder settings.

**Tech Stack:** QML, Quickshell, JavaScript, Python 3 standard library, Node test runner.

**Spec:** `docs/superpowers/specs/2026-11-03-omadocks-design.md`

## Global Constraints

Preserve existing dock features and MIT attribution. Own ID `io.github.viniabdalla.omadocks`, state `~/.local/state/omadocks`, repository `~/Projects/OmaDocks`. All three views, scrolling and hover-only recursive navigation must work. Do not replace the original plugin until the new one loads successfully.

## Review Focus

Filenames with spaces, quotes, non-ASCII and newlines must open literally.
Symlinks and inaccessible/disappearing folders must not break navigation.
Large folders must scroll and Fan must offer Grid overflow.
Edge placement and cascading panels must remain within the active screen.
Reloading settings must preserve both inherited app state and folder choices.

### Task 1: Fork and model

Files: inherited QML/JS/icons; `StackModel.js`; `tests/stack-model.test.cjs`.
Interfaces: normalized folder `{path,name,view,showHidden,sort}`; `normalizeFolders(raw)`, `fanLayout(count,height)`, `stackRect(edge,anchor,size,screen)`.

- [x] Copy the active plugin preserving license and attribution; rename ID and state paths.
- [x] Write tests for folder validation, view defaults, deduplication, URI handling, fan overflow, screen geometry and app/folder state round trips; run them failing.
- [x] Implement the pure model and persistence integration, run tests, commit.

### Task 2: Directory service

Files: `helpers/folders.py`; `tests/test_folders.py`; `FolderModel.qml`.
Interfaces: helper `list PATH --sort name|modified --hidden` emits `{path,entries,total,error}` JSON; entry `{name,path,url,isDir,icon,modified}`. QML `FolderModel` exposes `path`, `entries`, `loading`, `error`, `refresh()`.

- [x] Write real temporary-directory tests covering sorting, hidden files, symlinks, literal paths, missing paths and errors; run failing.
- [x] Implement helper and asynchronous refresh with stale-response protection; run tests, commit.

### Task 3: Stack views and integration

Files: `FolderStack.qml`, `StackFan.qml`, `StackGrid.qml`, `StackList.qml`, `StackSettings.qml`; modify `Dock.qml` and `DockSurface.qml`.
Interfaces: views emit `openEntry(entry)`, `showAll()`, `dismiss()`; stack overlay owns current path/view, anchoring and dismissal. Settings emit add/update/remove requests.

- [x] Add QML tests for Fan geometry, overflow activation, Grid entry activation and scrolling, List hover navigation and settings persistence; observe failure before creating views.
- [x] Build the folder settings panel and pinned folder strip with per-folder view controls.
- [x] Implement elastic Fan with perspective/shadows and overflow Grid shortcut.
- [x] Implement expanding blurred Grid with hover selection, scrolling and file activation.
- [x] Implement fast sliding List with delayed hover cascades and screen bounds.
- [x] Integrate keyboard/outside-click dismissal and auto-hide reveal hold; run tests and live loading checks; commit.

### Task 4: Delivery and visual validation

Files: README, install/dev scripts, QA evidence and recorded decisions.

- [x] Run full Python/JS/QML suites and inspect real running Fan/Grid/List views, nested navigation, file opening and persisted state.
- [x] Perform independent code review and fix material issues with regression coverage.
- [x] Install reversibly, verify plugin loaded and desktop healthy, retain original state and plugin for rollback.
- [x] Commit, push to the user-provided repository and report actual validation and limitations.
