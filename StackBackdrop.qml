import QtQuick
import QtQuick.Effects

// Wallpaper fallback keeps the frosted surface available without compositor rules.
Rectangle {
  id: root
  property string wallpaper: ""
  property real screenX: 0
  property real screenY: 0
  property real screenWidth: width
  property real screenHeight: height
  color: "transparent"
  radius: 14
  clip: true
  Image {
    id: image
    width: root.screenWidth; height: root.screenHeight
    source: root.wallpaper; fillMode: Image.PreserveAspectCrop
    asynchronous:true
    visible:false
  }
  ShaderEffectSource {
    id: crop
    width: root.width; height: root.height
    sourceItem: image
    sourceRect: Qt.rect(root.screenX,root.screenY,root.width,root.height)
    hideSource:true; visible:false; live:true
  }
  MultiEffect {
    anchors.fill:parent; source:crop
    blurEnabled:root.wallpaper.length>0; blurMax:64; blur:0.55
    saturation:-0.2
    autoPaddingEnabled:false
  }
  Rectangle { anchors.fill:parent; radius:root.radius; color:"#d91c1e24"; border.color:"#38ffffff" }
}
