.pragma library

function normalizeFolders(raw) {
  if (!Array.isArray(raw)) return []
  var seen = {}, out = []
  for (var i = 0; i < raw.length; i++) {
    var f = raw[i]
    if (!f || typeof f.path !== "string" || f.path.charAt(0) !== "/") continue
    var path = f.path.replace(/\/+$/, "") || "/"
    if (seen[path]) continue
    seen[path] = true
    out.push({path:path, name:String(f.name || path.split("/").pop() || "Filesystem"),
      view:normalizeView(f.view), showHidden:f.showHidden === true,
      sort:f.sort === "modified" ? "modified" : "name"})
  }
  return out
}

function normalizeView(value) { return ["fan", "grid", "list"].indexOf(value) >= 0 ? value : "fan" }
function fileUrl(path) { return "file://" + String(path).split("/").map(encodeURIComponent).join("/") }
function localPaths(urls) {
  var out=[]
  for(var i=0;i<urls.length;i++) {
    var match=String(urls[i]).match(/^file:\/\/(?:localhost)?(\/.*)$/)
    if (!match) continue
    try {
      var path=decodeURIComponent(match[1])
      if(path.indexOf("\u0000")<0 && out.indexOf(path)<0) out.push(path)
    } catch(e) {}
  }
  return out
}
function fanLayout(count, availableHeight) {
  var capacity = Math.max(1, Math.min(8, Math.floor((availableHeight - 100) / 56)))
  var visible = Math.min(Math.max(0, count), capacity)
  return {visibleCount:visible, fileCount:count > capacity ? visible - 1 : visible, hasOverflow:count > capacity}
}
function fanPose(index, count) {
  var t = count > 1 ? index / (count - 1) : 0
  return {x:Math.round(115 * t * t), y:-(54 + index * 56), scale:0.76 + 0.24*t, rotation:-7 + t*14}
}
function clamp(value, lo, hi) { return Math.max(lo, Math.min(value, Math.max(lo,hi))) }
function stackRect(edge, anchor, size, screen) {
  var w = Math.min(size.width, Math.max(1,screen.width-16))
  var h = Math.min(size.height, Math.max(1,screen.height-16))
  var x = anchor.x + anchor.width/2 - w/2
  var y = anchor.y - h - 12
  if (edge === "top") y = anchor.y + anchor.height + 12
  if (edge === "left" || edge === "right") {
    x = edge === "left" ? anchor.x + anchor.width + 12 : anchor.x - w - 12
    y = anchor.y + anchor.height/2 - h/2
  }
  return {x:clamp(x,8,screen.width-w-8),y:clamp(y,8,screen.height-h-8),width:w,height:h}
}
function cascadeRect(parent, rowY, size, screen) {
  var w = Math.min(size.width, screen.width-16), h = Math.min(size.height,screen.height-16)
  var x = parent.x + parent.width - 4
  if (x+w > screen.width-8) x = parent.x-w+4
  return {x:clamp(x,8,screen.width-w-8),y:clamp(parent.y+rowY,8,screen.height-h-8),width:w,height:h}
}
