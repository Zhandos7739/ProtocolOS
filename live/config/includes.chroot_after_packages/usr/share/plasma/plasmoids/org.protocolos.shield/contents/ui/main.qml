import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property var st: ({})
    property string cpuTemp: ""
    readonly property bool ok: st.clamd === "on" && st.ufw === "on" && st.blackout !== "on"
    readonly property bool blackout: st.blackout === "on"
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inDock: inPanel && Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property string statusCmd: "/usr/local/bin/protocolos-status"
    readonly property string tempCmd: "sh -c 'cat /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | sort -n | tail -n1'"
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: blackout ? "Blackout включён" : (ok ? "Защита активна" : "Требуется внимание")

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: [root.statusCmd, root.tempCmd]
        interval: 45000
        onNewData: (src, data) => {
            if (src === root.statusCmd) {
                var o = {}
                ;(data.stdout || "").split("\n").forEach(l => { var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) })
                root.st = o
            } else if (src === root.tempCmd) {
                var t = parseInt((data.stdout || "").trim())
                root.cpuTemp = (t > 1000) ? String(Math.round(t / 1000)) : ""
            } else {
                disconnectSource(src)
            }
        }
    }
    function run(cmd) { ex.connectSource(cmd) }

    // ---------- in panels ----------
    compactRepresentation: Item {
        Layout.preferredWidth: root.inDock ? height : row.implicitWidth + 4
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true

        // dock: rounded green shield icon
        Kirigami.Icon {
            visible: root.inDock
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) * 0.86; height: width
            source: root.blackout ? "protocolos-blackout" : "protocolos-shield"
        }

        // top bar: pills
        RowLayout {
            id: row
            visible: !root.inDock
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Pill {
                visible: root.cpuTemp !== ""
                fill: Qt.rgba(1, 0.55, 0.16, 0.22); line: Qt.rgba(1, 0.7, 0.43, 0.7)
                label: "ЦП " + root.cpuTemp + "°C"; glyph: "temperature-normal"
            }
            Pill {
                fill: root.blackout ? Qt.rgba(1, 0.16, 0.24, 0.55) : (root.ok ? Qt.rgba(0.31, 1, 0.67, 0.25) : Qt.rgba(1, 0.75, 0.2, 0.3))
                line: root.blackout ? "#ff8a95" : (root.ok ? Qt.rgba(0.55, 1, 0.78, 0.6) : Qt.rgba(1, 0.85, 0.5, 0.7))
                label: root.blackout ? "BLACKOUT" : (root.ok ? "Защита активна" : "Внимание")
                glyph: root.blackout ? "network-offline" : "security-high"
            }
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    component Pill: Rectangle {
        property alias label: lbl.text
        property alias glyph: ic.source
        property color fill
        property color line
        implicitWidth: pr.implicitWidth + 22
        implicitHeight: 24
        radius: 12
        color: fill; border.color: line; border.width: 1
        RowLayout { id: pr; anchors.centerIn: parent; spacing: 5
            Kirigami.Icon { id: ic; Layout.preferredWidth: 15; Layout.preferredHeight: 15; isMask: true; color: "white" }
            Text { id: lbl; color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold }
        }
    }

    // ---------- desktop card / popup ----------
    fullRepresentation: Rectangle {
        id: card
        Layout.preferredWidth: Kirigami.Units.gridUnit * 40
        Layout.preferredHeight: Kirigami.Units.gridUnit * 14
        Layout.minimumWidth: 420
        Layout.minimumHeight: 170
        // everything scales with the card height so it fits on 1024x768 too
        readonly property real u: Math.max(0.62, Math.min(1.25, Math.min(height / 260, width / 820)))
        radius: 26 * u
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.28) }
            GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.08) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.45); border.width: 1

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 22 * card.u; spacing: 16 * card.u
            RowLayout {
                spacing: 16 * card.u; Layout.fillWidth: true
                Kirigami.Icon {
                    source: root.blackout ? "protocolos-blackout" : "protocolos-shield"
                    Layout.preferredWidth: 60 * card.u; Layout.preferredHeight: 60 * card.u
                }
                ColumnLayout { spacing: 2
                    Text { color: "white"; font.bold: true; font.pixelSize: 25 * card.u
                        text: root.blackout ? "Blackout включён" : (root.ok ? "Защита активна" : "Требуется внимание") }
                    Text { color: Qt.rgba(1, 1, 1, 0.85); font.pixelSize: 15 * card.u
                        text: "ClamAV: базы " + (root.st.db || "—") }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: card.width > 640
                    implicitWidth: rt.implicitWidth + 24 * card.u; implicitHeight: 28 * card.u; radius: height / 2
                    color: Qt.rgba(0.31, 1, 0.67, 0.25); border.color: Qt.rgba(0.55, 1, 0.78, 0.6)
                    Text { id: rt; anchors.centerIn: parent; color: "white"; font.pixelSize: 14 * card.u
                        text: "● Реальное время " + (root.st.realtime === "on" ? "вкл" : "выкл") }
                }
                Text { text: "Блэкаут"; color: "white"; font.pixelSize: 15 * card.u; font.weight: Font.DemiBold }
                Rectangle {
                    id: tg
                    implicitWidth: 52 * card.u; implicitHeight: 30 * card.u; radius: height / 2
                    color: root.blackout ? "#e11d48" : Qt.rgba(1, 1, 1, 0.25)
                    border.color: Qt.rgba(1, 1, 1, 0.5)
                    Rectangle {
                        width: parent.height - 6; height: width; radius: width / 2; color: "white"
                        y: 3; x: root.blackout ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 160 } }
                    }
                    MouseArea { anchors.fill: parent
                        onClicked: root.run("pkexec /usr/local/bin/protocolos-blackout " + (root.blackout ? "off" : "on")) }
                }
            }
            GridLayout {
                columns: 4; Layout.fillWidth: true; Layout.fillHeight: true
                columnSpacing: 12 * card.u
                Repeater {
                    model: [
                        [root.st.realtime === "on" ? "Вкл" : "Выкл", "Реальное время", "clamonacc"],
                        [root.st.lastscan || "—", "Посл. проверка", "ClamTk"],
                        [(root.st.apparmor || "0"), "Песочницы", "AppArmor"],
                        [root.st.ufw === "on" ? "Вкл" : "Выкл", "Межсет. экран", "ufw · OpenSnitch " + (root.st.opensnitch === "on" ? "вкл" : "выкл")]
                    ]
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        radius: 16 * card.u
                        color: Qt.rgba(1, 1, 1, 0.15); border.color: Qt.rgba(1, 1, 1, 0.3)
                        ColumnLayout { anchors.fill: parent; anchors.margins: 12 * card.u; spacing: 1
                            Text { text: modelData[0]; color: "white"; font.bold: true; font.pixelSize: 21 * card.u }
                            Text { text: modelData[1]; color: "white"; font.pixelSize: 14 * card.u
                                Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: modelData[2]; color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12 * card.u
                                Layout.fillWidth: true; elide: Text.ElideRight }
                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }
        }
    }
}
