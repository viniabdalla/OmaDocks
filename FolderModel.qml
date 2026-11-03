import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property string path: ""
  property bool showHidden: false
  property string sort: "name"
  property bool active: true
  property var entries: []
  property string error: ""
  property bool loading: false
  property string requestPath: ""
  property bool refreshPending: false
  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("helpers/folders.py").toString().replace(/^file:\/\//,""))
  onPathChanged: { entries=[]; error=""; refresh() }
  onShowHiddenChanged: refresh()
  onSortChanged: refresh()
  onActiveChanged: if (active) refresh()
  function refresh() {
    if (!active || !path) return
    if (reader.running) { refreshPending=true; return }
    requestPath=path
    loading=entries.length===0
    var args=["python3",helper,"list",path,"--sort",sort]
    if (showHidden) args.push("--hidden")
    reader.command=args
    reader.running=true
  }
  Process {
    id: reader
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.path!==root.requestPath || !root.active) return
        try {
          var result=JSON.parse(text)
          var resolved=result.entries.map(function(e) {
            e.iconSource=Quickshell.iconPath(e.icon,true) || Quickshell.iconPath(e.isDir ? "folder" : "text-x-generic",true)
            return e
          })
          // Stable arrays keep a refresh from destroying hover/selection every poll.
          if (JSON.stringify(resolved)!==JSON.stringify(root.entries)) root.entries=resolved
          root.error=result.error || ""
        } catch(e) { root.error="Could not read this folder" }
      }
    }
    onExited: function(code,status) {
      if (code!==0) root.error="The folder reader could not run ("+code+")"
      root.loading=false
      if (root.refreshPending) { root.refreshPending=false; retry.start() }
    }
  }
  Timer { id:retry; interval:1; onTriggered:root.refresh() }
  Timer { interval:1800; repeat:true; running:root.active && root.path.length>0; onTriggered:root.refresh() }
  Component.onCompleted: refresh()
}
