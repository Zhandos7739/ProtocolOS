import QtQuick
import QtQuick.Effects

// Exact HTML .glass from protocolos_design/index.html:
//   background: linear-gradient(145deg, rgba(255,255,255,.28), rgba(255,255,255,.08))
//   backdrop-filter: blur(28px) saturate(170%)
//   border 1px rgba(255,255,255,.45)
//   box-shadow: inset highlights + pink/cyan chromatic + 0 20px 50px rgba(10,0,40,.35)
//   ::before specular overlay
Item {
    id: g
    property real radius: 28
    property real tint: 1.0
    property Item wallLayer: null   // kscreenlocker wallpaper item
    property bool shadow: true

    // Soft outer shadow
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

    // Backdrop blur of the live wallpaper (HTML backdrop-filter)
    Item {
        id: wallClip
        anchors.fill: parent
        visible: g.wallLayer !== null
        layer.enabled: true
        layer.smooth: true
        ShaderEffectSource {
            id: wallSrc
            anchors.fill: parent
            live: true
            hideSource: false
            sourceItem: g.wallLayer
            sourceRect: {
                if (!g.wallLayer) return Qt.rect(0, 0, 1, 1)
                var p = g.mapToItem(g.wallLayer, 0, 0)
                return Qt.rect(p.x, p.y, Math.max(1, g.width), Math.max(1, g.height))
            }
        }
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 40
            saturation: 1.7
            brightness: 0.04
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

    // Fallback fill when wallpaper sample unavailable
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        visible: g.wallLayer === null
        color: Qt.rgba(0.10, 0.12, 0.22, 0.55)
    }

    // Main glass fill
    Rectangle {
        anchors.fill: parent
        radius: g.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.28 * g.tint) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.08 * g.tint) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.45)
        border.width: 1
    }

    // ::before specular
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

    // inset 0 0 24px glow rings
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

    // Chromatic edges
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
