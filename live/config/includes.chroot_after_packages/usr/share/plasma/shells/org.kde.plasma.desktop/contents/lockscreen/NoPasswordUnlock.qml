/*
    ProtocolOS glass unlock (passwordless) — same HTML .card language.
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Item {
    id: page
    focus: true
    property var userListModel
    property real scaleFactor: 1
    readonly property real s: scaleFactor > 0 ? scaleFactor : 1

    Keys.onEnterPressed: unlock()
    Keys.onReturnPressed: unlock()
    Keys.onSpacePressed: unlock()
    function unlock() { Qt.quit() }

    implicitWidth: Math.round(404 * s)
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(16 * s)

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (typeof kscreenlocker_userName !== "undefined") ? kscreenlocker_userName : ""
            color: "white"
            font.family: "Inter"
            font.pixelSize: Math.round(18 * s)
            font.weight: Font.DemiBold
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
            visible: text.length > 0
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Сеанс без пароля"
            color: Qt.rgba(1, 1, 1, 0.75)
            font.family: "Inter"
            font.pixelSize: Math.round(15 * s)
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(52 * s)

            Rectangle {
                anchors.fill: parent
                radius: Math.round(18 * s)
                color: unlockMa.containsMouse ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.22)
                border.color: Qt.rgba(1, 1, 1, 0.55)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Text {
                anchors.centerIn: parent
                text: "Разблокировать"
                color: "white"
                font.family: "Inter"
                font.pixelSize: Math.round(18 * s)
                font.weight: Font.Bold
            }
            MouseArea {
                id: unlockMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.unlock()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enter · Пробел"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: "Inter"
            font.pixelSize: Math.round(13 * s)
        }
    }

    Component.onCompleted: forceActiveFocus()
}
