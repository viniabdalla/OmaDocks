import QtQuick
import "DockModel.js" as DockModel

// Shortcut input stays local to its group. In particular, this is not a
// native file drag: releasing outside only changes a saved shortcut list.
Item {
  id: root
  property string appId: ""
  property string appName: ""
  property url iconSource: ""
  property Item groupItem: parent
  property var bar: null
  property int iconSize: 22
  property int dragThreshold: 8
  readonly property string tooltipText: DockModel.barTooltip(appName)
  readonly property bool tooltipHovered: visible && enabled && pointer.containsMouse && !pointer.dragging
  readonly property bool dragging: pointer.dragging
  readonly property bool removeArmed: dragging && pointer.outside
  signal activated(string id)
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
    anchors.centerIn: parent
    width: Math.min(root.width, root.iconSize + 8)
    height: width
    radius: 6
    color: root.removeArmed ? "#40ff6666" : (pointer.containsMouse ? "#18ffffff" : "transparent")
  }
  Image {
    anchors.centerIn: parent
    width: root.iconSize; height: width
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
    cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
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
      var point = root.mapToItem(root.groupItem, mouse.x, mouse.y)
      var releasedOutside = point.x < 0 || point.y < 0 || point.x >= root.groupItem.width || point.y >= root.groupItem.height
      dragging = false
      if (cancelled) return
      if (wasDragging) {
        if (releasedOutside) root.removeRequested(root.appId)
      } else if (mouse.button === Qt.LeftButton && containsMouse) root.activated(root.appId)
      else if (mouse.button === Qt.RightButton && containsMouse) root.secondaryClicked()
    }
    onCanceled: { cancelled = true; dragging = false; root.hideTooltip() }
    onWheel: function(wheel) { root.wheelMoved(wheel.angleDelta.y) }
  }
}
