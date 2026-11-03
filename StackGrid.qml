import QtQuick
import QtQuick.Controls

Item {
  id: root
  property var entries: []
  property bool expanded: false
  property color foreground: "#f4f4f5"
  property color accent: "#b6c9e7"
  property int selectedIndex: entries.length ? 0 : -1
  readonly property int columns: Math.max(1, Math.floor(width / 104))
  signal openEntry(var entry)
  signal dragStarted()
  signal dragFinished(int action)
  signal filesDropped(var urls,string destination,bool copy)
  onEntriesChanged: selectedIndex = entries.length ? Math.min(Math.max(selectedIndex, 0), entries.length-1) : -1
  onSelectedIndexChanged: if (selectedIndex >= 0) grid.positionViewAtIndex(selectedIndex, GridView.Contain)
  focus: true
  Keys.onPressed: function(event) {
    var n = root.selectedIndex
    if (event.key === Qt.Key_Left) n--
    else if (event.key === Qt.Key_Right) n++
    else if (event.key === Qt.Key_Up) n -= root.columns
    else if (event.key === Qt.Key_Down) n += root.columns
    else if (event.key === Qt.Key_Home) n = 0
    else if (event.key === Qt.Key_End) n = root.entries.length-1
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (n >= 0 && n < root.entries.length) root.openEntry(root.entries[n])
      event.accepted = true; return
    } else return
    root.selectedIndex = Math.max(0, Math.min(root.entries.length-1, n))
    event.accepted = true
  }
  GridView {
    id: grid
    objectName: "stackGridView"
    anchors.fill: parent
    clip: true
    model: root.entries
    cellWidth: Math.floor(width/root.columns)
    cellHeight: 112
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: grid.contentHeight > grid.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
    delegate: Item {
      id: tile
      required property int index
      required property var modelData
      objectName: "gridEntry" + index
      width: grid.cellWidth; height: grid.cellHeight
      property bool animationReady: false
      property real appear: root.expanded && animationReady ? 1 : 0
      Component.onCompleted: Qt.callLater(function(){ tile.animationReady=true })
      opacity: appear
      scale: 0.72 + 0.28 * appear
      Behavior on appear { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
      Rectangle {
        anchors.fill: parent; anchors.margins: 4
        radius: 9
        color: root.selectedIndex === tile.index ? "#50676b73" : "transparent"
        border.color: root.selectedIndex === tile.index ? "#30ffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
      }
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter; y: 12
        width: 54; height: 54; radius: 11
        visible: !tile.modelData.iconSource
        color: tile.modelData.isDir ? "#527fa8" : "#d4d9e1"
        Text { anchors.centerIn: parent; text: tile.modelData.isDir ? "▰" : "▤"; color:"white"; font.pixelSize:32 }
      }
      Image {
        anchors.horizontalCenter: parent.horizontalCenter; y: 9
        width: 62; height: 62
        source: tile.modelData.iconSource || ""
        sourceSize.width: 124; sourceSize.height: 124
        fillMode: Image.PreserveAspectFit; asynchronous: source.toString().indexOf("image://") !== 0
      }
      Text {
        x: 7; y: 77; width: parent.width-14; height: 31
        text: tile.modelData.name; textFormat: Text.PlainText
        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        color: root.foreground; font.pixelSize: 12
      }
      MouseArea {
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons:Qt.NoButton
        onEntered: root.selectedIndex = tile.index
        onClicked: { root.forceActiveFocus(); root.openEntry(tile.modelData) }
      }
      FileDrag {
        anchors.fill:parent; objectName:"fileDrag"; entry:tile.modelData
        onClicked:{ root.forceActiveFocus(); root.openEntry(tile.modelData) }
        onStarted:root.dragStarted()
        onFinished:function(action){ root.dragFinished(action) }
      }
      FileDrop {
        anchors.fill:parent
        destination:tile.modelData.isDir ? tile.modelData.path : ""
        onFilesDropped:function(urls,destination,copy){ root.filesDropped(urls,destination,copy) }
        onSpringLoad:root.openEntry(tile.modelData)
      }
    }
  }
}
