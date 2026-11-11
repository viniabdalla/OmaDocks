import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons
import "OMADOCKS_TEST_MODULE" as Dock
import "TOOLBAR_TEST_MODULE" as Toolbar

ShellRoot {
  id: root
  property var errors: []
  function check(ok, message) { if (!ok) errors.push(message) }
  // Compile all controller/surface wiring but never instantiate another dock.
  Component { id: controllerType; Dock.Dock {} }
  PanelWindow {
    id: focusWindow
    visible: false
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Dock.BarShortcut { id: focusShortcut; width:30; height:30 }
    Dock.BarDragFocus { id: dragFocus; anchorItem: focusShortcut; hostWindow: focusWindow }
  }
  FileView { id: state; path: Quickshell.env("OMADOCKS_STATE_DIR")+"/state.json" }
  Window {
    id: window
    width:400; height:180; visible:false
    color:"#181b20"
    Dock.BarWidget { id: favorites; x:24; y:100; width:implicitWidth; height:implicitHeight }
    Toolbar.BarWidget { id: toolbar; x:24; y:24; width:implicitWidth; height:implicitHeight }
    Dock.ToolbarWidget {
      id: vertical
      x:180; y:24; width:implicitWidth; height:implicitHeight
      bar: QtObject { property bool vertical:true; property int barSize:26 }
    }
    Timer {
      interval:1500; running:true
      onTriggered: {
        root.check(favorites.implicitWidth > Commons.Style.bar.statusSlot,"existing favorites widget has no padding for native movement")
        dragFocus.active=true
        root.check(focusWindow.WlrLayershell.keyboardFocus===WlrKeyboardFocus.Exclusive,"shortcut drag did not borrow keyboard focus")
        dragFocus.active=false
        root.check(focusWindow.WlrLayershell.keyboardFocus===WlrKeyboardFocus.None,"shortcut drag did not restore keyboard focus")
        root.check(toolbar.shortcuts.length===3,"initial Toolbar must contain exactly three icons")
        root.check(toolbar.shortcuts[0].name==="Terminal" && toolbar.shortcuts[1].name==="Herdr" && toolbar.shortcuts[2].name==="Navegador","initial shortcut order")
        root.check(toolbar.width===toolbar.slotSize*3+toolbar.padding*2,"compact Toolbar width")
        root.check(vertical.height===vertical.slotSize*3+vertical.padding*2,"vertical Toolbar height")
        // Exercise the widgets' actual file watchers with an intentionally
        // empty selection and then a saved selection on the next write.
        var next=JSON.parse(state.text()); next.toolbarPinned=[]
        state.setText(JSON.stringify(next))
        emptyCheck.start()
      }
    }
    Timer {
      id: emptyCheck; interval:400
      onTriggered: {
        root.check(toolbar.shortcuts.length===0 && toolbar.width===0,"empty Toolbar must take no space")
        var next=JSON.parse(state.text())
        next.toolbarPinned=["omadocks-default-terminal","omadocks-herdr","omadocks-default-browser"]
        state.setText(JSON.stringify(next))
        finishTimer.start()
      }
    }
    Timer {
      id: finishTimer; interval:400
      onTriggered: {
        root.check(toolbar.shortcuts.length===3,"file watcher did not restore Toolbar")
        root.finish()
      }
    }
  }
  function finish() {
    console.log("QA_TOOLBAR_RESULT "+JSON.stringify(errors))
    Qt.quit()
  }
}
