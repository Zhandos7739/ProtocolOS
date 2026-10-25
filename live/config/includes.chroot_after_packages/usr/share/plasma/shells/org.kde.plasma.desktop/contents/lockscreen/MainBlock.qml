/*
    ProtocolOS lock password form — matches HTML .card field/btn geometry.
    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.breeze.components

FocusScope {
    id: sessionManager

    property real scaleFactor: 1
    readonly property real s: scaleFactor

    readonly property alias mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false
    property alias showPassword: passwordBox.showPassword
    property alias notificationMessage: notificationsLabel.text
    property alias userListModel: dummyUsers.model
    property bool showUserList: false
    property alias actionItems: actionItemsLayout.children
    property alias userList: dummyUsers
    property alias actionItemsVisible: actionItemsLayout.visible

    property int visibleBoundary: mapFromItem(goBtn, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(goBtn, 0, 0).y + goBtn.height + 8

    signal passwordResult(string password)
    signal userSelected()

    implicitWidth: Math.round(404 * s)
    implicitHeight: col.implicitHeight

    function startLogin() {
        goBtn.forceActiveFocus();
        passwordResult(passwordBox.text);
    }
    function playHighlightAnimation() { shake.restart() }

    ListView {
        id: dummyUsers
        visible: false
        width: 0; height: 0
        function decrementCurrentIndex() {}
        function incrementCurrentIndex() {}
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Math.round(16 * s)

        Text {
            id: notificationsLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Qt.rgba(1, 0.75, 0.8, 0.95)
            font.family: "Inter"
            font.pixelSize: Math.round(14 * s)
            font.italic: true
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }

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

        Item {
            id: fieldWrap
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(52 * s)

            SequentialAnimation {
                id: shake
                NumberAnimation { target: fieldWrap; property: "x"; to: -10; duration: 40 }
                NumberAnimation { target: fieldWrap; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: fieldWrap; property: "x"; to: -8; duration: 45 }
                NumberAnimation { target: fieldWrap; property: "x"; to: 0; duration: 40 }
            }

            // HTML .field
            Rectangle {
                anchors.fill: parent
                radius: Math.round(18 * s)
                color: Qt.rgba(0, 0, 0, 0.28)
                border.color: Qt.rgba(1, 1, 1, 0.45)
                border.width: 1
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(18 * s)
                anchors.rightMargin: Math.round(6 * s)
                spacing: Math.round(6 * s)

                PlasmaExtras.PasswordField {
                    id: passwordBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.family: "Inter"
                    font.pixelSize: Math.round(17 * s)
                    placeholderText: "Пароль"
                    focus: true
                    enabled: !authenticator.graceLocked
                    cursorVisible: visible
                    text: PasswordSync.password
                    background: Item {}
                    color: "white"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.55)

                    onAccepted: if (lockScreenUiVisible) startLogin()

                    Connections {
                        target: root
                        function onClearPassword() {
                            passwordBox.forceActiveFocus()
                            passwordBox.text = "";
                            passwordBox.text = Qt.binding(() => PasswordSync.password);
                        }
                        function onNotificationRepeated() {
                            sessionManager.playHighlightAnimation();
                        }
                    }
                }

                Binding {
                    target: PasswordSync
                    property: "password"
                    value: passwordBox.text
                }

                PlasmaComponents3.ToolButton {
                    id: goBtn
                    Layout.preferredHeight: Math.round(40 * s)
                    Layout.preferredWidth: Math.round(40 * s)
                    Accessible.name: "Разблокировать"
                    icon.name: LayoutMirroring.enabled ? "go-previous" : "go-next"
                    onClicked: startLogin()
                    Keys.onEnterPressed: clicked()
                    Keys.onReturnPressed: clicked()
                }
            }
        }

        // HTML .btn — primary unlock affordance
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
                onClicked: startLogin()
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enter"
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: "Inter"
            font.pixelSize: Math.round(13 * s)
            font.weight: Font.Medium
        }

        component FailableLabel : Text {
            id: _failableLabel
            required property int kind
            required property string label
            visible: authenticator.authenticatorTypes & kind
            text: label
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: "Inter"
            font.pixelSize: Math.round(14 * s)
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true

            RejectPasswordAnimation {
                id: _rejectAnimation
                target: _failableLabel
                onFinished: _timer.restart()
            }
            Connections {
                target: authenticator
                function onNoninteractiveError(kind, authenticator) {
                    if (kind & _failableLabel.kind) {
                        _failableLabel.text = Qt.binding(() => authenticator.errorMessage)
                        _rejectAnimation.start()
                    }
                }
            }
            Timer {
                id: _timer
                interval: Kirigami.Units.humanMoment
                onTriggered: _failableLabel.text = Qt.binding(() => _failableLabel.label)
            }
        }

        FailableLabel {
            kind: ScreenLocker.Authenticator.Fingerprint
            label: "или отсканируйте отпечаток"
        }
        FailableLabel {
            kind: ScreenLocker.Authenticator.Smartcard
            label: "или приложите смарт-карту"
        }

        Row {
            id: actionItemsLayout
            Layout.alignment: Qt.AlignHCenter
            spacing: Kirigami.Units.largeSpacing
        }
    }
}
