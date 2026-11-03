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
  visible: opened
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top:true; bottom:true; left:true; right:true }
  WlrLayershell.namespace: "omadocks-stacks"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: outgoingDrag ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
  // During native drags keep only the panels in the input region, exposing
  // file managers and terminals underneath the rest of this screen.
  mask:Region {
    width:root.outgoingDrag ? 0 : root.width
    height:root.outgoingDrag ? 0 : root.height
    Region {
      x:root.dragBounds.x; y:root.dragBounds.y
      width:root.outgoingDrag ? root.dragBounds.width : 0
      height:root.outgoingDrag ? root.dragBounds.height : 0
    }
  }
  readonly property var dragBounds: {
    var x=card.x,y=card.y,right=card.x+card.width,bottom=card.y+card.height
    if(currentView==="fan") { x=Math.min(x,sourceRect.x-330); right=Math.max(right,sourceRect.x+180) }
    for(var i=0;i<cascades.length;i++) {
      var child=cascadeRepeater.itemAt(i)
      if(child) { x=Math.min(x,child.x); y=Math.min(y,child.y); right=Math.max(right,child.x+child.width); bottom=Math.max(bottom,child.y+child.height) }
    }
    return {x:Math.max(0,x),y:Math.max(0,y),width:right-Math.max(0,x),height:bottom-Math.max(0,y)}
  }

  readonly property real availableFanHeight: edge==="top" ? height-sourceRect.y-sourceRect.height-65 :
    (edge==="bottom" ? sourceRect.y-65 : height-160)
  readonly property var fanLayout: StackModel.fanLayout(directory.entries.length,availableFanHeight)
  readonly property real desiredHeight: currentView==="fan" ? Math.max(180,fanLayout.visibleCount*56+100) :
    (currentView==="list" ? Math.min(520,Math.max(162,directory.entries.length*34+128)) : Math.min(540,Math.max(280,Math.ceil(directory.entries.length/5)*112+100)))
  readonly property var placement: StackModel.stackRect(edge,sourceRect,
    {width:currentView==="fan" ? 430 : (currentView==="list" ? 290 : 580),height:desiredHeight},
    {width:width,height:height})

  function openFolder(value,anchor) {
    closeTimer.stop()
    folder=value
    currentPath=value.path
    currentView=value.view
    sourceRect=anchor
    history=[]; cascades=[]
    managing=false; expanded=false; opened=true
    Qt.callLater(function(){ root.expanded=true; root.focusView() })
  }
  function close() { expanded=false; closeTimer.restart() }
  function finishDrag(action) {
    outgoingDrag=false
    if(action!==Qt.IgnoreAction) { root.outsideDismissed(); root.close() }
    else { directory.refresh(); root.focusView() }
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
  function activate(entry) {
    if (entry.isDir) {
      history=history.concat([currentPath]); currentPath=entry.path
      if (currentView==="fan") chooseView("grid",false)
      cascades=[]
    } else { controller.openFile(entry.path); close() }
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
  MouseArea { anchors.fill:parent; onClicked: { root.outsideDismissed(); root.close() } }
  // This focus scope catches Escape even when a grid/list handles other keys.
  FocusScope {
    id:keyFocus
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
      MouseArea { anchors.fill:parent }
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
      // Shared compact toolbar; Fan leaves the files floating freely below it.
      Rectangle {
        id:toolbar
        width:parent.width; height:44
        radius:root.currentView==="fan" ? 12 : 0
        color:root.currentView==="fan" ? "#ed24262c" : "transparent"
        Row {
          x:8; anchors.verticalCenter:parent.verticalCenter; spacing:4
          Repeater {
            model:[{name:"‹",view:"back"},{name:"Fan",view:"fan"},{name:"Grid",view:"grid"},{name:"List",view:"list"}]
            Rectangle {
              id:tool
              required property var modelData
              width:modelData.view==="back" ? 26 : 48; height:28; radius:6
              visible:modelData.view!=="back" || root.history.length>0
              color:root.currentView===modelData.view ? "#605f6978" : (toolHit.containsMouse ? "#305f6978" : "transparent")
              Text { anchors.centerIn:parent; text:tool.modelData.name; color:"#f4f4f5"; font.pixelSize:12 }
              MouseArea { id:toolHit; anchors.fill:parent; hoverEnabled:true; onClicked:tool.modelData.view==="back" ? root.back() : root.chooseView(tool.modelData.view) }
            }
          }
        }
        Row {
          anchors.right:parent.right; anchors.rightMargin:6; anchors.verticalCenter:parent.verticalCenter; spacing:4
          Repeater {
            model:["↗","×"]
            Rectangle {
              id:action
              required property string modelData
              width:28; height:28; radius:6
              color:actionHit.containsMouse ? "#405f6978" : "transparent"
              Text { anchors.centerIn:parent; text:action.modelData; color:"white"; font.pixelSize:16 }
              MouseArea {
                id:actionHit; anchors.fill:parent; hoverEnabled:true
                onClicked: {
                  if (action.modelData==="×") root.close()
                  else { root.controller.openFile(root.currentPath); root.close() }
                }
              }
            }
          }
        }
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
        onShowAll:root.chooseView("grid",false)
        onDragStarted:root.outgoingDrag=true
        onDragFinished:function(action){ root.finishDrag(action) }
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
      }
      StackGrid {
        id:grid
        x:12; y:66; width:parent.width-24; height:parent.height-104
        visible:root.currentView==="grid"
        entries:directory.entries; expanded:root.expanded && visible
        onOpenEntry: function(entry) { root.activate(entry) }
        onDragStarted:root.outgoingDrag=true
        onDragFinished:function(action){ root.finishDrag(action) }
        onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
        Keys.onEscapePressed:root.close()
      }
      Text {
        x:20; y:46; width:parent.width-40; height:18
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
        y:44; width:parent.width; height:parent.height-44
        visible:root.currentView==="list"
        entries:directory.entries
        title:root.currentPath.split("/").pop() || root.currentPath
        expanded:root.expanded && visible
        loading:directory.loading; error:directory.error
        onOpenEntry: function(entry) { root.activate(entry) }
        onOpenFolder: { root.controller.openFile(root.currentPath); root.close() }
        onHoverFolder: function(entry,rowY) { root.openCascade(0,entry,44+rowY,{x:card.x,y:card.y,width:card.width,height:card.height}) }
        onHoverFile:root.trimCascades(0)
        onGoBack:root.back()
        onDragStarted:root.outgoingDrag=true
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
          onDragStarted:root.outgoingDrag=true
          onDragFinished:function(action){ root.finishDrag(action) }
          onFilesDropped:function(urls,destination,copy){ root.controller.moveUrls(urls,destination,copy) }
        }
      }
    }
  }
}
