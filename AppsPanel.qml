import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "DockModel.js" as DockModel

KeyboardPanel {
  id: panel
  property var pinnedIds: []
  property bool barFavorites: false
  property int selectedIndex: 0
  contentWidth: Style.space(380)
  contentHeight: Style.space(480)
  focusTarget: search
  readonly property var entries: {
    var needle = search.text.toLowerCase()
    return DesktopEntries.applications.values.filter(function(entry) {
      return !entry.noDisplay && (entry.name || entry.id).toLowerCase().indexOf(needle) >= 0
    }).sort(function(a, b) { return (a.name || a.id).localeCompare(b.name || b.id) })
  }
  function activateSelected() {
    if (selectedIndex < 0 || selectedIndex >= entries.length) return
    toggleFavorite(entries[selectedIndex].id)
  }
  function toggleFavorite(id) {
    Quickshell.execDetached(["omarchy-shell", "io.github.viniabdalla.omadocks", "toggleFavorite", id])
  }
  onEntriesChanged: selectedIndex = Math.min(Math.max(0, selectedIndex), entries.length - 1)
  onSelectedIndexChanged: if (selectedIndex >= 0) list.positionViewAtIndex(selectedIndex, ListView.Contain)

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(10)
    Text {
      text: "OmaDocks · Bar favorites"
      textFormat: Text.PlainText
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
      color: Commons.Color.foreground
    }
    Button {
      Layout.fillWidth: true
      text: "Show favorites in the bar"
      selected: panel.barFavorites
      onClicked: Quickshell.execDetached(["omarchy-shell", "io.github.viniabdalla.omadocks", "barFavorites", panel.barFavorites ? "false" : "true"])
    }
    TextField {
      id: search
      objectName: "favoritesSearch"
      Layout.fillWidth: true
      placeholderText: "Search apps…"
      onTextChanged: panel.selectedIndex = 0
      Keys.onEscapePressed: panel.close()
      Keys.onDownPressed: panel.selectedIndex = Math.min(panel.entries.length - 1, panel.selectedIndex + 1)
      Keys.onUpPressed: panel.selectedIndex = panel.entries.length ? Math.max(0, panel.selectedIndex - 1) : -1
      Keys.onReturnPressed: panel.activateSelected()
      Keys.onEnterPressed: panel.activateSelected()
    }
    ListView {
      id: list
      objectName: "favoritesList"
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      model: panel.entries
      spacing: Style.space(2)
      delegate: Button {
        id: appRow
        required property var modelData
        required property int index
        objectName: "favoriteRow-" + modelData.id
        width: list.width
        height: Style.space(36)
        hasCursor: panel.selectedIndex === index
        selected: panel.pinnedIds.indexOf(modelData.id) >= 0
        onHovered: function(hovering) { if (hovering) panel.selectedIndex = index }
        onClicked: panel.toggleFavorite(modelData.id)
        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.space(6)
          spacing: Style.space(8)
          Text {
            text: appRow.selected ? "✓" : ""
            textFormat: Text.PlainText
            color: Commons.Color.foreground
            Layout.preferredWidth: Style.space(14)
          }
          Image {
            Layout.preferredWidth: Style.space(20)
            Layout.preferredHeight: Style.space(20)
            fillMode: Image.PreserveAspectFit
            source: {
              var icon = String(appRow.modelData.icon || "application-x-executable")
              return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon)
            }
          }
          Text {
            text: appRow.modelData.name || appRow.modelData.id
            textFormat: Text.PlainText
            color: Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
      }
      Text {
        anchors.centerIn: parent
        visible: panel.entries.length === 0
        text: "No apps found"
        textFormat: Text.PlainText
        color: Commons.Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
      }
    }
  }
}
