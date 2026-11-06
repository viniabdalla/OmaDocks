import QtQuick
import QtQuick.Shapes

// Independently drawn macOS-style Open in Finder symbol, using the view color.
Item {
  id:root
  property color color: "#f4f4f5"
  implicitWidth:56; implicitHeight:56
  Rectangle {
    anchors.fill:parent; anchors.margins:2
    radius:width/2; color:"transparent"
    border.color:root.color; border.width:Math.max(1.5,root.width/24)
  }
  Shape {
    width:64; height:64
    scale:Math.min(root.width,root.height)/64
    transformOrigin:Item.TopLeft
    ShapePath {
      strokeColor:"transparent"; fillColor:root.color
      PathSvg { path:"M 16 44 C 16 30 23 24 35 24 L 35 16 L 50 30 L 35 44 L 35 35 C 26 35 21 38 16 44 Z" }
    }
  }
}
