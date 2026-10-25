/*
    ProtocolOS glass unlock form (password path).
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

    readonly property alias mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false
    property alias showPassword: passwordBox.showPassword
    property alias notificationMessage: notificationsLabel.text
    property alias userListModel: dummyUsers.model
    property bool showUserList: false
    property alias actionItems: actionItemsLayout.children
    property alias userList: dummyUsers
    property alias actionItemsVisible: actionItemsLayout.visible

    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal passwordResult(string password)
    signal userSelected()

    implicitWidth: 400
    implicitHeight: col.implicitHeight

    function startLogin() {
        loginButton.forceActiveFocus();
        passwordResult(passwordBox.text);
    }

    function playHighlightAnimation() {
        shake.restart()
    }

    // Satisfy VirtualKeyboardLoader / stock API that touch userList
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
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Text {
            id: notificationsLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Qt.rgba(1, 0.75, 0.8, 0.95)
            font.family: "Inter"
            font.pixelSize: 14
            font.italic: true
            wrapMode: Text.WordWrap
            visible: text.length > 0
        }

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

        Item {
            id: fieldWrap
            Layout.fillWidth: true
            Layout.preferredHeight: 52

            SequentialAnimation {
                id: shake
                NumberAnimation { target: fieldWrap; property: "x"; to: -10; duration: 40 }
                NumberAnimation { target: fieldWrap; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: fieldWrap; property: "x"; to: -8; duration: 45 }
                NumberAnimation { target: fieldWrap; property: "x"; to: 0; duration: 40 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 18
                color: Qt.rgba(0, 0, 0, 0.28)
                border.color: Qt.rgba(1, 1, 1, 0.45)
                border.width: 1
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 6
                spacing: 6

                PlasmaExtras.PasswordField {
                    id: passwordBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    font.family: "Inter"
                    font.pixelSize: 17
                    placeholderText: "Пароль"
                    focus: true
                    enabled: !authenticator.graceLocked
                    cursorVisible: visible
                    text: PasswordSync.password
                    background: Item {}
                    color: "white"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.55)

                    onAccepted: {
                        if (lockScreenUiVisible) {
                            startLogin();
                        }
                    }

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
                    id: loginButton
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 40
                    Accessible.name: "Разблокировать"
                    icon.name: LayoutMirroring.enabled ? "go-previous" : "go-next"
                    onClicked: startLogin()
                    Keys.onEnterPressed: clicked()
                    Keys.onReturnPressed: clicked()
                }
            }
        }

        component FailableLabel : Text {
            id: _failableLabel
            required property int kind
            required property string label
            visible: authenticator.authenticatorTypes & kind
            text: label
            color: Qt.rgba(1, 1, 1, 0.85)
            font.family: "Inter"
            font.pixelSize: 14
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
