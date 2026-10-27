import QtQuick
import QtQuick.Shapes
import qs.theme

// The island's outline: flat against the top screen edge and rounded at the bottom, with
// concave curves (fillets) where its sides meet the top edge, so it looks like it grows out
// of the bezel. The body is bodyWidth wide; the fillets stick out a little on both sides.
// Animating bodyWidth, bodyHeight and radius morphs the shape; the path follows every frame.
Shape {
    id: root

    property real bodyWidth
    property real bodyHeight
    property real radius // bottom corners
    property color color

    readonly property real f: Theme.island.fillet

    width: bodyWidth + f * 2
    height: bodyHeight
    // Draws curves on the GPU with smooth, antialiased edges.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeWidth: -1 // no outline

        // Clockwise from the top-left: along the screen edge, down the right side, along the
        // bottom, up the left side. Convex corners turn clockwise, the fillets the other way.
        startX: 0
        startY: 0
        PathLine { x: root.width; y: 0 }
        PathArc {
            x: root.width - root.f; y: root.f
            radiusX: root.f; radiusY: root.f
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.width - root.f; y: root.height - root.radius }
        PathArc {
            x: root.width - root.f - root.radius; y: root.height
            radiusX: root.radius; radiusY: root.radius
        }
        PathLine { x: root.f + root.radius; y: root.height }
        PathArc {
            x: root.f; y: root.height - root.radius
            radiusX: root.radius; radiusY: root.radius
        }
        PathLine { x: root.f; y: root.f }
        PathArc {
            x: 0; y: 0
            radiusX: root.f; radiusY: root.f
            direction: PathArc.Counterclockwise
        }
    }
}
