import QtQuick
import "DockModel.js" as DockModel

// Moving a shortcut never removes it. Pointer movement is tracked only
// to suppress accidental clicks and permit reordering inside its own group.
// Adding/removing shortcuts belongs to explicit menus.
Item {
  id: root
  property string appId: ""
  property string appName: ""
  property url iconSource: ""
  property Item groupItem: parent
  property var bar: null
  property int iconSize: 22
  property bool iconBackground: false
  // Keep artwork inside the bar's inner surface in either orientation.
  readonly property int visualIconSize: Math.max(0, Math.min(iconSize, Math.floor(width) - 8, Math.floor(height) - 8))
  property int dragThreshold: 8
  readonly property string tooltipText: DockModel.barTooltip(appName)
  readonly property bool tooltipHovered: visible && enabled && pointer.containsMouse && !pointer.dragging
  readonly property bool dragging: pointer.dragging
  readonly property bool removeArmed: false
  signal activated(string id)
  signal reorderRequested(string id, real x, real y)
  signal removeRequested(string id)
  signal secondaryClicked()
  signal wheelMoved(int delta)
  implicitWidth: 32
  implicitHeight: 36

  function hideTooltip() { if (bar && bar.hideTooltip) bar.hideTooltip(root) }
  Keys.onEscapePressed: function(event) {
    if (pointer.pressed) {
      pointer.cancelled = true
      pointer.dragging = false
      root.hideTooltip()
      event.accepted = true
    }
  }
  onVisibleChanged: if (!visible) hideTooltip()
  Component.onDestruction: hideTooltip()

  Rectangle {
    objectName: "shortcutHighlight"
    anchors.centerIn: parent
    width: Math.max(0, Math.min(root.width, root.height) - 4)
    height: width
    radius: 6
    color: root.removeArmed ? "#40ff6666" : (pointer.containsMouse ? "#18ffffff" : "transparent")
  }
  Rectangle {
    objectName: "shortcutBackground"
    anchors.centerIn: parent
    width: root.visualIconSize; height: width
    radius: Math.min(3, width / 4)
    visible: root.iconBackground
    color: "#101b2b"
  }
  Image {
    objectName: "shortcutIcon"
    anchors.centerIn: parent
    width: root.visualIconSize; height: width
    fillMode: Image.PreserveAspectFit
    source: root.iconSource
    sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
    opacity: root.removeArmed ? 0.4 : 1
  }
  MouseArea {
    id: pointer
    objectName: "shortcutPointer"
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    property point pressPoint: Qt.point(0, 0)
    property bool dragging: false
    property bool cancelled: false
    property bool outside: false
    onEntered: if (root.bar && root.bar.showTooltip) root.bar.showTooltip(root, root.tooltipText)
    onExited: root.hideTooltip()
    onPressed: function(mouse) {
      pressPoint = Qt.point(mouse.x, mouse.y)
      dragging = false; cancelled = false; outside = false
      root.forceActiveFocus()
    }
    onPositionChanged: function(mouse) {
      if (!pressed || !(mouse.buttons & Qt.LeftButton) || cancelled) return
      if (Math.abs(mouse.x - pressPoint.x) + Math.abs(mouse.y - pressPoint.y) >= root.dragThreshold) dragging = true
      var point = root.mapToItem(root.groupItem, mouse.x, mouse.y)
      outside = point.x < 0 || point.y < 0 || point.x >= root.groupItem.width || point.y >= root.groupItem.height
      if (dragging) root.hideTooltip()
    }
    onReleased: function(mouse) {
      var wasDragging = dragging
      dragging = false
      if (cancelled) return
      if (wasDragging) {
        var point = root.mapToItem(root.groupItem, mouse.x, mouse.y)
        if (point.x >= 0 && point.y >= 0 && point.x < root.groupItem.width && point.y < root.groupItem.height)
          root.reorderRequested(root.appId, point.x, point.y)
        return
      }
      if (mouse.button === Qt.LeftButton && containsMouse) root.activated(root.appId)
      else if (mouse.button === Qt.RightButton && containsMouse) root.secondaryClicked()
    }
    onCanceled: { cancelled = true; dragging = false; root.hideTooltip() }
    onWheel: function(wheel) { root.wheelMoved(wheel.angleDelta.y) }
  }
}
