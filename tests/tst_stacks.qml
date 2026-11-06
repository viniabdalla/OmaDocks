import QtQuick
import QtTest
import ".."

TestCase {
  name: "FolderViews"
  when: windowShown
  visible: true
  width: 900; height: 700
  property var fixtures: [
    {name:"Documents",path:"/tmp/Documents",isDir:true,iconSource:""},
    {name:"Report.pdf",path:"/tmp/Report.pdf",isDir:false,iconSource:""}
  ]
  Component { id: fanComponent; StackFan {} }
  Component { id: gridComponent; StackGrid {} }
  Component { id: listComponent; StackList {} }
  Component { id: fileDragComponent; FileDrag {} }
  SignalSpy { id: activation; signalName: "openEntry" }
  SignalSpy { id: overflow; signalName: "openFolder" }
  SignalSpy { id: navigation; signalName: "hoverFolder" }

  function cleanup() { mouseMove(this,width-1,height-1); activation.target=null; overflow.target=null; navigation.target=null; activation.clear(); overflow.clear(); navigation.clear() }
  function test_fan_always_ends_with_open_folder() {
    for (var count of [0,2,30]) {
      var entries=[]
      for(var i=0;i<count;i++) entries.push({name:"File "+i,path:"/tmp/"+i,isDir:false})
      var fan=createTemporaryObject(fanComponent,this,{width:420,height:500,entries:entries,expanded:true})
      overflow.target=fan; overflow.clear()
      wait(500)
      var action=findChild(fan,"fanOpenFolder")
      verify(action)
      compare(action.index,fan.layout.visibleCount-1)
      verify(!findChild(action,"fileDrag").enabled)
      mouseClick(action,action.width/2,action.height/2)
      compare(overflow.count,1)
      fan.destroy(); overflow.target=null
    }
  }
  function test_grid_last_cell_opens_folder_by_click_and_keyboard() {
    for (var entries of [[],fixtures]) {
      var grid=createTemporaryObject(gridComponent,this,{width:600,height:400,entries:entries,expanded:true})
      overflow.target=grid; overflow.clear()
      wait(350)
      var action=findChild(grid,"gridOpenFolder")
      verify(action)
      compare(action.index,entries.length)
      verify(!findChild(action,"fileDrag").enabled)
      mouseClick(action,action.width/2,action.height/2)
      compare(overflow.count,1)
      mouseMove(this,width-1,height-1)
      grid.forceActiveFocus(); keyClick(Qt.Key_End); keyClick(Qt.Key_Return)
      compare(grid.selectedIndex,entries.length)
      compare(overflow.count,2)
      grid.destroy(); overflow.target=null
    }
  }
  function test_new_fan_and_grid_animate_instead_of_appearing_finished() {
    var fan=createTemporaryObject(fanComponent,this,{width:420,height:500,entries:fixtures,expanded:true})
    compare(fan.progress,0)
    var grid=createTemporaryObject(gridComponent,this,{width:600,height:400,entries:fixtures,expanded:true})
    var tile=findChild(grid,"gridEntry0")
    verify(tile)
    verify(tile.opacity<1)
    wait(500)
    compare(fan.progress,1)
    compare(tile.opacity,1)
  }
  function test_grid_offers_native_file_drag_with_copy_and_move_actions() {
    var grid=createTemporaryObject(gridComponent,this,{width:600,height:400,entries:fixtures,expanded:true})
    var tile=findChild(grid,"gridEntry1")
    var drag=findChild(tile,"fileDrag")
    verify(drag)
    compare(drag.Drag.mimeData["text/uri-list"],"file:///tmp/Report.pdf\r\n")
    compare(drag.Drag.mimeData["text/plain"],"/tmp/Report.pdf")
    verify(drag.Drag.supportedActions & Qt.MoveAction)
    verify(drag.Drag.supportedActions & Qt.CopyAction)
    compare(drag.Drag.proposedAction,Qt.MoveAction)
  }
  function test_ctrl_held_at_drag_start_proposes_copy() {
    var drag=createTemporaryObject(fileDragComponent,this,{width:80,height:80,entry:fixtures[1]})
    mousePress(drag,30,30,Qt.LeftButton,Qt.ControlModifier)
    compare(drag.Drag.proposedAction,Qt.CopyAction)
    compare(drag.Drag.supportedActions,Qt.CopyAction)
    mouseRelease(drag,30,30,Qt.LeftButton,Qt.ControlModifier)
  }
  function test_native_completion_releases_pointer_for_the_next_drag() {
    var drag=createTemporaryObject(fileDragComponent,this,{width:100,height:100,entry:fixtures[1]})
    // Exercise real pointer activation, then deliver the completion callback
    // independently of the offscreen platform's native drag implementation.
    drag.Drag.dragType=Drag.Internal
    var handler=findChild(drag,"fileDragHandler")
    mousePress(drag,20,30)
    mouseMove(drag,70,30)
    compare(handler.active,true)
    tryVerify(function(){ return drag.Drag.active })
    drag.Drag.dragFinished(Qt.IgnoreAction)
    tryVerify(function(){ var h=findChild(drag,"fileDragHandler"); return h && !h.active })
    mouseRelease(drag,70,30)
    handler=findChild(drag,"fileDragHandler")
    mousePress(drag,20,30)
    mouseMove(drag,70,30)
    compare(handler.active,true)
    tryVerify(function(){ return drag.Drag.active })
    drag.Drag.dragFinished(Qt.CopyAction)
    tryVerify(function(){ var h=findChild(drag,"fileDragHandler"); return h && !h.active })
    mouseRelease(drag,70,30)
  }
  function test_drag_preview_captures_each_view_even_without_an_icon() {
    var cases=[{component:fanComponent,entryName:"fanEntry1",width:420,height:500},
      {component:gridComponent,entryName:"gridEntry1",width:600,height:400},
      {component:listComponent,entryName:"listEntry1",width:300,height:250}]
    for (var i=0;i<cases.length;i++) {
      var c=cases[i]
      var view=createTemporaryObject(c.component,this,{width:c.width,height:c.height,entries:fixtures,expanded:true})
      wait(500)
      var item=findChild(view,c.entryName)
      verify(item,c.entryName)
      var drag=findChild(item,"fileDrag")
      drag.Drag.dragType=Drag.Internal
      mousePress(drag,15,15)
      mouseMove(drag,40,15)
      tryVerify(function(){ return drag.Drag.imageSource.toString().indexOf("itemgrabber:")===0 })
      verify(drag.Drag.active)
      verify(drag.previewSize.width>0 && drag.previewSize.width<=320)
      verify(drag.previewSize.height>0 && drag.previewSize.height<=128)
      verify(drag.Drag.hotSpot.x>=0 && drag.Drag.hotSpot.x<=drag.previewSize.width)
      compare(drag.Drag.mimeData["text/plain"],fixtures[1].path)
      drag.Drag.dragFinished(Qt.IgnoreAction)
      mouseRelease(drag,40,15)
      compare(drag.Drag.imageSource.toString(),"")
      view.destroy()
    }
  }
  function test_release_before_preview_is_ready_does_not_start_a_late_drag() {
    var drag=createTemporaryObject(fileDragComponent,this,{width:100,height:100,entry:fixtures[1]})
    drag.Drag.dragType=Drag.Internal
    mousePress(drag,20,30)
    mouseMove(drag,70,30)
    mouseRelease(drag,70,30)
    wait(150)
    verify(!drag.Drag.active)
    compare(drag.Drag.imageSource.toString(),"")
  }
  function test_grid_click_and_keyboard_open_files() {
    var grid=createTemporaryObject(gridComponent,this,{width:600,height:400,entries:fixtures,expanded:true})
    verify(grid)
    activation.target=grid
    wait(350)
    var file=findChild(grid,"gridEntry1")
    verify(file)
    mouseClick(file,file.width/2,file.height/2)
    compare(activation.count,1)
    compare(activation.signalArguments[0][0].path,"/tmp/Report.pdf")
    grid.forceActiveFocus()
    keyClick(Qt.Key_Home); keyClick(Qt.Key_Return)
    compare(activation.count,2)
    compare(activation.signalArguments[1][0].path,"/tmp/Documents")
  }
  function test_grid_scrolls_large_folders() {
    var entries=[]
    for(var i=0;i<200;i++) entries.push({name:"File "+i,path:"/tmp/"+i,isDir:false})
    var grid=createTemporaryObject(gridComponent,this,{width:400,height:300,entries:entries,expanded:true})
    verify(grid)
    var view=findChild(grid,"stackGridView")
    verify(view.contentHeight>view.height)
    grid.forceActiveFocus(); keyClick(Qt.Key_End)
    wait(300)
    verify(view.contentY>0)
    compare(grid.selectedIndex,200)
    verify(findChild(grid,"gridOpenFolder"))
  }
  function test_list_hover_opens_subfolder_without_clicking() {
    var list=createTemporaryObject(listComponent,this,{width:280,height:240,entries:fixtures,expanded:true})
    verify(list)
    navigation.target=list
    wait(180)
    var row=findChild(list,"listEntry0")
    verify(row)
    mouseMove(row,30,row.height/2)
    tryCompare(navigation,"count",1,800)
    compare(navigation.signalArguments[0][0].path,"/tmp/Documents")
  }
  function test_list_click_opens_file() {
    var list=createTemporaryObject(listComponent,this,{width:280,height:240,entries:fixtures,expanded:true})
    verify(list)
    activation.target=list
    wait(180)
    var row=findChild(list,"listEntry1")
    mouseClick(row,30,row.height/2)
    compare(activation.count,1)
    compare(activation.signalArguments[0][0].path,"/tmp/Report.pdf")
  }
  function test_list_selection_survives_files_disappearing() {
    var list=createTemporaryObject(listComponent,this,{width:280,height:240,entries:fixtures,expanded:true})
    activation.target=list
    list.forceActiveFocus(); keyClick(Qt.Key_End)
    compare(list.selectedIndex,1)
    list.entries=[fixtures[1]]
    keyClick(Qt.Key_Return)
    compare(activation.count,1)
    compare(activation.signalArguments[0][0].path,"/tmp/Report.pdf")
    list.entries=[]; keyClick(Qt.Key_Return)
    compare(activation.count,1)
  }
  function test_fan_icons_at_all_edges_activate_their_own_files() {
    var entries=[]
    for(var i=0;i<7;i++) entries.push({name:"File "+i,path:"/tmp/"+i,isDir:false})
    var edges=[{edge:"left",x:40,y:650},{edge:"right",x:1326,y:650},{edge:"bottom",x:683,y:728},{edge:"top",x:683,y:40}]
    width=1366; height=768
    for(var e=0;e<edges.length;e++) {
      var edge=edges[e]
      var fan=createTemporaryObject(fanComponent,this,{width:1366,height:768,availableHeight:700,originX:edge.x,originY:edge.y,edge:edge.edge,entries:entries,expanded:true})
      activation.target=fan; activation.clear(); wait(500)
      for(var i=0;i<7;i++) {
        var card=findChild(fan,"fanEntry"+i)
        verify(card)
        mouseClick(card,card.iconOnLeft ? 28 : card.width-28,30)
        compare(activation.signalArguments[i][0].path,"/tmp/"+i,edge.edge+" item "+i)
      }
      fan.destroy(); activation.target=null
    }
    width=900; height=700
  }
}
