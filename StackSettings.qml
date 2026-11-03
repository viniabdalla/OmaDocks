import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Embedded in the bar's OmaDocks popover, using Omarchy's own UI kit.
Item {
  id:root
  property var folders: []
  property string home: ""
  property string message: ""
  signal addFolder(string path)
  signal updateFolder(string path,var patch)
  signal removeFolder(string path)
  function addPath() {
    var path=pathField.text
    if(path.indexOf("~/")===0) path=home+path.slice(1)
    if(path.charAt(0)!=="/") { message="Use a full folder path or ~/Downloads"; return }
    root.addFolder(path); pathField.text=""; message=""
  }
  ColumnLayout {
    anchors.fill:parent; spacing:Style.space(10)
    Text {
      Layout.fillWidth:true
      text:"Drag folders onto your dock to pin them."
      color:Color.accent; font.family:Style.font.family; font.pixelSize:Style.font.body
    }
    RowLayout {
      Layout.fillWidth:true; spacing:Style.space(6)
      TextField { id:pathField; Layout.fillWidth:true; placeholderText:"~/Downloads"; onAccepted:root.addPath() }
      Button { text:"Add folder"; bordered:true; onClicked:root.addPath() }
    }
    Text { visible:root.message.length>0; text:root.message; color:Color.urgent; font.family:Style.font.family; font.pixelSize:Style.font.caption }
    Flickable {
      id:scroller
      Layout.fillWidth:true; Layout.fillHeight:true
      contentHeight:folderColumn.implicitHeight
      boundsBehavior:Flickable.StopAtBounds; clip:true
      ColumnLayout {
        id:folderColumn
        width:scroller.width; spacing:Style.space(12)
        Repeater {
          model:root.folders
          ColumnLayout {
            id:row
            required property var modelData
            Layout.fillWidth:true; spacing:Style.space(6)
            RowLayout {
              Layout.fillWidth:true
              TextField { Layout.fillWidth:true; text:row.modelData.name; onEditingFinished: if(text!==row.modelData.name) root.updateFolder(row.modelData.path,{name:text}) }
              Button { iconText:"×"; tooltipText:"Unpin folder"; onClicked:root.removeFolder(row.modelData.path) }
            }
            Text { Layout.fillWidth:true; text:row.modelData.path; textFormat:Text.PlainText; elide:Text.ElideMiddle; color:Util.alpha(Color.foreground,0.5); font.family:Style.font.family; font.pixelSize:Style.font.caption }
            RowLayout {
              Layout.fillWidth:true; spacing:Style.space(4)
              Repeater {
                model:["fan","grid","list"]
                Button {
                  required property string modelData
                  text:modelData.charAt(0).toUpperCase()+modelData.slice(1)
                  selected:row.modelData.view===modelData
                  onClicked:root.updateFolder(row.modelData.path,{view:modelData})
                }
              }
              Item { Layout.fillWidth:true }
              Button { text:row.modelData.sort==="modified" ? "Newest" : "A–Z"; tooltipText:"Change sorting"; onClicked:root.updateFolder(row.modelData.path,{sort:row.modelData.sort==="name" ? "modified" : "name"}) }
              Button { text:"Hidden"; selected:row.modelData.showHidden; onClicked:root.updateFolder(row.modelData.path,{showHidden:!row.modelData.showHidden}) }
            }
            Rectangle { Layout.fillWidth:true; height:1; color:Util.alpha(Color.foreground,0.1) }
          }
        }
      }
      Text { visible:root.folders.length===0; anchors.centerIn:parent; text:"Drop a folder onto the dock to get started."; color:Util.alpha(Color.foreground,0.5); font.family:Style.font.family; font.pixelSize:Style.font.bodySmall }
    }
    Text { Layout.fillWidth:true; text:"Drag to reorder. Drag away from the dock to unpin."; color:Util.alpha(Color.foreground,0.5); font.family:Style.font.family; font.pixelSize:Style.font.caption }
  }
}
