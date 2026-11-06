import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "StackModel.js" as StackModel

PanelWindow {
  id: root
  required property var controller
  property bool opened: false
  property bool expanded: false
  property bool managing: false
  property var folder: ({path:"",name:"",view:"fan",showHidden:false,sort:"name"})
  property string currentPath: folder.path
  property string currentView: folder.view
  property string edge: "bottom"
  property var sourceRect: ({x:0,y:0,width:48,height:48})
  property var history: []
  property var cascades: []
  property bool outgoingDrag: false
  signal dismissed()
  signal outsideDismissed()
  signal contextRequested(real x,real y)
  visible: opened
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top:true; bottom:true; left:true; right:true }
  WlrLayershell.namespace: "omadocks-stacks"
  WlrLayershell.layer: WlrLayer.Overlay
  // Never retain the keyboard for an invisible/closing overlay. Hyprland
  // handles Escape during native drags and cancels the Wayland offer itself.
  WlrLayershell.keyboardFocus: root.opened && root.expanded && !root.outgoingDrag
    ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  // The native drag owns the pointer grab. Keep its source surface mapped,
  // but expose every destination underneath, including the old panel area.
  mask:Region {
    width:root.outgoingDrag ? 0 : root.width
    height:root.outgoingDrag ? 0 : root.height
  }

  readonly property real availableFanHeight: edge==="top" ? height-sourceRect.y-sourceRect.height-65 :
    sourceRect.y-65
  readonly property var fanLayout: StackModel.fanLayout(directory.entries.length,availableFanHeight)
  readonly property real desiredHeight: currentView==="fan" ? Math.max(180,fanLayout.visibleCount*56+100) :
    (currentView==="list" ? Math.min(480,Math.max(118,directory.entries.length*34+84)) : Math.min(510,Math.max(240,Math.ceil(directory.entries.length/5)*112+58)))
  readonly property var placement: StackModel.stackRect(currentView==="fan" && edge!=="top" ? "bottom" : edge,sourceRect,
    {width:currentView==="fan" ? 430 : (currentView==="list" ? 290 : 580),height:desiredHeight},
    {width:width,height:height})

  function openFolder(value,anchor) {
    closeTimer.stop()
    folder=value
    currentPath=value.path
    currentView=value.view
    sourceRect=anchor
    history=[]; cascades=[]
    outgoingDrag=false; managing=false; expanded=false; opened=true
    Qt.callLater(function(){ root.expanded=true; root.focusView() })
  }
  function close() {
    expanded=false
    root.outsideDismissed()
    closeTimer.restart()
  }
  function beginDrag() {
    outgoingDrag=true
    root.outsideDismissed()
  }
  function finishDrag(action) {
    // Some file managers perform the transfer but finish the Wayland offer
    // with IgnoreAction. Closing the stack never changes the source file.
    // Unmap before restoring the input region; never flash the stack back
    // over the destination after dropping or pressing Escape.
    closeTimer.stop(); expanded=false; opened=false; cascades=[]
    outgoingDrag=false
    root.dismissed()
  }
  function snapshot() {
    var layers=[]
    for(var i=0;i<cascades.length;i++) {
      var c=cascadeRepeater.itemAt(i)
      if(c) layers.push({path:c.modelData.path,rect:c.rect,count:c.entryCount})
    }
    return {opened:opened,view:currentView,path:currentPath,loading:directory.loading,error:directory.error,
      count:directory.entries.length,rect:placement,source:sourceRect,cascades:layers,outgoingDrag:outgoingDrag}
  }
  function focusView() {
    if (currentView==="grid") grid.forceActiveFocus()
    else if (currentView==="list") list.forceActiveFocus()
    else keyFocus.forceActiveFocus()
  }
  function chooseView(view,save) {
    expanded=false; currentView=view; cascades=[]
    if (save!==false) controller.updateFolder(folder.path,{view:view})
    Qt.callLater(function(){ root.expanded=true; root.focusView() })
  }
  function updateOptions(patch) {
    folder=Object.assign({},folder,patch)
    controller.updateFolder(folder.path,patch)
    if(patch.view) chooseView(patch.view,false)
  }
  function activate(entry) {
    if (entry.isDir) {
      history=history.concat([currentPath]); currentPath=entry.path
      if (currentView==="fan") chooseView("grid",false)
      cascades=[]
    } else { controller.openFile(entry.path); close() }
  }
  function openCurrentFolder() {
    root.controller.openFile(root.currentPath)
    root.close()
  }
  function back() {
    if (!history.length) return
    var next=history.slice(); currentPath=next.pop(); history=next
    cascades=[]
  }
  function openCascade(depth,entry,rowY,parentRect) {
    if (cascades.length>depth && cascades[depth].path===entry.path) return
    var next=cascades.slice(0,depth)
    next.push({path:entry.path,name:entry.name,rowY:rowY,parent:parentRect})
    cascades=next
    Qt.callLater(function() { var c=cascadeRepeater.itemAt(depth); if(c) c.focusMenu() })
  }
  function trimCascades(depth) {
    if (cascades.length>depth) cascades=cascades.slice(0,depth)
  }
  Timer {
    id:closeTimer; interval:220
    onTriggered: { root.opened=false; root.cascades=[]; root.dismissed() }
  }
  FolderModel {
    id:directory
    active:root.opened && !root.managing && !root.outgoingDrag
    path:root.currentPath
    showHidden:root.folder.showHidden
    sort:root.folder.sort
  }
  MouseArea {
    anchors.fill:parent; acceptedButtons:Qt.LeftButton | Qt.RightButton
    onClicked:function(mouse){
      if(mouse.button===Qt.RightButton) root.contextRequested(mouse.x,mouse.y)
      else root.close()
    }
  }
  // This focus scope catches Escape even when a grid/list handles other keys.
  FocusScope {
    id:keyFocus
    objectName:"stackContents"
    opacity:root.outgoingDrag ? 0 : 1
    anchors.fill:parent; focus:true
    Keys.onEscapePressed: root.close()
    Keys.onPressed: function(event) {
      if (event.key===Qt.Key_Backspace) { root.back(); event.accepted=true }
    }

    Item {
      id:card
      visible:!root.managing
      x:root.placement.x; y:root.placement.y
      width:root.placement.width; height:root.placement.height
      property real reveal: root.expanded ? 1 : 0
      opacity: root.currentView==="fan" ? 1 : reveal
      transform: Scale {
        origin.x:root.sourceRect.x+root.sourceRect.width/2-card.x
        origin.y:root.sourceRect.y+root.sourceRect.height/2-card.y
        xScale:root.currentView==="grid" ? 0.12+0.88*card.reveal : 1
        yScale:root.currentView==="grid" ? 0.12+0.88*card.reveal : 1
      }
      Behavior on reveal { NumberAnimation { duration:root.currentView==="grid" ? 260 : 120; easing.type:Easing.OutCubic } }
      // Consume clicks in panel padding so only clicks outside dismiss it.
      MouseArea {
        anchors.fill:parent; visible:root.currentView!=="fan"
        acceptedButtons:Qt.LeftButton | Qt.RightButton
        onClicked:function(mouse){ if(mouse.button===Qt.RightButton) root.contextRequested(card.x+mouse.x,card.y+mouse.y) }
      }
      FileDrop {
        anchors.fill:parent; destination:root.currentPath
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy); directory.refresh() }
      }
      StackBackdrop {
        anchors.fill:parent
        visible:root.currentView!=="fan"
        wallpaper:root.controller.wallpaperUrl
        screenX:card.x; screenY:card.y; screenWidth:root.width; screenHeight:root.height
      }
      StackFan {
        id:fan
        x:-card.x; y:-card.y
        width:root.width; height:root.height
        originX:root.sourceRect.x+root.sourceRect.width/2
        originY:root.sourceRect.y+root.sourceRect.height/2
        availableHeight:root.availableFanHeight
        visible:root.currentView==="fan"
        edge:root.edge; entries:directory.entries; expanded:root.expanded && visible
        onOpenEntry: function(entry) { root.activate(entry) }
        onOpenFolder:root.openCurrentFolder()
        onDragStarted:root.beginDrag()
        onDragFinished:function(action){ root.finishDrag(action) }
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
      }
      StackGrid {
        id:grid
        x:12; y:28; width:parent.width-24; height:parent.height-66
        visible:root.currentView==="grid"
        entries:directory.entries; expanded:root.expanded && visible
        onOpenEntry: function(entry) { root.activate(entry) }
        onOpenFolder:root.openCurrentFolder()
        onDragStarted:root.beginDrag()
        onDragFinished:function(action){ root.finishDrag(action) }
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
        Keys.onEscapePressed:root.close()
      }
      Text {
        x:20; y:7; width:parent.width-40; height:18
        visible:root.currentView==="grid"
        text:root.currentPath.split("/").pop() || root.currentPath
        textFormat:Text.PlainText; color:"#d7d9de"; font.pixelSize:12; elide:Text.ElideMiddle
      }
      Text {
        x:18; y:parent.height-28
        visible:root.currentView==="grid"
        text:directory.entries.length+" items"; color:"#9a9da6"; font.pixelSize:11
      }
      StackList {
        id:list
        y:0; width:parent.width; height:parent.height
        visible:root.currentView==="list"
        entries:directory.entries
        title:root.currentPath.split("/").pop() || root.currentPath
        expanded:root.expanded && visible
        loading:directory.loading; error:directory.error
        onOpenEntry: function(entry) { root.activate(entry) }
        onOpenFolder:root.openCurrentFolder()
        onHoverFolder: function(entry,rowY) { root.openCascade(0,entry,rowY,{x:card.x,y:card.y,width:card.width,height:card.height}) }
        onHoverFile:root.trimCascades(0)
        onGoBack:root.back()
        onDragStarted:root.beginDrag()
        onDragFinished:function(action){ root.finishDrag(action) }
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
        Keys.onEscapePressed:root.close()
      }
      Text {
        anchors.centerIn:parent; width:parent.width-40
        visible:root.currentView!=="list" && (directory.loading || directory.error.length>0 || directory.entries.length===0)
        text:directory.loading ? "Loading…" : (directory.error || "This folder is empty")
        textFormat:Text.PlainText; color:"#eeeeef"; font.pixelSize:14
        wrapMode:Text.Wrap; horizontalAlignment:Text.AlignHCenter
        style:Text.Outline; styleColor:"#b0101115"
      }
      Text {
        x:16; y:parent.height-28; width:parent.width-32
        visible:root.controller.transferMessage.length>0
        text:root.controller.transferMessage; textFormat:Text.PlainText
        elide:Text.ElideRight; color:"#dce6f7"; font.pixelSize:11
      }
    }

    Repeater {
      id:cascadeRepeater
      model:root.currentView==="list" && !root.managing ? root.cascades : []
      Item {
        id:submenu
        required property int index
        required property var modelData
        readonly property int entryCount:childDirectory.entries.length
        readonly property var rect: StackModel.cascadeRect(modelData.parent,modelData.rowY,
          {width:290,height:Math.min(460,Math.max(118,childDirectory.entries.length*34+84))},
          {width:root.width,height:root.height})
        x:rect.x; y:rect.y; width:rect.width; height:rect.height
        function focusMenu() { childList.forceActiveFocus() }
        FolderModel {
          id:childDirectory
          path:submenu.modelData.path; active:root.opened && !root.outgoingDrag
          showHidden:root.folder.showHidden; sort:root.folder.sort
        }
        MouseArea { anchors.fill:parent }
        StackBackdrop { anchors.fill:parent; wallpaper:root.controller.wallpaperUrl; screenX:submenu.x; screenY:submenu.y; screenWidth:root.width; screenHeight:root.height }
        StackList {
          id:childList
          anchors.fill:parent; title:submenu.modelData.name
          entries:childDirectory.entries; loading:childDirectory.loading; error:childDirectory.error
          expanded:root.expanded
          onOpenEntry: function(entry) { root.controller.openFile(entry.path); root.close() }
          onOpenFolder: { root.controller.openFile(submenu.modelData.path); root.close() }
          onHoverFolder: function(entry,rowY) { root.openCascade(submenu.index+1,entry,rowY,submenu.rect) }
          onHoverFile:root.trimCascades(submenu.index+1)
          onGoBack: { root.trimCascades(submenu.index); if(submenu.index===0) list.forceActiveFocus(); else { var previous=cascadeRepeater.itemAt(submenu.index-1); if(previous) previous.focusMenu() } }
          Keys.onEscapePressed:root.close()
          onDragStarted:root.beginDrag()
          onDragFinished:function(action){ root.finishDrag(action) }
          onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
        }
      }
    }
  }
}
