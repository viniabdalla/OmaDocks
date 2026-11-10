import QtQuick
import Quickshell
import "OMADOCKS_TEST_MODULE" as Dock
ShellRoot {
  id: root
  property var errors: []
  property int dockChanges: 0
  property int barChanges: 0
  property int contextChanges: 0
  function check(ok, message) { if (!ok) errors.push(message) }
  function find(item, name) {
    if (!item) return null
    if (item.length !== undefined) { for (var n=0;n<item.length;n++) { var found=find(item[n],name); if(found) return found }; return null }
    if (item.objectName === name) return item
    var children = item.children || []
    for (var i=0;i<children.length;i++) { var result=find(children[i],name); if(result) return result }
    return null
  }
  Dock.SettingsPopup {
    id: settings
    allEntries: [{id:"Oracle", name:"Oracle", pinned:false, barPinned:true, iconSource:""}]
    onAppPicked: root.dockChanges++
    onBarAppPicked: root.barChanges++
  }
  Dock.IconContextMenu {
    id: menu
    running: true
    onBarPinToggled: root.contextChanges++
  }
  Timer {
    interval: 300; running: true
    onTriggered: {
      settings.activeTab=1; settings.selectedIndex=0; settings.activateSelected()
      root.check(root.dockChanges===1 && root.barChanges===0,"dock selection reached bar favorites")
      settings.activeTab=3; settings.selectedIndex=0; settings.activateSelected()
      root.check(root.dockChanges===1 && root.barChanges===1,"bar selection changed dock pins")
      settings.filterText="missing-app"; settings.selectedIndex=-1; settings.activateSelected()
      root.check(root.barChanges===1,"empty selection changed bar favorites")
      var button=root.find(settings.contentItem,"chooseBarFavorites")
      root.check(!!button,"favorites chooser missing from existing configuration menu")
      if(button) { settings.activeTab=0; button.clicked(); root.check(settings.activeTab===3,"settings button did not open bar selection") }
      var action=root.find(menu.contentItem,"barFavoriteAction")
      root.check(!!action,"context action missing")
      if(action) {
        root.check(action.label==="Add to bar favorites","missing add label")
        action.activated()
        root.check(root.contextChanges===1,"context action did not emit bar pin toggle")
        menu.barPinned=true
        root.check(action.label==="Remove from bar favorites","missing remove label")
      }
      console.log("QA_BAR_RESULT " + JSON.stringify(root.errors))
      Qt.quit()
    }
  }
}
