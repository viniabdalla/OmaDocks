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
  // Capture the rendered file item before the stack hides. Retain the grab
  // result until completion: its URL is backed by Qt's temporary image cache.
  property Item previewItem: parent
  property var preview: null
  property bool previewReady: false
  property int previewGeneration: 0
  property size previewSize: Qt.size(64,64)
  property point previewHotSpot: Qt.point(32,32)
  function preparePreview() {
    var generation=++previewGeneration
    preview=null; previewReady=false
    var item=previewItem
    if (!item || item.width<=0 || item.height<=0) { previewReady=true; return }
    var factor=Math.min(1,320/item.width,128/item.height)
    previewSize=Qt.size(Math.max(1,Math.round(item.width*factor)),Math.max(1,Math.round(item.height*factor)))
    var press=gesture.item.pressPosition
    var point=root.mapToItem(item,press.x,press.y)
    previewHotSpot=Qt.point(Math.max(0,Math.min(previewSize.width,point.x*previewSize.width/item.width)),
      Math.max(0,Math.min(previewSize.height,point.y*previewSize.height/item.height)))
    var accepted=item.grabToImage(function(result) {
      // Releasing the pointer while rendering must not start a delayed drag.
      if (generation!==previewGeneration || !gesture.item || !gesture.item.dragging) return
      preview=result
      previewReady=true
    },previewSize)
    if (!accepted) previewReady=true
  }
  function clearPreview() {
    previewGeneration++
    previewReady=false
    preview=null
  }
  Drag.dragType: Drag.Automatic
  readonly property bool copyRequested: gesture.item ? !!(gesture.item.modifiers & Qt.ControlModifier) : false
  Drag.active: previewReady && (gesture.item ? gesture.item.dragging : false)
  Drag.supportedActions: copyRequested ? Qt.CopyAction : (Qt.CopyAction | Qt.MoveAction)
  Drag.proposedAction: copyRequested ? Qt.CopyAction : Qt.MoveAction
  Drag.mimeData: ({"text/uri-list":(entry.url || StackModel.fileUrl(entry.path))+"\r\n", "text/plain":entry.path})
  Drag.imageSource: preview ? preview.url : (entry.iconSource || "")
  Drag.hotSpot.x:preview ? previewHotSpot.x : 32
  Drag.hotSpot.y:preview ? previewHotSpot.y : 32
  Drag.onDragStarted:root.started()
  Drag.onDragFinished:function(action) {
    // Native Wayland drags consume the release outside the source window.
    // Recreate the local gesture before hiding: toggling enabled alone does
    // not clear DragHandler.active after a release consumed by native DnD.
    gesture.active=false
    gesture.active=true
    clearPreview()
    root.finished(action)
  }
  Loader {
    id:gesture
    anchors.fill:parent
    sourceComponent: Item {
      readonly property bool dragging:handler.active
      readonly property int modifiers:handler.centroid.modifiers
      readonly property point pressPosition:handler.centroid.pressPosition
      DragHandler {
        id:handler; objectName:"fileDragHandler"; target:null; acceptedButtons:Qt.LeftButton
        onActiveChanged: active ? root.preparePreview() : root.clearPreview()
      }
      TapHandler { acceptedButtons:Qt.LeftButton; gesturePolicy:TapHandler.ReleaseWithinBounds; onTapped:root.clicked() }
    }
  }
}
