import QtQuick
import "StackModel.js" as StackModel

// Native Wayland drag: file managers receive a Move offer, terminals can
// consume its URI/plain-text path. Never delete a source on dragFinished:
// the receiving file manager performs the move itself.
Item {
  id:root
  required property var entry
  signal started()
  signal clicked()
  signal finished(int action)
  Drag.dragType: Drag.Automatic
  readonly property bool copyRequested: gesture.item ? !!(gesture.item.modifiers & Qt.ControlModifier) : false
  Drag.active: gesture.item ? gesture.item.dragging : false
  Drag.supportedActions: copyRequested ? Qt.CopyAction : (Qt.CopyAction | Qt.MoveAction)
  Drag.proposedAction: copyRequested ? Qt.CopyAction : Qt.MoveAction
  Drag.mimeData: ({"text/uri-list":(entry.url || StackModel.fileUrl(entry.path))+"\r\n", "text/plain":entry.path})
  Drag.imageSource: entry.iconSource || ""
  Drag.imageSourceSize: Qt.size(64,64)
  Drag.hotSpot.x:32; Drag.hotSpot.y:32
  Drag.onDragStarted:root.started()
  Drag.onDragFinished:function(action) {
    // Native Wayland drags consume the release outside the source window.
    // Recreate the local gesture before hiding: toggling enabled alone does
    // not clear DragHandler.active after a release consumed by native DnD.
    gesture.active=false
    gesture.active=true
    root.finished(action)
  }
  Loader {
    id:gesture
    anchors.fill:parent
    sourceComponent: Item {
      readonly property bool dragging:handler.active
      readonly property int modifiers:handler.centroid.modifiers
      DragHandler { id:handler; objectName:"fileDragHandler"; target:null; acceptedButtons:Qt.LeftButton }
      TapHandler { acceptedButtons:Qt.LeftButton; gesturePolicy:TapHandler.ReleaseWithinBounds; onTapped:root.clicked() }
    }
  }
}
