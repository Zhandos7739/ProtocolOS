import QtQuick
import QtQuick.Effects

// Glass panel: samples a shared blurred wallpaper (WallBlur) — one GPU blur for the whole
// desktop instead of a MultiEffect blur per tile.
Item {
    id: g
    property real radius: 24
    property bool hovered: false
    property real tint: 1.0
    property url wallpaper: ""       // kept for API compat; prefer wallLayer
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
    Timer { interval: 4000; running: g.visible; repeat: true; onTriggered: g.sync() }

    Rectangle {
        visible: g.shadow
        z: -2
        x: 0; y: Math.max(6, g.radius * 0.35)
        width: g.width; height: g.height
        radius: g.radius
        color: Qt.rgba(10/255, 0, 40/255, 0.30)
    }

    // Rounded sample of the shared blurred wall (mask only — no per-tile blur).
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
                var lw = Math.max(1, g.wallW)
                var lh = Math.max(1, g.wallH)
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
        color: Qt.rgba(0.12, 0.14, 0.22, 0.55)
    }

    Rectangle {
        anchors.fill: parent
        radius: g.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, (g.hovered ? 0.42 : 0.32) * g.tint) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, (g.hovered ? 0.18 : 0.11) * g.tint) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.45)
        border.width: 1
    }

    Rectangle {
        anchors.fill: parent
        radius: g.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.20) }
            GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.05) }
        }
    }

    Repeater {
        model: 2
        Rectangle {
            anchors.fill: parent; anchors.margins: 1 + index * 4
            radius: Math.max(0, g.radius - anchors.margins)
            color: "transparent"; border.width: 2
            border.color: Qt.rgba(1, 1, 1, 0.06 - index * 0.02)
        }
    }

    Rectangle {
        x: 1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 80/255, 160/255, 0.28)
    }
    Rectangle {
        x: -1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1; border.color: Qt.rgba(80/255, 200/255, 1, 0.28)
    }
    Rectangle { x: g.radius * 0.5; width: parent.width - 2 * x; y: 1; height: 1; color: Qt.rgba(1, 1, 1, 0.7) }
    Rectangle { x: g.radius * 0.5; width: parent.width - 2 * x; y: parent.height - 2; height: 1; color: Qt.rgba(1, 1, 1, 0.12) }
}
