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
    readonly property bool ok: st.clamd === "on" && st.ufw === "on" && st.blackout !== "on"
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: ["/usr/local/bin/protocolos-status"]
        interval: 15000
        onNewData: (src, data) => {
            if (src !== "/usr/local/bin/protocolos-status") { disconnectSource(src); return }
            var o = {}; (data.stdout || "").split("\n").forEach(l => { var i = l.indexOf("="); if (i > 0) o[l.slice(0,i)] = l.slice(i+1) }); root.st = o
        }
    }
    function run(cmd) { ex.connectSource(cmd) }

    compactRepresentation: Rectangle {
        Layout.preferredWidth: row.implicitWidth + 16
        Layout.fillHeight: true
        radius: height / 2
        color: root.ok ? Qt.rgba(0.18,0.83,0.66,0.22) : Qt.rgba(0.95,0.3,0.3,0.28)
        border.color: root.ok ? Qt.rgba(0.18,0.83,0.66,0.6) : Qt.rgba(0.95,0.3,0.3,0.6)
        RowLayout { id: row; anchors.centerIn: parent; spacing: 4
            Kirigami.Icon { source: root.ok ? "security-high" : "security-low"; Layout.preferredWidth: 16; Layout.preferredHeight: 16 }
            PC3.Label { text: root.st.blackout === "on" ? "Blackout" : (root.ok ? "Защита активна" : "Внимание"); font.pointSize: 9 }
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    fullRepresentation: Rectangle {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 34
        Layout.preferredHeight: Kirigami.Units.gridUnit * 13
        radius: 22
        color: Qt.rgba(1,1,1,0.10)
        border.color: Qt.rgba(1,1,1,0.28)
        ColumnLayout { anchors.fill: parent; anchors.margins: 18; spacing: 12
            RowLayout { spacing: 12
                Rectangle { width: 44; height: 44; radius: 12; color: "#22b38a"
                    Kirigami.Icon { anchors.centerIn: parent; source: "security-high"; width: 28; height: 28 } }
                ColumnLayout { spacing: 0
                    PC3.Label { text: root.ok ? "Защита активна" : "Требуется внимание"; font.pointSize: 15; font.bold: true }
                    PC3.Label { text: "ClamAV: базы " + (root.st.db || "—"); opacity: 0.7 } }
                Item { Layout.fillWidth: true }
                PC3.Label { text: "Блэкаут" }
                PC3.Switch { checked: root.st.blackout === "on"; onToggled: root.run("pkexec /usr/local/bin/protocolos-blackout " + (checked ? "on" : "off")) }
            }
            GridLayout { columns: 4; Layout.fillWidth: true; columnSpacing: 10
                Repeater {
                    model: [
                        [root.st.realtime === "on" ? "Вкл" : "Выкл", "Реальное время", "clamonacc"],
                        [root.st.lastscan || "—", "Посл. проверка", "ClamTk"],
                        [(root.st.apparmor || "0"), "Профили", "AppArmor"],
                        [root.st.ufw === "on" ? "Вкл" : "Выкл", "Межсет. экран", "ufw · OpenSnitch " + (root.st.opensnitch === "on" ? "вкл" : "выкл")]
                    ]
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 70; radius: 12
                        color: Qt.rgba(1,1,1,0.08); border.color: Qt.rgba(1,1,1,0.18)
                        ColumnLayout { anchors.fill: parent; anchors.margins: 8; spacing: 0
                            PC3.Label { text: modelData[0]; font.bold: true; font.pointSize: 12 }
                            PC3.Label { text: modelData[1]; opacity: 0.8; font.pointSize: 8 }
                            PC3.Label { text: modelData[2]; opacity: 0.6; font.pointSize: 8 } } }
                }
            }
        }
    }
}
