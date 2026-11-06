import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

PopupWindow {
  id:root
  property QtObject hostWindow:null
  property point position:Qt.point(0,0)
  property var folder:({name:"Folder",path:"",view:"fan",sort:"name",showHidden:false})
  property string selectedView:folder.view
  signal viewPicked(string view)
  signal optionPicked(var patch)
  signal unpinRequested()
  signal dismissed()
  visible:false; color:"transparent"; grabFocus:true
  implicitWidth:Math.ceil(Style.space(218)); implicitHeight:Math.ceil(menu.implicitHeight)
  onVisibleChanged:if(!visible) root.dismissed()
  anchor {
    window:root.hostWindow
    edges:Edges.Top | Edges.Left; gravity:Edges.Bottom | Edges.Right
    adjustment:PopupAdjustment.Slide
    rect.x:Math.round(root.position.x); rect.y:Math.round(root.position.y)
    rect.width:1; rect.height:1
  }
  BorderSurface {
    id:menu
    width:root.width; implicitHeight:content.implicitHeight+Style.space(12)
    color:Color.popups.background
    borderSpec:Border.surfaceSpec("popups","border",Color.popups.border,1)
    radius:Math.max(Style.cornerRadius,Style.space(8))
    ColumnLayout {
      id:content
      x:Style.space(6); y:Style.space(6); width:parent.width-Style.space(12)
      spacing:Style.space(2)
      Text {
        Layout.fillWidth:true; Layout.leftMargin:Style.space(10)
        text:root.folder.name; textFormat:Text.PlainText; elide:Text.ElideMiddle
        color:Util.alpha(Color.popups.text,0.55); font.family:Style.font.family; font.pixelSize:Style.font.caption
      }
      Repeater {
        model:[{view:"fan",label:"Fan"},{view:"grid",label:"Grid"},{view:"list",label:"List"}]
        Button {
          required property var modelData
          Layout.fillWidth:true; leftAlign:true
          text:(root.selectedView===modelData.view ? "✓  " : "    ")+modelData.label
          selected:root.selectedView===modelData.view
          onClicked:{ root.viewPicked(modelData.view); root.visible=false }
        }
      }
      Rectangle { Layout.fillWidth:true; height:1; color:Util.alpha(Color.popups.text,0.12) }
      Button { Layout.fillWidth:true; leftAlign:true; text:root.folder.sort==="modified" ? "Sort by name" : "Sort newest first"; onClicked:{ root.optionPicked({sort:root.folder.sort==="modified" ? "name" : "modified"}); root.visible=false } }
      Button { Layout.fillWidth:true; leftAlign:true; text:(root.folder.showHidden ? "✓  " : "    ")+"Show hidden files"; onClicked:{ root.optionPicked({showHidden:!root.folder.showHidden}); root.visible=false } }
      Rectangle { Layout.fillWidth:true; height:1; color:Util.alpha(Color.popups.text,0.12) }
      Button { Layout.fillWidth:true; leftAlign:true; text:"Remove from dock"; onClicked:{ root.unpinRequested(); root.visible=false } }
    }
  }
}
