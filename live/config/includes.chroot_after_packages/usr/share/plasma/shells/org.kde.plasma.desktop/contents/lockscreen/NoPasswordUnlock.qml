/*
    ProtocolOS glass unlock (passwordless / live session).
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

Item {
    id: page
    focus: true

    property var userListModel

    Keys.onEnterPressed: unlock()
    Keys.onReturnPressed: unlock()
    Keys.onSpacePressed: unlock()

    function unlock() { Qt.quit() }

    implicitWidth: 400
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: (typeof kscreenlocker_userName !== "undefined") ? kscreenlocker_userName : ""
            color: Qt.rgba(1, 1, 1, 0.92)
            font.family: "Inter"
            font.pixelSize: 18
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
            font.pixelSize: 15
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 52

            Rectangle {
                anchors.fill: parent
                radius: 18
                color: unlockMa.containsMouse ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.18)
                border.color: Qt.rgba(1, 1, 1, 0.5)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: "Разблокировать"
                color: "white"
                font.family: "Inter"
                font.pixelSize: 18
                font.weight: Font.Bold
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.3)
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
            font.pixelSize: 13
        }
    }

    Component.onCompleted: forceActiveFocus()
}
