import QtQuick
import QtQuick.Controls

Item {
  id: root
  property var entries: []
  property string title: ""
  property bool expanded: false
  property color foreground: "#f4f4f5"
  property int selectedIndex: -1
  property bool loading: false
  property string error: ""
  signal openEntry(var entry)
  signal hoverFolder(var entry, real rowY)
  signal hoverFile()
  signal openFolder()
  signal goBack()
  signal dragStarted()
  signal dragFinished(int action)
  signal filesDropped(var urls,string destination,bool copy)
  focus: true
  property bool animationReady: false
  property real progress: expanded && animationReady ? 1 : 0
  Component.onCompleted: Qt.callLater(function(){ root.animationReady=true })
  Behavior on progress { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  opacity: progress
  transform: Translate { y: (1-root.progress)*14 }
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Up) selectedIndex = Math.max(0,selectedIndex-1)
    else if (event.key === Qt.Key_Down) selectedIndex = Math.min(entries.length-1,selectedIndex+1)
    else if (event.key === Qt.Key_Home) selectedIndex = 0
    else if (event.key === Qt.Key_End) selectedIndex = entries.length-1
    else if (event.key === Qt.Key_Left) root.goBack()
    else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Right) && selectedIndex>=0) {
      var entry=entries[selectedIndex]
      if (entry.isDir) root.hoverFolder(entry,44+selectedIndex*34-list.contentY)
      else if (event.key !== Qt.Key_Right) root.openEntry(entry)
    } else return
    if (selectedIndex>=0) list.positionViewAtIndex(selectedIndex,ListView.Contain)
    event.accepted=true
  }
  Text {
    x: 12; y: 10; width: parent.width-24; height: 24
    text: root.title; textFormat: Text.PlainText; elide: Text.ElideMiddle
    color: root.foreground; opacity: 0.65; font.pixelSize: 12; font.bold: true
  }
  Rectangle { x: 8; y: 37; width: parent.width-16; height: 1; color: "#20ffffff" }
  ListView {
    id: list
    objectName: "stackListView"
    x: 5; y: 44; width: parent.width-10; height: Math.max(0,parent.height-84)
    clip: true; model: root.entries
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}
    delegate: Rectangle {
      id: row
      required property int index
      required property var modelData
      objectName: "listEntry"+index
      width: list.width; height: 34; radius: 6
      color: root.selectedIndex===index ? "#58686c73" : "transparent"
      Behavior on color { ColorAnimation { duration: 80 } }
      Rectangle { x: 8; y: 7; width: 20; height: 20; radius: 4; visible: !row.modelData.iconSource; color: row.modelData.isDir ? "#6498c4" : "#c3c8d0" }
      Image { x: 6; y: 5; width: 24; height: 24; source: row.modelData.iconSource || ""; sourceSize.width:48; sourceSize.height:48; fillMode: Image.PreserveAspectFit }
      Text { x: 38; width: parent.width-65; height: parent.height; verticalAlignment: Text.AlignVCenter; text: row.modelData.name; textFormat: Text.PlainText; elide: Text.ElideMiddle; color: root.foreground; font.pixelSize: 13 }
      Text { anchors.right:parent.right; anchors.rightMargin:10; anchors.verticalCenter:parent.verticalCenter; visible:row.modelData.isDir; text:"›"; font.pixelSize:22; color: root.foreground; opacity:0.65 }
      Timer {
        id: hoverDelay
        interval: 240
        onTriggered: if (hit.containsMouse && row.modelData.isDir) root.hoverFolder(row.modelData,44+row.y-list.contentY)
      }
      MouseArea {
        id: hit
        anchors.fill: parent; hoverEnabled:true; cursorShape: Qt.PointingHandCursor
        acceptedButtons:Qt.NoButton
        onEntered: {
          root.selectedIndex=row.index
          if (row.modelData.isDir) hoverDelay.restart()
          else root.hoverFile()
        }
        onExited: hoverDelay.stop()
        onClicked: row.modelData.isDir ? root.hoverFolder(row.modelData,44+row.y-list.contentY) : root.openEntry(row.modelData)
      }
      FileDrag {
        anchors.fill:parent; objectName:"fileDrag"; entry:row.modelData
        onClicked:row.modelData.isDir ? root.hoverFolder(row.modelData,44+row.y-list.contentY) : root.openEntry(row.modelData)
        onStarted:root.dragStarted()
        onFinished:function(action){ root.dragFinished(action) }
      }
      FileDrop {
        anchors.fill:parent
        destination:row.modelData.isDir ? row.modelData.path : ""
        onFilesDropped:function(urls,destination,copy){ root.filesDropped(urls,destination,copy) }
        onSpringLoad:root.hoverFolder(row.modelData,44+row.y-list.contentY)
      }
    }
  }
  Text {
    anchors.centerIn: list; width: list.width-20
    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
    visible: root.loading || root.error.length>0 || root.entries.length===0
    text: root.loading ? "Loading…" : (root.error || "This folder is empty")
    color: root.foreground; opacity: 0.65; font.pixelSize: 13
  }
  Rectangle { x: 8; y: parent.height-36; width: parent.width-16; height: 1; color: "#20ffffff" }
  Rectangle {
    x: 5; y: parent.height-32; width: parent.width-10; height: 28; radius: 5
    color: openHit.containsMouse ? "#30676b73" : "transparent"
    Text { x:10; anchors.verticalCenter:parent.verticalCenter; text:"Open in file manager  ↗"; color:root.foreground; font.pixelSize:12; opacity:0.8 }
    MouseArea { id:openHit; anchors.fill:parent; hoverEnabled:true; onClicked: root.openFolder() }
  }
}
