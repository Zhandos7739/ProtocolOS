import QtQuick
import org.kde.kirigami as Kirigami

// edit-mode toolbar: list of hidden items (click to show again) and the "Готово" button
Item {
    id: bar
    property real s: 1
    property url wallpaper: ""
    property var hiddenList: []
    signal restore(string key)
    signal done()
    property bool animIcons: true
    signal toggleAnim()
    signal reset()
    property bool confirmReset: false
    z: 100
    width: row.width + 24 * s
    height: Math.round(52 * s)

    Glass { anchors.fill: parent; radius: height / 2; wallpaper: bar.wallpaper; tint: 1.3 }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10 * bar.s
        Kirigami.Icon { source: "protocolos-edit"; width: 22 * bar.s; height: width; anchors.verticalCenter: parent.verticalCenter }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.hiddenList.length ? "Скрытые:" : "Скрытых нет"
            color: "white"; font.family: "Inter"; font.pixelSize: Math.max(11, 15 * bar.s); font.weight: Font.DemiBold
        }
        Repeater {
            model: bar.hiddenList
            delegate: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 34 * bar.s; width: chip.width + 16 * bar.s; radius: height / 2
                color: cm.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.18)
                border.color: Qt.rgba(1, 1, 1, 0.45)
                Row {
                    id: chip; anchors.centerIn: parent; spacing: 6 * bar.s
                    Kirigami.Icon { source: modelData[2]; width: 20 * bar.s; height: width; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData[1]; color: "white"; anchors.verticalCenter: parent.verticalCenter
                        font.family: "Inter"; font.pixelSize: Math.max(10, 13 * bar.s) }
                    Kirigami.Icon { source: "protocolos-eye"; width: 16 * bar.s; height: width; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: bar.restore(modelData[0]) }
            }
        }
        // "Анимации иконок" on/off
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 34 * bar.s; width: anRow.width + 20 * bar.s; radius: height / 2
            color: am.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.18)
            border.color: Qt.rgba(1, 1, 1, 0.45)
            Row { id: anRow; anchors.centerIn: parent; spacing: 8 * bar.s
                Text { text: "Анимации иконок"; color: "white"; anchors.verticalCenter: parent.verticalCenter
                    font.family: "Inter"; font.pixelSize: Math.max(10, 13 * bar.s) }
                Rectangle { anchors.verticalCenter: parent.verticalCenter
                    width: 34 * bar.s; height: 20 * bar.s; radius: height / 2
                    color: bar.animIcons ? Qt.rgba(80/255, 1, 170/255, 0.6) : Qt.rgba(1, 1, 1, 0.25)
                    Rectangle { width: parent.height - 4 * bar.s; height: width; radius: width / 2; color: "white"
                        y: 2 * bar.s; x: bar.animIcons ? parent.width - width - 2 * bar.s : 2 * bar.s
                        Behavior on x { NumberAnimation { duration: 140 } } } }
            }
            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.toggleAnim() }
        }
        // "Сбросить расположение": second click within 4 s confirms
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 34 * bar.s; width: rt.width + 24 * bar.s; radius: height / 2
            color: bar.confirmReset ? Qt.rgba(1, 0.3, 0.35, rm.containsMouse ? 0.55 : 0.4) : (rm.containsMouse ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.18))
            border.color: Qt.rgba(1, 1, 1, 0.45)
            Text { id: rt; anchors.centerIn: parent; color: "white"
                text: bar.confirmReset ? "Точно?" : "Сбросить"
                font.family: "Inter"; font.pixelSize: Math.max(10, 13 * bar.s); font.weight: bar.confirmReset ? Font.Bold : Font.Normal }
            Timer { id: rTimer; interval: 4000; onTriggered: bar.confirmReset = false }
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { if (bar.confirmReset) { bar.confirmReset = false; rTimer.stop(); bar.reset() } else { bar.confirmReset = true; rTimer.restart() } } }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 34 * bar.s; width: dt.width + 28 * bar.s; radius: height / 2
            color: dm.containsMouse ? Qt.rgba(80/255, 1, 170/255, 0.45) : Qt.rgba(80/255, 1, 170/255, 0.3)
            border.color: Qt.rgba(140/255, 1, 200/255, 0.7)
            Text { id: dt; anchors.centerIn: parent; text: "Готово"; color: "white"
                font.family: "Inter"; font.pixelSize: Math.max(11, 15 * bar.s); font.weight: Font.Bold }
            MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bar.done() }
        }
    }
}
