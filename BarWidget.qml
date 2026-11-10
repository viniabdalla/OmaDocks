import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "DockModel.js" as DockModel
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.viniabdalla.omadocks"

  readonly property bool opened: managing
  readonly property string openAtCursorCommand: [
    "pos=$(hyprctl cursorpos 2>/dev/null) || exit 0",
    "x=${pos%%,*}",
    "y=${pos#*,}",
    "x=${x//[[:space:]]/}",
    "y=${y//[[:space:]]/}",
    "monitor=$(hyprctl monitors -j 2>/dev/null | jq -r --argjson x \"$x\" --argjson y \"$y\" '.[] | select($x >= .x and $x < (.x + .width) and $y >= .y and $y < (.y + .height)) | .name' | head -n1)",
    "if [ -n \"$monitor\" ]; then",
    "  omarchy-shell io.github.viniabdalla.omadocks toggleSettingsOn \"$monitor\"",
    "else",
    "  omarchy-shell io.github.viniabdalla.omadocks toggleSettings",
    "fi"
  ].join("\n")

  function open() {
    if (root.bar) root.bar.run("bash -lc " + Util.shellQuote(root.openAtCursorCommand))
  }
  function close() { root.managing = false }


  property var dockState: DockModel.defaultState()
  property int firstApp: 0
  readonly property bool showFavorites: dockState.settings.barFavorites
  readonly property var favorites: {
    var entries = DesktopEntries.applications.values
    return dockState.barPinned.filter(function(id) { return !!DesktopEntries.byId(id) })
  }
  onFavoritesChanged: firstApp = DockModel.barOffset(firstApp, 0, favorites.length)
  readonly property var visibleApps: favorites.slice(firstApp, firstApp + 4)
  implicitWidth: controls.implicitWidth
  implicitHeight: controls.implicitHeight

  property bool managing: false
  function manageApps() { managing = !managing }
  function scroll(delta) {
    firstApp = DockModel.barOffset(firstApp, delta, favorites.length)
  }
  IpcHandler {
    target: "io.github.viniabdalla.omadocks.bar"
    function apps(): void { root.managing = true }
    function scroll(direction: int): void { root.scroll(direction) }
    function status(): string { return JSON.stringify({ first: root.firstApp, apps: root.visibleApps, enabled: root.showFavorites }) }
  }
  FileView {
    path: (Quickshell.env("OMADOCKS_STATE_DIR") || (Quickshell.env("HOME") + "/.local/state/omadocks")) + "/state.json"
    watchChanges: true
    printErrors: false
    onLoaded: root.dockState = DockModel.parseState(text())
    onFileChanged: reload()
  }

  AppsPanel {
    id: appManager
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.managing
    pinnedIds: root.dockState.barPinned
    barFavorites: root.showFavorites
  }

  GridLayout {
    id: controls
    anchors.centerIn: parent
    columns: root.vertical ? 1 : 7
    rowSpacing: 0
    columnSpacing: 0

    BarIconButton {
      id: button
      bar: root.bar
      text: "▣"
      fontFamily: Style.font.family
      slotSize: Style.bar.statusSlot
      fontSize: Style.font.caption * 1.5
      tooltipText: "OmaDocks"
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.RightButton) root.manageApps()
        else if (mouseButton === Qt.LeftButton) root.open()
      }
    }
    BarIconButton {
      visible: root.showFavorites
      bar: root.bar
      text: root.vertical ? "⌃" : "‹"
      fontFamily: Style.font.family
      slotSize: Style.space(18)
      dimmed: root.firstApp === 0
      tooltipText: ""
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.RightButton) root.manageApps()
        else if (mouseButton === Qt.LeftButton) root.scroll(-1)
      }
      onWheelMoved: function(delta) { root.scroll(delta < 0 ? 1 : -1) }
    }
    Repeater {
      model: root.showFavorites ? root.visibleApps : []
      delegate: BarIconButton {
        id: appButton
        required property string modelData
        readonly property var entry: DesktopEntries.byId(modelData)
        bar: root.bar
        slotSize: Style.bar.iconSlot
        tooltipText: DockModel.barTooltip(entry ? entry.name : modelData)
        iconComponent: Image {
          width: Style.space(24)
          height: width
          fillMode: Image.PreserveAspectFit
          source: {
            var icon = appButton.entry ? String(appButton.entry.icon || "application-x-executable") : "application-x-executable"
            return icon.startsWith("/") ? Qt.resolvedUrl("file://" + icon) : Quickshell.iconPath(icon)
          }
        }
        onPressed: function(mouseButton) {
          if (mouseButton === Qt.RightButton) root.manageApps()
          else if (mouseButton === Qt.LeftButton && appButton.entry)
            Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", modelData + ".desktop"])
        }
        onWheelMoved: function(delta) { root.scroll(delta < 0 ? 1 : -1) }
      }
    }
    BarIconButton {
      visible: root.showFavorites
      bar: root.bar
      text: root.vertical ? "⌄" : "›"
      fontFamily: Style.font.family
      slotSize: Style.space(18)
      dimmed: root.firstApp >= Math.max(0, root.favorites.length - 4)
      tooltipText: ""
      onPressed: function(mouseButton) {
        if (mouseButton === Qt.RightButton) root.manageApps()
        else if (mouseButton === Qt.LeftButton) root.scroll(1)
      }
      onWheelMoved: function(delta) { root.scroll(delta < 0 ? 1 : -1) }
    }
  }
}
