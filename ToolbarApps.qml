import QtQuick
import Quickshell
import Quickshell.Io
import "DockModel.js" as DockModel

Item {
  id: root
  property var defaults: ({terminal: "", browser: "", herdr: "herdr"})
  readonly property var entries: {
    // Keep default-role choices even when a system desktop entry is hidden.
    var applications = DesktopEntries.applications.values
    return [roleEntry("omadocks-default-terminal", defaults.terminal, "Terminal", "utilities-terminal"),
      roleEntry("omadocks-herdr", defaults.herdr, "Herdr", "utilities-terminal"),
      roleEntry("omadocks-default-browser", defaults.browser, "Navegador", "web-browser")]
  }
  function iconSource(icon) {
    icon = String(icon || "application-x-executable")
    return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon)
  }
  function roleEntry(id, appId, name, fallback) {
    var entry = appId ? DesktopEntries.byId(appId) : null
    return {id: id, name: name, iconSource: iconSource(entry ? entry.icon : fallback), toolbarOnly: true}
  }
  function entryFor(id) {
    for (var i = 0; i < entries.length; i++) if (entries[i].id === id) return entries[i]
    var app = DesktopEntries.byId(id)
    return app ? {id: id, name: app.name || id, iconSource: iconSource(app.icon)} : null
  }
  Process {
    id: discovery
    command: ["python3", decodeURIComponent(Qt.resolvedUrl("helpers/default_apps.py").toString().replace(/^file:\/\//, ""))]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.defaults = JSON.parse(text) } catch (e) { console.warn("Toolbar default-app discovery failed") }
      }
    }
  }
  // Launch commands always follow current defaults. Refresh icons and aliases
  // as well, including changes made outside the shell while it stays running.
  Timer { interval: 30000; running: true; repeat: true; onTriggered: if (!discovery.running) discovery.running = true }
}
