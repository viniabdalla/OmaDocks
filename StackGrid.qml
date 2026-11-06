import QtQuick
import QtQuick.Controls

Item {
  id: root
  property var entries: []
  property bool expanded: false
  property color foreground: "#f4f4f5"
  property color accent: "#b6c9e7"
  property int selectedIndex: 0
  readonly property int columns: Math.max(1, Math.floor(width / 104))
  signal openEntry(var entry)
  signal openFolder()
  signal dragStarted()
  signal dragFinished(int action)
  signal filesDropped(var urls,string destination,bool copy)
  onEntriesChanged: selectedIndex = Math.min(Math.max(selectedIndex, 0), entries.length)
  onSelectedIndexChanged: if (selectedIndex >= 0) grid.positionViewAtIndex(selectedIndex, GridView.Contain)
  focus: true
  Keys.onPressed: function(event) {
    var n = root.selectedIndex
    if (event.key === Qt.Key_Left) n--
    else if (event.key === Qt.Key_Right) n++
    else if (event.key === Qt.Key_Up) n -= root.columns
    else if (event.key === Qt.Key_Down) n += root.columns
    else if (event.key === Qt.Key_Home) n = 0
    else if (event.key === Qt.Key_End) n = root.entries.length
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.activate(n)
      event.accepted = true; return
    } else return
    root.selectedIndex = Math.max(0, Math.min(root.entries.length, n))
    event.accepted = true
  }
  function activate(index) {
    if (index===entries.length) root.openFolder()
    else if (index>=0 && index<entries.length) root.openEntry(entries[index])
  }
  GridView {
    id: grid
    objectName: "stackGridView"
    anchors.fill: parent
    clip: true
    model: root.entries.concat([{name:"Open in File Manager",iconSource:"",isDir:false}])
    cellWidth: Math.floor(width/root.columns)
    cellHeight: 112
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: grid.contentHeight > grid.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
    delegate: Item {
      id: tile
      required property int index
      required property var modelData
      readonly property bool openAction: index === root.entries.length
      objectName: openAction ? "gridOpenFolder" : "gridEntry" + index
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
        visible: !tile.openAction && !tile.modelData.iconSource
        color: tile.modelData.isDir ? "#527fa8" : "#d4d9e1"
        Text { anchors.centerIn: parent; text: tile.modelData.isDir ? "▰" : "▤"; color:"white"; font.pixelSize:32 }
      }
      Image {
        anchors.horizontalCenter: parent.horizontalCenter; y: 9
        width: 62; height: 62
        visible: !tile.openAction
        source: tile.modelData.iconSource || ""
        sourceSize.width: 124; sourceSize.height: 124
        fillMode: Image.PreserveAspectFit; asynchronous: source.toString().indexOf("image://") !== 0
      }
      OpenFolderIcon {
        anchors.horizontalCenter:parent.horizontalCenter; y:12
        width:54; height:54; visible:tile.openAction; color:root.foreground
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
        acceptedButtons:tile.openAction ? Qt.LeftButton : Qt.NoButton
        onEntered: root.selectedIndex = tile.index
        onClicked: { root.forceActiveFocus(); root.activate(tile.index) }
      }
      FileDrag {
        anchors.fill:parent; objectName:"fileDrag"; entry:tile.modelData; enabled:!tile.openAction
        onClicked:{ root.forceActiveFocus(); root.activate(tile.index) }
        onStarted:root.dragStarted()
        onFinished:function(action){ root.dragFinished(action) }
      }
      FileDrop {
        anchors.fill:parent
        destination:!tile.openAction && tile.modelData.isDir ? tile.modelData.path : ""
        onFilesDropped:function(urls,destination,copy){ root.filesDropped(urls,destination,copy) }
        onSpringLoad:root.activate(tile.index)
      }
    }
  }
}
