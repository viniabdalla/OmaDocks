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
  Drag.active: handler.active
  Drag.supportedActions: handler.centroid.modifiers & Qt.ControlModifier ? Qt.CopyAction : (Qt.CopyAction | Qt.MoveAction)
  Drag.proposedAction: handler.centroid.modifiers & Qt.ControlModifier ? Qt.CopyAction : Qt.MoveAction
  Drag.mimeData: ({"text/uri-list":(entry.url || StackModel.fileUrl(entry.path))+"\r\n", "text/plain":entry.path})
  Drag.imageSource: entry.iconSource || ""
  Drag.imageSourceSize: Qt.size(64,64)
  Drag.hotSpot.x:32; Drag.hotSpot.y:32
  Drag.onDragStarted:root.started()
  Drag.onDragFinished:function(action) { root.finished(action) }
  DragHandler { id:handler; target:null; acceptedButtons:Qt.LeftButton }
  TapHandler { acceptedButtons:Qt.LeftButton; gesturePolicy:TapHandler.ReleaseWithinBounds; onTapped:root.clicked() }
}
