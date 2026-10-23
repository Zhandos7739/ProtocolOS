import QtQuick
import QtQuick.Shapes

// check mark drawn by a growing stroke dash; `progress` 0..1; points in 64-unit icon space
Shape {
    id: c
    property real u: 1
    property real progress: 1
    property color color: "#7CFFB2"
    property real w: 3.2
    property var p: [24.5, 32, 29.5, 37, 39.5, 25]
    readonly property real len: Math.hypot(p[2] - p[0], p[3] - p[1]) + Math.hypot(p[4] - p[2], p[5] - p[3]) + w
    visible: progress > 0.01
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: c.color; strokeWidth: c.w * c.u; fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        strokeStyle: ShapePath.DashLine
        dashPattern: [Math.max(0.01, c.len / c.w * c.progress), 1000]
        startX: c.p[0] * c.u; startY: c.p[1] * c.u
        PathLine { x: c.p[2] * c.u; y: c.p[3] * c.u }
        PathLine { x: c.p[4] * c.u; y: c.p[5] * c.u }
    }
}
