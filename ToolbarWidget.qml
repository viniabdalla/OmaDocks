import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "DockModel.js" as DockModel

BarWidget {
  id: root
  moduleName: "io.github.viniabdalla.omadocks.toolbar"
  property var dockState: DockModel.defaultState()
  readonly property var shortcuts: {
    var applications = DesktopEntries.applications.values
    return dockState.toolbarPinned.map(function(id) { return apps.entryFor(id) }).filter(function(entry) { return !!entry })
  }
  readonly property real slotSize: Style.space(30)
  readonly property real padding: Style.space(4)
  implicitWidth: shortcuts.length ? (vertical ? barSize : shortcuts.length * slotSize + padding * 2) : 0
  implicitHeight: shortcuts.length ? (vertical ? shortcuts.length * slotSize + padding * 2 : barSize) : 0

  BarInputPriority {}
  ToolbarApps { id: apps }
  FileView {
    path: (Quickshell.env("OMADOCKS_STATE_DIR") || (Quickshell.env("HOME") + "/.local/state/omadocks")) + "/state.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.dockState = DockModel.parseState(text())
    onFileChanged: reload()
  }
  GridLayout {
    anchors.centerIn: parent
    columns: root.vertical ? 1 : Math.max(1, root.shortcuts.length)
    rowSpacing: 0; columnSpacing: 0
    Repeater {
      model: root.shortcuts
      delegate: BarShortcut {
        id: shortcut
        BarDragFocus { anchorItem: shortcut; active: shortcut.dragging }
        required property var modelData
        objectName: "toolbarShortcut-" + modelData.id
        appId: modelData.id
        appName: modelData.name
        iconSource: modelData.iconSource
        iconSize: Style.space(20)
        groupItem: root
        bar: root.bar
        implicitWidth: root.vertical ? root.barSize : root.slotSize
        implicitHeight: root.vertical ? root.slotSize : root.barSize
        onActivated: function(id) { Quickshell.execDetached(DockModel.toolbarCommand(id)) }
        onRemoveRequested: function(id) { Quickshell.execDetached(["omarchy-shell", "io.github.viniabdalla.omadocks", "removeToolbar", id]) }
      }
    }
  }
}
