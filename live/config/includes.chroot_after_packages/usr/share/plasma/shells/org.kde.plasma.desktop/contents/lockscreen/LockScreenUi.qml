/*
    ProtocolOS Liquid Glass lock screen — always-visible UI matching the HTML desktop language.
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.plasma5support as P5Support

import org.kde.plasma.private.sessions
import org.kde.breeze.components

Item {
    id: lockScreenUi

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property var ru: Qt.locale("ru_RU")

    function handleMessage(msg) {
        if (!root.notification) {
            root.notification += msg;
        } else if (root.notification.includes(msg)) {
            root.notificationRepeated();
        } else {
            root.notification += "\n" + msg
        }
    }

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) {
                return;
            }
            lockScreenUi.handleMessage("Неверный пароль");
            graceLockTimer.restart();
            notificationRemoveTimer.restart();
            rejectPasswordAnimation.start();
        }

        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                mainStack.replace(null, Qt.resolvedUrl("NoPasswordUnlock.qml"),
                    { userListModel: users },
                    StackView.Immediate,
                );
                mainStack.forceActiveFocus();
            }
        }

        function onInfoMessageChanged() {
            lockScreenUi.handleMessage(authenticator.infoMessage);
        }

        function onErrorMessageChanged() {
            lockScreenUi.handleMessage(authenticator.errorMessage);
        }

        function onPromptChanged(msg) {
            lockScreenUi.handleMessage(authenticator.prompt);
        }
        function onPromptForSecretChanged(msg) {
            mainBlock.showPassword = false;
            mainBlock.mainPasswordBox.forceActiveFocus();
        }
    }

    SessionManagement {
        id: sessionManagement
    }

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            root.clearPassword();
        }
    }

    RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: glassCard
    }

    MouseArea {
        id: lockScreenRoot

        // Always show ProtocolOS chrome — stock Breeze starts hidden and feels like a skip.
        property bool uiVisible: true
        property bool seenPositionChange: false
        property bool blockUI: containsMouse && (mainStack.depth > 1 || mainBlock.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive)

        x: parent.x
        y: parent.y
        width: parent.width
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: {
            uiVisible = true;
            seenPositionChange = true;
        }
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
            authenticator.startAuthenticating();
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }
        Keys.onEscapePressed: {
            if (inputPanel.keyboardActive) {
                inputPanel.showHide();
            }
            root.clearPassword();
        }
        Keys.onPressed: event => {
            uiVisible = true;
            event.accepted = false;
        }

        Timer {
            id: fadeoutTimer
            interval: 120000
            onTriggered: {
                // Keep clock/brand; only clear password reveal after long idle.
                if (!lockScreenRoot.blockUI && mainBlock && mainBlock.mainPasswordBox) {
                    mainBlock.mainPasswordBox.showPassword = false;
                }
            }
        }
        Timer {
            id: notificationRemoveTimer
            interval: 3000
            onTriggered: root.notification = ""
        }
        Timer {
            id: graceLockTimer
            interval: 3000
            onTriggered: {
                root.clearPassword();
                authenticator.startAuthenticating();
            }
        }

        PropertyAnimation {
            id: launchAnimation
            target: lockScreenRoot
            property: "opacity"
            from: 0
            to: 1
            duration: Kirigami.Units.veryLongDuration * 2
        }
        Component.onCompleted: {
            launchAnimation.start();
            authenticator.startAuthenticating();
        }

        // Soft dim so glass + type read on bright day wallpaper
        Rectangle {
            anchors.fill: parent
            z: 0
            color: Qt.rgba(10/255, 0, 30/255, 0.22)
        }

        WallpaperFader {
            anchors.fill: parent
            z: 0
            state: "on"
            source: wallpaper
            mainStack: mainStack
            footer: footer
            clock: brandBlock
        }

        ColumnLayout {
            id: brandBlock
            z: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.10)
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "◆ ProtocolOS"
                color: "white"
                font.family: "Inter"
                font.pixelSize: Math.max(22, Math.round(parent.parent.height * 0.028))
                font.weight: Font.Bold
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(timeSource.data["Local"]["DateTime"], "HH:mm")
                color: "white"
                font.family: "Inter"
                font.pixelSize: Math.max(64, Math.round(parent.parent.height * 0.12))
                font.weight: Font.Light
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(timeSource.data["Local"]["DateTime"], lockScreenUi.ru, "dddd, d MMMM")
                color: Qt.rgba(1, 1, 1, 0.88)
                font.family: "Inter"
                font.pixelSize: Math.max(16, Math.round(parent.parent.height * 0.022))
                font.weight: Font.Medium
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.3)
            }

            P5Support.DataSource {
                id: timeSource
                engine: "time"
                connectedSources: ["Local"]
                interval: 1000
            }
        }

        ListModel {
            id: users
            Component.onCompleted: {
                users.append({
                    name: kscreenlocker_userName,
                    realName: kscreenlocker_userName,
                    icon: kscreenlocker_userImage !== ""
                          ? "file://" + kscreenlocker_userImage.split("/").map(encodeURIComponent).join("/")
                          : "",
                })
            }
        }

        Item {
            id: glassCard
            z: 2
            width: Math.min(parent.width - 48, 460)
            height: Math.max(160, (mainStack.currentItem ? mainStack.currentItem.implicitHeight : 160) + 48)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: brandBlock.bottom
            anchors.topMargin: Math.round(parent.height * 0.06)
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            GlassCard {
                anchors.fill: parent
                radius: 28
            }

            StackView {
                id: mainStack
                anchors.fill: parent
                anchors.margins: 24
                focus: true
                visible: opacity > 0

                initialItem: MainBlock {
                    id: mainBlock
                    lockScreenUiVisible: true
                    showUserList: false
                    enabled: !graceLockTimer.running
                    userListModel: users
                    width: mainStack.width

                    StackView.onStatusChanged: {
                        if (StackView.status === StackView.Activating) {
                            mainPasswordBox.clear();
                            mainPasswordBox.focus = true;
                            root.notification = "";
                        }
                    }

                    notificationMessage: {
                        const parts = [];
                        if (capsLockState.locked) {
                            parts.push("Caps Lock включён");
                        }
                        if (root.notification) {
                            parts.push(root.notification);
                        }
                        return parts.join(" · ");
                    }

                    onPasswordResult: password => {
                        authenticator.respond(password)
                    }

                    actionItems: [
                        ActionButton {
                            text: "Сон"
                            icon.name: "system-suspend"
                            onClicked: root.suspendToRam()
                            visible: root.suspendToRamSupported
                        },
                        ActionButton {
                            text: "Гибернация"
                            icon.name: "system-suspend-hibernate"
                            onClicked: root.suspendToDisk()
                            visible: root.suspendToDiskSupported
                        },
                        ActionButton {
                            text: "Сменить пользователя"
                            icon.name: "system-switch-user"
                            onClicked: sessionManagement.switchUser()
                            visible: sessionManagement.canSwitchUser
                        }
                    ]
                }
            }
        }

        VirtualKeyboardLoader {
            id: inputPanel
            z: 3
            screenRoot: lockScreenRoot
            mainStack: mainStack
            mainBlock: mainBlock
            passwordField: mainBlock.mainPasswordBox
        }

        Loader {
            z: 4
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.gridUnit
            }
        }

        RowLayout {
            id: footer
            z: 3
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.smallSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                id: virtualKeyboardButton
                focusPolicy: Qt.TabFocus
                text: "Клавиатура"
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                onClicked: {
                    mainBlock.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide()
                }
                visible: inputPanel.status === Loader.Ready
                Layout.fillHeight: true
                containmentMask: Item {
                    parent: virtualKeyboardButton
                    anchors.fill: parent
                    anchors.leftMargin: -footer.anchors.margins
                    anchors.bottomMargin: -footer.anchors.margins
                }
            }

            PlasmaComponents3.ToolButton {
                id: keyboardButton
                focusPolicy: Qt.TabFocus
                Accessible.description: "Сменить раскладку"
                icon.name: "input-keyboard"
                PW.KeyboardLayoutSwitcher {
                    id: keyboardLayoutSwitcher
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }
                text: keyboardLayoutSwitcher.layoutNames.longName
                onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()
                visible: keyboardLayoutSwitcher.hasMultipleKeyboardLayouts
                Layout.fillHeight: true
                containmentMask: Item {
                    parent: keyboardButton
                    anchors.fill: parent
                    anchors.leftMargin: virtualKeyboardButton.visible ? 0 : -footer.anchors.margins
                    anchors.bottomMargin: -footer.anchors.margins
                }
            }

            Item { Layout.fillWidth: true }
            Battery {}
        }
    }
}
