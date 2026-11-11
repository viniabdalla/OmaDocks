import QtQuick
import Quickshell
import Quickshell.Wayland

// Layer-shell bars normally do not receive keys. Borrow keyboard focus only
// during a shortcut drag so Escape can cancel it, then restore the host's
// original binding rather than leaving the bar keyboard-interactive.
Item {
  id: root
  property Item anchorItem: null
  property bool active: false
  property var hostWindow: anchorItem ? anchorItem.QsWindow.window : null
  readonly property var layerShell: active && hostWindow ? hostWindow.WlrLayershell : null
  onActiveChanged: if (active && anchorItem) anchorItem.forceActiveFocus()
  Component.onDestruction: focusBinding.when = false
  Binding {
    id: focusBinding
    target: root.layerShell
    property: "keyboardFocus"
    value: WlrKeyboardFocus.Exclusive
    when: root.active && root.layerShell !== null
    restoreMode: Binding.RestoreBindingOrValue
  }
}
