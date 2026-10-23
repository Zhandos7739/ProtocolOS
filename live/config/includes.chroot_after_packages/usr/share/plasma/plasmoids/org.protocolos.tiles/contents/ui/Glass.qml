import QtQuick
import QtQuick.Window
import QtQuick.Effects

// Glass panel: blurred copy of the wallpaper behind the item + white gradient + light border.
// Plasma cannot blur the wallpaper behind desktop widgets, so the blur is rebuilt here from the
// wallpaper file, aligned to the item's position in the desktop window.
Item {
    id: g
    property real radius: 24
    property bool hovered: false
    property real tint: 1.0              // multiplies the white gradient
    property url wallpaper: ""
    property point origin: Qt.point(0, 0) // position of this item in window coordinates
    readonly property real pad: 24

    function sync() {
        var p = g.mapToItem(null, 0, 0)
        if (p.x !== origin.x || p.y !== origin.y) origin = Qt.point(p.x, p.y)
    }
    Component.onCompleted: Qt.callLater(sync)
    onWidthChanged: Qt.callLater(sync)
    onHeightChanged: Qt.callLater(sync)
    Timer { interval: 2000; running: g.visible; repeat: true; onTriggered: g.sync() }

    property bool shadow: true
    // box-shadow: 0 20px 50px rgba(10,0,40,.35), drawn only outside the shape (like CSS)
    readonly property real sp: 60 * Math.max(0.5, g.radius / 28)
    Item {
        id: shBox
        visible: false
        x: -g.sp; y: -g.sp; width: g.width + 2 * g.sp; height: g.height + 2 * g.sp
        Rectangle { x: g.sp; y: g.sp + 20 * g.sp / 60; width: g.width; height: g.height; radius: g.radius
            color: Qt.rgba(10/255, 0, 40/255, 1) }
    }
    Item {
        id: shMask; visible: false; layer.enabled: true
        anchors.fill: shBox
        Rectangle { x: g.sp; y: g.sp; width: g.width; height: g.height; radius: g.radius }
    }
    MultiEffect {
        visible: g.shadow
        anchors.fill: shBox; source: shBox
        autoPaddingEnabled: false
        blurEnabled: true; blur: 1.0; blurMax: 50
        opacity: 0.35
        maskEnabled: true; maskSource: shMask; maskInverted: true
        maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
    }
    // wallpaper slice (slightly larger than the item so the blur has no dark edges)
    Item {
        id: slice
        x: -g.pad; y: -g.pad
        width: g.width + 2 * g.pad; height: g.height + 2 * g.pad
        visible: false
        clip: true
        Image {
            source: g.wallpaper
            visible: g.wallpaper != ""
            x: -g.origin.x + g.pad; y: -g.origin.y + g.pad
            width: g.Window.width > 0 ? g.Window.width : 1920
            height: g.Window.height > 0 ? g.Window.height : 1080
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 960
            asynchronous: true
            cache: true
        }
    }
    Item {
        id: maskShape
        anchors.fill: slice
        visible: false
        layer.enabled: true
        Rectangle { x: g.pad; y: g.pad; width: g.width; height: g.height; radius: g.radius }
    }
    MultiEffect {
        anchors.fill: slice
        source: slice
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        saturation: 0.7
        brightness: 0.07
        maskEnabled: true
        maskSource: maskShape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    // glass tint, same as the mockup: linear-gradient(145deg, rgba(255,255,255,.28), rgba(255,255,255,.08))
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
    // ::before overlay: linear-gradient(160deg, .55 0, 0 30%, 0 75%, .18) with mix-blend overlay (approx. at lower alpha)
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true; maskSource: hlMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0
        }
        Rectangle {
            anchors.centerIn: parent
            width: Math.hypot(parent.width, parent.height); height: width
            rotation: -20
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.30) }
                GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.10) }
            }
        }
    }
    Item {
        id: hlMask; anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: g.radius }
    }
    // inset 0 0 24px rgba(255,255,255,.18): soft inner glow
    Repeater {
        model: 4
        Rectangle {
            anchors.fill: parent; anchors.margins: 1 + index * 3
            radius: Math.max(0, g.radius - anchors.margins)
            color: "transparent"; border.width: 3
            border.color: Qt.rgba(1, 1, 1, 0.07 - index * 0.016)
        }
    }
    // chromatic edges: 1px 0 0 rgba(255,80,160,.35), -1px 0 0 rgba(80,200,255,.35)
    Rectangle {
        x: 1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1; border.color: Qt.rgba(1, 80/255, 160/255, 0.35)
    }
    Rectangle {
        x: -1; y: 0; width: parent.width; height: parent.height; radius: g.radius; z: -1
        color: "transparent"; border.width: 1; border.color: Qt.rgba(80/255, 200/255, 1, 0.35)
    }
    // inset 0 1px 0 rgba(255,255,255,.8) / inset 0 -1px 0 rgba(255,255,255,.15)
    Rectangle { x: g.radius * 0.5; width: parent.width - 2 * x; y: 1; height: 1; color: Qt.rgba(1, 1, 1, 0.8) }
    Rectangle { x: g.radius * 0.5; width: parent.width - 2 * x; y: parent.height - 2; height: 1; color: Qt.rgba(1, 1, 1, 0.15) }
}
