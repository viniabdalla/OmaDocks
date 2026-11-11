import QtQuick
import QtTest
import ".."

TestCase {
  id: test
  name: "BarShortcuts"
  when: windowShown
  width: 520; height: 320
  visible: true
  Component { id: shortcutComponent; BarShortcut {} }
  Component {
    id: slotComponent
    Item {
      width:180; height:40
      property Item widgetRoom: room
      property Item widgetHolder: room
      property alias inputPriority: priority
      property alias shortcut: shortcut
      property int widgetMoves: 0
      Item {
        id: room; anchors.fill:parent
        BarInputPriority { id: priority }
        BarShortcut { id: shortcut; width:32; height:36; groupItem:room; appId:"editor" }
      }
      // Same stacking/input boundary as Omarchy's whole-widget mover.
      MouseArea { anchors.fill:parent; onClicked: parent.widgetMoves++ }
    }
  }
  function test_shortcut_input_precedes_widget_mover_and_padding_still_moves_group() {
    var slot=createTemporaryObject(slotComponent,test,{x:100,y:80})
    activated.target=slot.shortcut; removed.target=slot.shortcut
    mouseClick(slot.shortcut,16,18)
    compare(activated.count,1); compare(slot.widgetMoves,0)
    mousePress(slot.shortcut,16,18); mouseMove(slot.shortcut,16,90); mouseRelease(slot.shortcut,16,90)
    compare(removed.count,1); compare(slot.widgetMoves,0)
    mouseClick(slot,150,20); compare(slot.widgetMoves,1)
    slot.inputPriority.destroy()
    wait(0)
    compare(slot.widgetRoom.z,0)
  }
  SignalSpy { id: removed; signalName: "removeRequested" }
  SignalSpy { id: activated; signalName: "activated" }
  Item { id: group; x:100; y:80; width:120; height:36 }
  function init() { removed.clear(); activated.clear() }
  function cleanup() { removed.target=null; activated.target=null }
  function makeShortcut() {
    var item=createTemporaryObject(shortcutComponent,group,{width:32,height:36,groupItem:group,appId:"editor",appName:"Editor",iconSource:""})
    removed.target=item; activated.target=item
    return item
  }
  function test_hover_exposes_plain_tooltip_state() {
    var item=makeShortcut()
    item.appName='<img src="https://example.invalid/"> & Editor'
    mouseMove(item,16,18)
    compare(item.tooltipHovered,true)
    verify(item.tooltipText.indexOf("<") < 0)
    mouseMove(test,450,250)
    compare(item.tooltipHovered,false)
  }
  function test_click_launches_without_removing() {
    var item=makeShortcut()
    mouseClick(item,16,18)
    compare(activated.count,1); compare(removed.count,0)
  }
  function test_release_outside_removes_once_without_launching() {
    var item=makeShortcut()
    mousePress(item,16,18); mouseMove(item,16,90); mouseRelease(item,16,90)
    compare(removed.count,1); compare(removed.signalArguments[0][0],"editor"); compare(activated.count,0)
  }
  function test_inside_and_returned_drag_keep_shortcut() {
    var item=makeShortcut()
    mousePress(item,16,18); mouseMove(item,65,18); mouseRelease(item,65,18)
    compare(removed.count,0); compare(activated.count,0)
    mousePress(item,16,18); mouseMove(item,16,90); mouseMove(item,16,18); mouseRelease(item,16,18)
    compare(removed.count,0); compare(activated.count,0)
  }
  function test_escape_cancels_outside_drag() {
    var item=makeShortcut()
    mousePress(item,16,18); mouseMove(item,16,90)
    keyClick(Qt.Key_Escape); mouseRelease(item,16,90)
    compare(removed.count,0); compare(activated.count,0)
    mouseClick(item,16,18); compare(activated.count,1)
  }
  function test_lost_pointer_cancels() {
    var item=makeShortcut()
    mousePress(item,16,18); mouseMove(item,16,90)
    item.enabled=false
    item.enabled=true
    mouseRelease(item,16,90)
    compare(removed.count,0); compare(activated.count,0)
  }
}
