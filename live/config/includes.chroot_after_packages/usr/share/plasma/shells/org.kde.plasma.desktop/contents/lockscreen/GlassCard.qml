import QtQuick

// Liquid Glass panel matching ProtocolOS HTML mockup / desktop tiles.
Item {
    id: g
    property real radius: 28
    property real tint: 1.0

    Rectangle {
        z: -2
        x: 0; y: Math.max(10, g.radius * 0.55)
        width: g.width; height: g.height
        radius: g.radius
        color: Qt.rgba(10/255, 0, 40/255, 0.32)
    }
    Rectangle {
        z: -1
        x: 4; y: Math.max(6, g.radius * 0.3)
        width: g.width - 8; height: g.height - 4
        radius: g.radius
        color: Qt.rgba(10/255, 0, 40/255, 0.18)
    }

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

    Rectangle {
        x: g.radius * 0.45; width: parent.width - 2 * x; y: 1; height: 1
        color: Qt.rgba(1, 1, 1, 0.80)
    }
    Rectangle {
        x: g.radius * 0.45; width: parent.width - 2 * x; y: parent.height - 2; height: 1
        color: Qt.rgba(1, 1, 1, 0.15)
    }
}
