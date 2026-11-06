import QtQuick
import QtQuick.Effects
import "StackModel.js" as StackModel

// Transparent fan: each card travels from the folder's tip to a curved arc.
Item {
  id: root
  property var entries: []
  property bool expanded: false
  property string edge: "bottom"
  property color foreground: "#f4f4f5"
  property color accent: "#b6c9e7"
  property real availableHeight: height
  property real originX: width / 2
  property real originY: height
  readonly property var layout: StackModel.fanLayout(entries.length, availableHeight)
  readonly property bool reversed: edge === "top"
  signal openEntry(var entry)
  signal openFolder()
  signal dragStarted()
  signal dragFinished(int action)
  signal filesDropped(var urls,string destination,bool copy)
  property bool animationReady: false
  property real progress: expanded && animationReady ? 1 : 0
  onEntriesChanged: { animationReady=false; Qt.callLater(function(){ root.animationReady=true }) }
  Component.onCompleted: Qt.callLater(function(){ root.animationReady=true })
  Behavior on progress { NumberAnimation { duration: root.expanded ? 420 : 180; easing.type: root.expanded ? Easing.OutBack : Easing.InCubic; easing.overshoot: 0.75 } }

  Repeater {
    model: root.layout.visibleCount
    Item {
      id: card
      required property int index
      readonly property bool openAction: index === root.layout.fileCount
      readonly property var entry: openAction ? ({name:"Open in File Manager",iconSource:""}) : root.entries[index]
      readonly property var pose: StackModel.fanPose(index, root.layout.visibleCount)
      readonly property bool iconOnLeft: root.edge === "left" || root.originX < 330
      readonly property real dx: root.edge === "left" ? 54+pose.x : (root.edge === "right" ? -54-pose.x : pose.x * (root.originX > root.width-300 ? -1 : 1))
      readonly property real dy: root.edge === "top" ? -pose.y : pose.y
      objectName: openAction ? "fanOpenFolder" : "fanEntry" + index
      width: Math.min(310, root.width - 120); height: 60
      x: StackModel.clamp(root.originX - (iconOnLeft ? 28 : width-28) + dx*root.progress,8,root.width-width-8)
      y: StackModel.clamp(root.originY - height/2 + dy*root.progress,8,root.height-height-8)
      opacity: Math.max(0, Math.min(1, root.progress * 2))
      scale: (0.4 + 0.6 * root.progress) * pose.scale * (hit.containsMouse ? 1.07 : 1)
      rotation: pose.rotation * root.progress
      transformOrigin: Item.Right
      z: root.layout.visibleCount - index
      Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

      Rectangle {
        x:card.iconOnLeft ? 70 : card.width-width-70
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(label.implicitWidth + 22, card.width - 82); height: 30
        radius: 9
        color: hit.containsMouse ? "#dd50545c" : "#bb202126"
        border.color: "#28ffffff"
        Behavior on color { ColorAnimation { duration: 110 } }
        Text {
          id: label
          anchors.fill: parent; anchors.leftMargin: 11; anchors.rightMargin: 11
          text: card.openAction ? "Open in File Manager" : card.entry.name
          textFormat: Text.PlainText; elide: Text.ElideMiddle
          verticalAlignment: Text.AlignVCenter
          color: root.foreground; font.pixelSize: 13
        }
      }
      Item {
        id: icon
        x:card.iconOnLeft ? 0 : card.width-width
        anchors.verticalCenter: parent.verticalCenter
        width: 56; height: 56
        layer.enabled: !card.openAction
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.7; shadowVerticalOffset: 5; shadowHorizontalOffset: 1 }
        Rectangle {
          anchors.fill: parent; anchors.margins: 3
          visible: !card.openAction && !card.entry.iconSource
          radius: 13; color: card.entry.isDir ? "#527fa8" : "#d4d9e1"
          Text { anchors.centerIn: parent; text: card.entry.isDir ? "▰" : "▤"; color: "white"; font.pixelSize: 32 }
        }
        Image {
          anchors.fill: parent
          source: card.entry.iconSource || ""
          sourceSize.width: 112; sourceSize.height: 112
          fillMode: Image.PreserveAspectFit; asynchronous: source.toString().indexOf("image://") !== 0
        }
      }
      OpenFolderIcon {
        x:card.iconOnLeft ? 0 : card.width-width
        anchors.verticalCenter:parent.verticalCenter
        width:56; height:56; visible:card.openAction
        color:root.foreground
      }
      MouseArea {
        id: hit
        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons:card.openAction ? Qt.LeftButton : Qt.NoButton
        onClicked: card.openAction ? root.openFolder() : root.openEntry(card.entry)
      }
      FileDrag {
        anchors.fill:parent; objectName:"fileDrag"
        enabled:!card.openAction; entry:card.entry
        onClicked:root.openEntry(card.entry)
        onStarted:root.dragStarted()
        onFinished:function(action){ root.dragFinished(action) }
      }
      FileDrop {
        anchors.fill:parent
        destination:!card.openAction && card.entry.isDir ? card.entry.path : ""
        onFilesDropped:function(urls,destination,copy){ root.filesDropped(urls,destination,copy) }
        onSpringLoad:root.openEntry(card.entry)
      }
    }
  }
}
