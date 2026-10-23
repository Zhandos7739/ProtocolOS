import QtQuick
import org.kde.plasma.plasmoid
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property bool folders: Plasmoid.configuration.mode === "folders"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property var apps: [
        ["firefox", "Firefox", "Браузер", "firefox-esr"],
        ["terminal", "Терминал", "Система", "konsole"],
        ["files", "Файлы", "Менеджер", "dolphin"],
        ["settings", "Настройки", "Система", "systemsettings"],
        ["store", "Магазин", "Приложения", "plasma-discover"],
        ["antivirus", "Защита", "ClamAV · Антивирус", "clamtk"],
        ["discord", "Discord", "Мессенджер", "flatpak run com.discordapp.Discord || plasma-discover --search discord"],
        ["record", "Запись экрана", "Kooha", "kooha"],
        ["kdenlive", "Kdenlive", "Видеоредактор", "kdenlive"],
        ["blackout", "Blackout", "Отключить сеть", "konsole --hold -e /usr/local/bin/protocolos-blackout toggle"],
        ["network", "Сетевой монитор", "OpenSnitch", "opensnitch-ui"]
    ]
    readonly property var dirs: [
        ["f-projects", "Проекты", "", "d=$(xdg-user-dir DOCUMENTS)/Проекты; mkdir -p \"$d\"; xdg-open \"$d\""],
        ["f-docs", "Документы", "", "xdg-open \"$(xdg-user-dir DOCUMENTS)\""],
        ["f-down", "Загрузки", "", "xdg-open \"$(xdg-user-dir DOWNLOAD)\""],
        ["f-pics", "Изображения", "", "xdg-open \"$(xdg-user-dir PICTURES)\""],
        ["f-system", "Система", "", "dolphin /"],
        ["f-trash", "Корзина", "", "dolphin trash:/"]
    ]
    readonly property var items: folders ? dirs : apps

    P5Support.DataSource {
        id: ex; engine: "executable"
        onNewData: (src, data) => disconnectSource(src)
    }
    function launch(cmd) {
        ex.connectSource("setsid -f sh -c '" + cmd.replace(/'/g, "'\\''") + "' >/dev/null 2>&1")
    }

    fullRepresentation: Item {
        id: area
        Layout.minimumWidth: 100
        Layout.minimumHeight: 100
        // pick the biggest square cell (<=150px) so that all items fit into the widget
        readonly property int n: root.items.length
        readonly property real gap: Math.max(8, Math.min(width, height) * 0.02)
        readonly property real cell: {
            if (root.folders) return Math.max(48, Math.min(130, width, height / n - gap))
            var best = 48
            for (var c = 1; c <= n; c++) {
                var r = Math.ceil(n / c)
                var s = Math.min((width - (c - 1) * gap) / c, (height - (r - 1) * gap) / r / 1.12)
                if (s > best) best = s
            }
            return Math.min(150, best)
        }
        readonly property int cols: root.folders ? 1 : Math.max(1, Math.floor((width + gap) / (cell + gap)))

        Grid {
            columns: area.cols
            spacing: area.gap
            anchors.top: parent.top
            anchors.left: root.folders ? undefined : parent.left
            anchors.horizontalCenter: root.folders ? parent.horizontalCenter : undefined
            Repeater {
                model: root.items
                delegate: root.folders ? folderTile : appTile
            }
        }

        Component {
            id: appTile
            Rectangle {
                width: area.cell; height: area.cell * 1.12
                radius: Math.round(area.cell * 0.13)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.36 : 0.26) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.16 : 0.08) }
                }
                border.color: Qt.rgba(1, 1, 1, 0.45); border.width: 1
                scale: ma.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                Column {
                    anchors.centerIn: parent
                    spacing: area.cell * 0.05
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "protocolos-" + modelData[0]
                        width: area.cell * 0.52; height: width
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: area.cell - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        text: modelData[1]; color: "white"; font.bold: true
                        font.pixelSize: Math.max(10, area.cell * 0.115)
                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.35)
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: area.cell - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                        text: modelData[2]; color: Qt.rgba(1, 1, 1, 0.8)
                        font.pixelSize: Math.max(8, area.cell * 0.085)
                    }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: root.launch(modelData[3]) }
            }
        }

        Component {
            id: folderTile
            Item {
                width: area.cell; height: area.cell
                scale: fm.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                Kirigami.Icon {
                    id: fi
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "protocolos-" + modelData[0]
                    width: area.cell * 0.68; height: width
                    opacity: fm.containsMouse ? 1 : 0.93
                }
                Text {
                    anchors.top: fi.bottom; anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData[1]; color: "white"; font.bold: true
                    font.pixelSize: Math.max(10, area.cell * 0.13)
                    style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.5)
                }
                MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; onClicked: root.launch(modelData[3]) }
            }
        }
    }
}
