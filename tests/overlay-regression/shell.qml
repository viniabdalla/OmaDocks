import QtQuick
import Quickshell
import Quickshell.Wayland
import "OMADOCKS_TEST_MODULE" as Oma

// Never map this window: exercise the real overlay without taking desktop input.
ShellRoot {
  QtObject { id: controller; property string wallpaperUrl: ""; property string transferMessage: ""; property int releases:0; property string openedPath:""; function openFile(path) { openedPath=path } }
  Oma.FolderStack {
    id: stack
    controller: controller
    visible: false
    implicitWidth: 900
    implicitHeight: 700
    onOutsideDismissed:controller.releases++
  }
  Timer {
    interval: 100; running: true
    onTriggered: {
      var failures=[]
      function check(value,message) { if(!value) failures.push(message) }
      function hasArea(region) {
        if(region.width>0 && region.height>0) return true
        for(var i=0;i<region.regions.length;i++) if(hasArea(region.regions[i])) return true
        return false
      }
      stack.opened=true
      stack.expanded=true
      stack.beginDrag()
      check(controller.releases===1,"starting a drag does not retract the dock")
      check(!hasArea(stack.mask),"overlay still intercepts the destination window")
      check(stack.WlrLayershell.keyboardFocus===WlrKeyboardFocus.None,"hidden drag overlay traps the keyboard")
      var contents=stack.contentItem.children
      var hidden=false
      for(var j=0;j<contents.length;j++) if(contents[j].objectName==="stackContents") hidden=contents[j].opacity===0
      check(hidden,"folder contents remain visible over the destination")
      check(!stack.visible,"test must never map an overlay on the desktop")
      stack.finishDrag(Qt.IgnoreAction)
      check(!stack.opened && !stack.outgoingDrag,"cancelled drag leaves the stack open")
      check(stack.WlrLayershell.keyboardFocus===WlrKeyboardFocus.None,"cancelled drag retains the keyboard")
      stack.opened=true; stack.expanded=true
      stack.close()
      check(stack.WlrLayershell.keyboardFocus===WlrKeyboardFocus.None,"closing animation retains the keyboard")
      check(controller.releases===2,"closing the stack does not retract the dock")
      stack.managing=true
      stack.currentPath="/tmp/nested # é"
      stack.expanded=true
      stack.openCurrentFolder()
      check(controller.openedPath===stack.currentPath,"open-folder action ignores the current nested folder")
      check(!stack.expanded,"open-folder action does not close the stack")
      check(controller.releases===3,"open-folder action does not retract the dock")
      console.log("QA_OVERLAY_RESULT",JSON.stringify(failures))
      Qt.quit()
    }
  }
}
