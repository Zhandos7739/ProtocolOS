import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property bool connected: false
    property string activeName: ""
    property string selected: ""
    property int profileCount: 0
    property var profiles: []
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "VPN"
    toolTipSubText: connected
        ? ("Подключено: " + activeName)
        : (profileCount ? ("Выкл · профилей: " + profileCount + " · клик — вкл/выкл") : "Нет профилей · ПКМ — настройки")

    readonly property string statusCmd: "/usr/local/bin/protocolos-vpn status #v"
    readonly property string listCmd: "/usr/local/bin/protocolos-vpn list #l"

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: [root.statusCmd]
        interval: 3000
        onNewData: (src, data) => {
            var out = data.stdout || ""
            if (src.indexOf("protocolos-vpn status") >= 0) {
                var o = {}
                out.split("\n").forEach(l => {
                    var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                })
                root.connected = o.connected === "1"
                root.activeName = o.active || ""
                root.selected = o.selected || ""
                root.profileCount = parseInt(o.profiles || "0") || 0
            } else if (src.indexOf("protocolos-vpn list") >= 0) {
                var ps = []
                out.split("\n").forEach(l => {
                    if (l.indexOf("profile=") === 0) ps.push(l.slice(8))
                })
                root.profiles = ps
            } else {
                disconnectSource(src)
                disconnectSource(root.statusCmd); connectSource(root.statusCmd)
            }
        }
    }
    function run(cmd) { ex.connectSource(cmd + " #" + Date.now()) }
    function refreshList() { ex.connectSource(root.listCmd + Date.now()) }

    compactRepresentation: Item {
        Layout.preferredWidth: 28
        Layout.minimumWidth: 28
        Layout.fillHeight: true
        Rectangle {
            anchors.fill: parent; radius: 8
            color: root.connected
                 ? (ma.containsMouse ? Qt.rgba(0.2, 0.85, 0.55, 0.45) : Qt.rgba(0.15, 0.75, 0.5, 0.32))
                 : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10))
            border.color: root.connected ? Qt.rgba(0.4, 1, 0.75, 0.9) : Qt.rgba(1, 1, 1, 0.35)
            border.width: root.connected ? 2 : 1
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18; height: 18
            source: root.connected ? "protocolos-vpn" : "protocolos-vpn-off"
        }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: (m) => {
                if (m.button === Qt.RightButton) { root.expanded = true; root.refreshList(); return }
                root.run("/usr/local/bin/protocolos-vpn toggle")
            }
            onPressAndHold: { root.expanded = true; root.refreshList() }
        }
        QQC2.ToolTip.visible: ma.containsMouse
        QQC2.ToolTip.delay: 400
        QQC2.ToolTip.text: root.toolTipSubText
    }

    fullRepresentation: Rectangle {
        Layout.preferredWidth: 320
        Layout.preferredHeight: 380
        color: Qt.rgba(0.08, 0.1, 0.14, 0.92)
        radius: 12
        border.color: Qt.rgba(1, 1, 1, 0.15)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Kirigami.Icon {
                    width: 28; height: 28
                    source: root.connected ? "protocolos-vpn" : "protocolos-vpn-off"
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text {
                        text: "VPN · ProtocolOS"
                        color: "white"; font.pixelSize: 15; font.bold: true
                    }
                    Text {
                        text: root.connected ? ("Онлайн: " + root.activeName) : "Отключено (как Happ)"
                        color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 12
                    }
                }
            }

            QQC2.Button {
                Layout.fillWidth: true
                text: root.connected ? "Отключить" : "Подключить"
                onClicked: root.run("/usr/local/bin/protocolos-vpn toggle")
            }

            Text {
                text: "Серверы / профили"
                color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 11; font.bold: true
            }

            ListView {
                id: lv
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.profiles
                spacing: 4
                delegate: Rectangle {
                    width: lv.width; height: 36; radius: 8
                    color: (modelData === root.selected || modelData === root.activeName)
                         ? Qt.rgba(0.2, 0.6, 1, 0.28) : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: "white"; font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.run("/usr/local/bin/protocolos-vpn set-active " + modelData)
                            root.run("/usr/local/bin/protocolos-vpn connect " + modelData)
                        }
                    }
                }
            }

            RowLayout {
                QQC2.Button {
                    Layout.fillWidth: true
                    text: "Настройки…"
                    onClicked: root.run("/usr/local/bin/protocolos-vpn-settings")
                }
                QQC2.Button {
                    text: "↻"
                    QQC2.ToolTip.text: "Обновить подписку"
                    onClicked: root.run("/usr/local/bin/protocolos-vpn update-sub")
                }
            }
        }

        Component.onCompleted: root.refreshList()
        onVisibleChanged: if (visible) root.refreshList()
    }
}
