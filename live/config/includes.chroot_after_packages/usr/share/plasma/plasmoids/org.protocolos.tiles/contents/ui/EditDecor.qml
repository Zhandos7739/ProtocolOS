import QtQuick
import org.kde.kirigami as Kirigami

// edit-mode outline + hide button (top-left), placed over a tile, folder or the card
Item {
    id: d
    property real k: 1
    property real radius: 28
    property bool editing: false
    signal hide()
    anchors.fill: parent
    visible: editing
    z: 50
    Rectangle {
        anchors.fill: parent; anchors.margins: -3 * d.k
        radius: d.radius + 3 * d.k
        color: "transparent"
        border.width: Math.max(1, 2 * d.k); border.color: Qt.rgba(1, 1, 1, 0.75)
        opacity: 0.9
    }
    Kirigami.Icon {
        id: x
        source: "protocolos-close"
        width: Math.max(18, Math.round(26 * d.k)); height: width
        x: -width / 3; y: -height / 3
        scale: hm.containsMouse ? 1.12 : 1
        MouseArea { id: hm; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor; onClicked: d.hide() }
    }
}
