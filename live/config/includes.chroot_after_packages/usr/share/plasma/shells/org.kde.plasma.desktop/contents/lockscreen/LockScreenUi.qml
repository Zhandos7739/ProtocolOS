/*
    ProtocolOS lock — pixel layout from HTML mockup glass language
    (lock.html @1920×1080: bar 16/12/44 r22, clock 128px, card 460×@560).
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
    // Scale from HTML mockup base 1920×1080
    readonly property real s: Math.min(width / 1920, height / 1080)

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
            if (kind != 0) return;
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
                    { userListModel: users, scaleFactor: lockScreenUi.s }, StackView.Immediate);
                mainStack.forceActiveFocus();
            }
        }
        function onInfoMessageChanged() { lockScreenUi.handleMessage(authenticator.infoMessage); }
        function onErrorMessageChanged() { lockScreenUi.handleMessage(authenticator.errorMessage); }
        function onPromptChanged(msg) { lockScreenUi.handleMessage(authenticator.prompt); }
        function onPromptForSecretChanged(msg) {
            mainBlock.showPassword = false;
            mainBlock.mainPasswordBox.forceActiveFocus();
        }
    }

    SessionManagement { id: sessionManagement }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }
    Connections {
        target: sessionManagement
        function onAboutToSuspend() { root.clearPassword(); }
    }
    RejectPasswordAnimation { id: rejectPasswordAnimation; target: unlockCard }

    P5Support.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: ["Local"]
        interval: 1000
    }

    MouseArea {
        id: lockScreenRoot
        property bool uiVisible: true
        property bool blockUI: containsMouse && (mainStack.depth > 1 || mainBlock.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive)

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        drag.filterChildren: true
        onPressed: uiVisible = true
        onPositionChanged: uiVisible = true
        onUiVisibleChanged: {
            if (blockUI) fadeoutTimer.running = false;
            else if (uiVisible) fadeoutTimer.restart();
            authenticator.startAuthenticating();
        }
        onBlockUIChanged: {
            if (blockUI) { fadeoutTimer.running = false; uiVisible = true; }
            else fadeoutTimer.restart();
        }
        Keys.onEscapePressed: {
            if (inputPanel.keyboardActive) inputPanel.showHide();
            root.clearPassword();
        }
        Keys.onPressed: event => { uiVisible = true; event.accepted = false; }

        Timer {
            id: fadeoutTimer
            interval: 120000
            onTriggered: {
                if (!lockScreenRoot.blockUI && mainBlock && mainBlock.mainPasswordBox)
                    mainBlock.mainPasswordBox.showPassword = false;
            }
        }
        Timer { id: notificationRemoveTimer; interval: 3000; onTriggered: root.notification = "" }
        Timer {
            id: graceLockTimer
            interval: 3000
            onTriggered: { root.clearPassword(); authenticator.startAuthenticating(); }
        }

        PropertyAnimation {
            id: launchAnimation
            target: lockScreenRoot
            property: "opacity"
            from: 0; to: 1
            duration: Kirigami.Units.veryLongDuration * 2
        }
        Component.onCompleted: { launchAnimation.start(); authenticator.startAuthenticating(); }

        // Keep WallpaperFader hooked so stock wallpaper item stays valid,
        // but force "on" and hide its opacity games on our chrome.
        WallpaperFader {
            anchors.fill: parent
            z: 0
            state: "on"
            source: wallpaper
            mainStack: mainStack
            footer: footer
            clock: topBar
            opacity: 0
        }

        // HTML .dim
        Rectangle {
            anchors.fill: parent
            z: 1
            color: Qt.rgba(10/255, 0, 30/255, 0.18)
        }

        // Soft wave wash (same paths as HTML mockup) — lightweight white arcs
        Canvas {
            anchors.fill: parent
            z: 1
            opacity: 0.55
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var sx = width / 1920, sy = height / 1080;
                ctx.fillStyle = "rgba(255,255,255,0.08)";
                ctx.beginPath();
                ctx.moveTo(0, 700 * sy);
                ctx.bezierCurveTo(400 * sx, 450 * sy, 800 * sx, 950 * sy, 1200 * sx, 640 * sy);
                ctx.bezierCurveTo(1600 * sx, 380 * sy, 1800 * sx, 380 * sy, 1920 * sx, 520 * sy);
                ctx.lineTo(width, height); ctx.lineTo(0, height); ctx.closePath(); ctx.fill();
                ctx.strokeStyle = "rgba(255,255,255,0.22)";
                ctx.lineWidth = 2.5 * s;
                ctx.beginPath();
                ctx.moveTo(0, 700 * sy);
                ctx.bezierCurveTo(400 * sx, 450 * sy, 800 * sx, 950 * sy, 1200 * sx, 640 * sy);
                ctx.bezierCurveTo(1600 * sx, 380 * sy, 1800 * sx, 380 * sy, 1920 * sx, 520 * sy);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(0, 380 * sy);
                ctx.bezierCurveTo(500 * sx, 200 * sy, 900 * sx, 600 * sy, 1400 * sx, 360 * sy);
                ctx.bezierCurveTo(1625 * sx, 250 * sy, 1850 * sx, 250 * sy, 1920 * sx, 300 * sy);
                ctx.stroke();
            }
            onWidthChanged: requestPaint(); onHeightChanged: requestPaint()
        }

        // HTML .glass.bar — left:16 right:16 top:12 height:44 radius:22
        Item {
            id: topBar
            z: 3
            x: Math.round(16 * lockScreenUi.s)
            y: Math.round(12 * lockScreenUi.s)
            width: parent.width - 2 * x
            height: Math.round(44 * lockScreenUi.s)

            GlassCard {
                anchors.fill: parent
                radius: Math.round(22 * lockScreenUi.s)
                wallLayer: wallpaper
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(22 * lockScreenUi.s)
                anchors.rightMargin: Math.round(22 * lockScreenUi.s)
                spacing: Math.round(22 * lockScreenUi.s)

                Text {
                    text: "◆ ProtocolOS"
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: Math.round(19 * lockScreenUi.s)
                    font.weight: Font.Bold
                }
                Text {
                    text: "Блокировка"
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.family: "Inter"
                    font.pixelSize: Math.round(17 * lockScreenUi.s)
                    font.weight: Font.Medium
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredHeight: Math.round(28 * lockScreenUi.s)
                    Layout.preferredWidth: pillTxt.implicitWidth + Math.round(24 * lockScreenUi.s)
                    radius: Math.round(14 * lockScreenUi.s)
                    color: Qt.rgba(80/255, 1, 170/255, 0.25)
                    border.color: Qt.rgba(140/255, 1, 200/255, 0.6)
                    border.width: 1
                    Text {
                        id: pillTxt
                        anchors.centerIn: parent
                        text: "Защита активна"
                        color: "white"
                        font.family: "Inter"
                        font.pixelSize: Math.round(15 * lockScreenUi.s)
                        font.weight: Font.DemiBold
                    }
                }
                Text {
                    text: "RU"
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: Math.round(17 * lockScreenUi.s)
                    font.weight: Font.DemiBold
                }
                Text {
                    text: Qt.formatDateTime(timeSource.data["Local"]["DateTime"], "ddd, d MMM  HH:mm")
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: Math.round(17 * lockScreenUi.s)
                    font.weight: Font.DemiBold
                }
            }
        }

        // Center brand + clock — HTML .center top:210
        Column {
            id: clockCol
            z: 3
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(210 * lockScreenUi.s)
            width: Math.round(520 * lockScreenUi.s)
            spacing: Math.round(8 * lockScreenUi.s)

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "◆ ProtocolOS"
                color: "white"
                font.family: "Inter"
                font.pixelSize: Math.round(22 * lockScreenUi.s)
                font.weight: Font.Bold
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(timeSource.data["Local"]["DateTime"], "HH:mm")
                color: "white"
                font.family: "Inter"
                font.pixelSize: Math.round(128 * lockScreenUi.s)
                font.weight: Font.Light
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(timeSource.data["Local"]["DateTime"], lockScreenUi.ru, "dddd, d MMMM")
                color: Qt.rgba(1, 1, 1, 0.90)
                font.family: "Inter"
                font.pixelSize: Math.round(24 * lockScreenUi.s)
                font.weight: Font.Medium
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.35)
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

        // HTML .glass.card — width 460, top 560, padding 28
        Item {
            id: unlockCard
            z: 4
            width: Math.round(460 * lockScreenUi.s)
            height: Math.max(Math.round(180 * lockScreenUi.s),
                             (mainStack.currentItem ? mainStack.currentItem.implicitHeight : 140) + Math.round(52 * lockScreenUi.s))
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(560 * lockScreenUi.s)
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            GlassCard {
                anchors.fill: parent
                radius: Math.round(28 * lockScreenUi.s)
                wallLayer: wallpaper
            }

            StackView {
                id: mainStack
                anchors.fill: parent
                anchors.margins: Math.round(28 * lockScreenUi.s)
                focus: true
                visible: true

                initialItem: MainBlock {
                    id: mainBlock
                    lockScreenUiVisible: true
                    showUserList: false
                    enabled: !graceLockTimer.running
                    userListModel: users
                    width: mainStack.width
                    scaleFactor: lockScreenUi.s

                    StackView.onStatusChanged: {
                        if (StackView.status === StackView.Activating) {
                            mainPasswordBox.clear();
                            mainPasswordBox.focus = true;
                            root.notification = "";
                        }
                    }

                    notificationMessage: {
                        const parts = [];
                        if (capsLockState.locked) parts.push("Caps Lock включён");
                        if (root.notification) parts.push(root.notification);
                        return parts.join(" · ");
                    }

                    onPasswordResult: password => authenticator.respond(password)

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
            z: 5
            screenRoot: lockScreenRoot
            mainStack: mainStack
            mainBlock: mainBlock
            passwordField: mainBlock.mainPasswordBox
        }

        Loader {
            z: 5
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Kirigami.Units.gridUnit
        }

        // Minimal footer (keyboard) — no Breeze chrome clutter
        RowLayout {
            id: footer
            z: 4
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                margins: Math.round(16 * lockScreenUi.s)
            }
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                id: virtualKeyboardButton
                focusPolicy: Qt.TabFocus
                text: "Клавиатура"
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                onClicked: {
                    mainBlock.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide();
                }
                visible: inputPanel.status === Loader.Ready
                Layout.fillHeight: true
            }

            PlasmaComponents3.ToolButton {
                id: keyboardButton
                focusPolicy: Qt.TabFocus
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
            }

            Item { Layout.fillWidth: true }
            Battery {}
        }
    }
}
