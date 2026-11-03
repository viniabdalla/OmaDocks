import QtQuick

DropArea {
  id:root
  property string destination: ""
  property color accent: "#b6c9e7"
  signal filesDropped(var urls,string destination,bool copy)
  signal springLoad()
  enabled:destination.length>0
  onEntered:function(drag){ if(!drag.hasUrls) drag.accepted=false; else springTimer.restart() }
  onExited:springTimer.stop()
  onDropped:function(drop){
    springTimer.stop()
    var copy=!!(drop.modifiers & Qt.ControlModifier)
    root.filesDropped(drop.urls,root.destination,copy)
    drop.accept(copy ? Qt.CopyAction : Qt.MoveAction)
  }
  Timer { id:springTimer; interval:600; onTriggered:root.springLoad() }
  Rectangle { anchors.fill:parent; anchors.margins:2; radius:8; color:"#256a8ac0"; border.color:root.accent; border.width:2; visible:root.containsDrag }
}
