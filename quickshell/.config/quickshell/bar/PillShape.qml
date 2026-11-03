import QtQuick
import QtQuick.Shapes
import qs.theme
import "PillPath.js" as PillPath

// The island's outline (bar/IslandPill.qml): floating, or attached to the top edge (`mode`, see
// PillPath.js). The body is bodyWidth x bodyHeight and starts at bodyX in the shape (the fillets
// stick out of it). Animating
// bodyWidth, bodyHeight and radius morphs it; the path follows every frame.
Shape {
    id: root

    property string mode: "float"
    property real bodyWidth
    property real bodyHeight
    property real radius
    property color color
    // The thin light edge of glass panels (widgets/Surface.qml); transparent for none.
    property color edgeColor: "transparent"

    readonly property real fillet: Theme.island.fillet
    readonly property var geometry: PillPath.size(mode, bodyWidth, bodyHeight, fillet)
    readonly property real bodyX: geometry.bodyX
    // The radius actually drawn (it never exceeds what the body has room for).
    readonly property real drawnRadius: PillPath.radius(bodyWidth, bodyHeight, radius)

    width: geometry.width
    height: geometry.height
    // Draws curves on the GPU with smooth, antialiased edges.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        // Along the whole path; the parts on the screen's edges fall mostly outside the screen.
        strokeColor: root.edgeColor
        strokeWidth: root.edgeColor.a > 0 ? Theme.glass.edge : -1

        PathSvg {
            path: PillPath.path(root.mode, root.bodyWidth, root.bodyHeight, root.radius, root.fillet)
        }
    }
}
