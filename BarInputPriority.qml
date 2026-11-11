import QtQuick

// Omarchy 4.5 puts a whole-widget drag MouseArea over each ModuleSlot.
// Raise only this slot's content so shortcut MouseAreas receive their own
// gestures. Unhandled padding still reaches Omarchy's normal widget mover.
// Restore the original stacking when this component is unloaded.
Item {
  id: root
  readonly property Item room: {
    var ancestor = root.parent
    while (ancestor) {
      if ("widgetRoom" in ancestor && "widgetHolder" in ancestor) return ancestor.widgetRoom
      ancestor = ancestor.parent
    }
    return null
  }
  Component.onDestruction: stacking.when = false
  Binding {
    id: stacking
    target: root.room
    property: "z"
    value: 1
    when: root.room !== null
    restoreMode: Binding.RestoreBindingOrValue
  }
}
