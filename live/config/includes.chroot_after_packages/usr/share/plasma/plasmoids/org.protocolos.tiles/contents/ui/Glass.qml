import QtQuick
import QtQuick.Effects

// Liquid Glass from HTML mockup:
//   background: linear-gradient(145deg, rgba(255,255,255,.28), rgba(255,255,255,.08))
//   backdrop-filter: blur(28px) saturate(170%)
//   border 1px rgba(255,255,255,.45) + chromatic edges + inset highlights
Item {
    id: g
    property real radius: 28
    property bool hovered: false
    property real tint: 1.0
    property url wallpaper: ""
    property Item wallLayer: null
    property real wallW: 1920
    property real wallH: 1080
    property point origin: Qt.point(0, 0)
    property bool shadow: true

    function sync() {
        var p = g.mapToItem(null, 0, 0)
        if (p.x !== origin.x || p.y !== origin.y) origin = Qt.point(p.x, p.y)
    }
    Component.onCompleted: Qt.callLater(sync)
    onWidthChanged: Qt.callLater(sync)
    onHeightChanged: Qt.callLater(sync)
    Timer { interval: 3500; running: g.visible; repeat: true; onTriggered: g.sync() }

    // Soft outer shadow (HTML: 0 20px 50px rgba(10,0,40,.35))
    Rectangle {
        visible: g.shadow
        z: -3
        x: 0; y: Math.max(10, g.radius * 0.55)
        width: g.width; height: g.height
        radius: g.radius
        color: Qt.rgba(10/255, 0, 40/255, 0.32)
    }
    Rectangle {
        visible: g.shadow
        z: -2
        x: 4; y: Math.max(6, g.radius * 0.3)
        width: g.width - 8; height: g.height - 4
        radius: g.radius
        color: Qt.rgba(10/255, 0, 40/255, 0.18)
    }

    // Shared blurred wallpaper, rounded
    Item {
        id: wallClip
        anchors.fill: parent
        visible: g.wallLayer !== null
        layer.enabled: true
        layer.smooth: true
        ShaderEffectSource {
            anchors.fill: parent
            live: true
            hideSource: false
            sourceItem: g.wallLayer
            sourceRect: {
                var lw = Math.max(1, g.wallW), lh = Math.max(1, g.wallH)
                var tw = g.wallLayer ? g.wallLayer.width : lw
                var th = g.wallLayer ? g.wallLayer.height : lh
                return Qt.rect(g.origin.x * tw / lw, g.origin.y * th / lh,
                               Math.max(1, g.width) * tw / lw,
                               Math.max(1, g.height) * th / lh)
            }
        }
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: roundMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }
    Item {
        id: roundMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; radius: g.radius }
    }

    Rectangle {
        anchors.fill: parent
        radius: g.radius
        visible: g.wallLayer === null
        color: Qt.rgba(0.10, 0.12, 0.22, 0.55)
    }

    // Main glass fill (145deg ≈ vertical-ish light)
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, (g.hovered ? 0.38 : 0.28) * g.tint) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, (g.hovered ? 0.14 : 0.08) * g.tint) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.45)
        border.width: 1
    }

    // ::before specular sweep (mix-blend overlay approx)
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        opacity: 0.9
        gradient: Gradient {
            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.40) }
            GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.14) }
        }
    }

    // inset glow rings
    Repeater {
        model: 3
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1 + index * 3
            radius: Math.max(0, g.radius - anchors.margins)
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(1, 1, 1, 0.14 - index * 0.035)
        }
    }

    // Chromatic edges: pink + cyan
    Rectangle {
        x: 1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1
        border.color: Qt.rgba(1, 80/255, 160/255, 0.35)
    }
    Rectangle {
        x: -1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1
        border.color: Qt.rgba(80/255, 200/255, 1, 0.35)
    }

    // inset 0 1px / inset 0 -1px
    Rectangle {
        x: g.radius * 0.45; width: parent.width - 2 * x; y: 1; height: 1
        color: Qt.rgba(1, 1, 1, 0.80)
    }
    Rectangle {
        x: g.radius * 0.45; width: parent.width - 2 * x; y: parent.height - 2; height: 1
        color: Qt.rgba(1, 1, 1, 0.15)
    }
}
