import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// Protection card for the desktop (same data as org.protocolos.shield).
Item {
    id: card
    property url wallpaper: ""
    property Item wallLayer: null
    property real wallW: 1920
    property real wallH: 1080
    property bool animate: true
    property var st: ({})
    readonly property bool blackout: st.blackout === "on"
    readonly property bool ok: st.clamd === "on" && st.ufw === "on" && !blackout
    // mockup: 820x270 at 1920x1080 — every size below is scaled from that
    readonly property real u: Math.max(0.3, Math.min(1.4, height / 270, width / 820))
    readonly property string statusCmd: "/usr/local/bin/protocolos-status"
    function run(cmd) { ex.connectSource("setsid -f sh -c '" + cmd.replace(/'/g, "'\\''") + "' >/dev/null 2>&1; true #" + Date.now()) }
    function toggleBlackout() {
        var on = !card.blackout
        ex.connectSource("pkexec /usr/local/bin/protocolos-blackout " + (on ? "on" : "off")
            + " && notify-send -a ProtocolOS -i " + (on ? "protocolos-blackout 'Blackout включён' 'Вся сеть отключена'" : "protocolos-shield 'Blackout выключен' 'Сеть восстановлена'"))
    }

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: [card.statusCmd]
        interval: 45000
        onNewData: (src, data) => {
            if (src === card.statusCmd) {
                var o = {}
                ;(data.stdout || "").split("\n").forEach(l => { var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1) })
                card.st = o
                if (card.animate && Kirigami.Units.longDuration > 0) shDraw.restart(); else shChk.progress = 1
            } else {
                disconnectSource(src)
                // refresh right away after an action (e.g. Blackout)
                disconnectSource(card.statusCmd); connectSource(card.statusCmd)
            }
        }
    }

    Glass {
        anchors.fill: parent; radius: 28 * card.u
        wallpaper: card.wallpaper; wallLayer: card.wallLayer
        wallW: card.wallW; wallH: card.wallH
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 24 * card.u; spacing: 20 * card.u
        RowLayout {
            Layout.fillWidth: true; spacing: 18 * card.u
            Item {
                Layout.preferredWidth: 64 * card.u; Layout.preferredHeight: 64 * card.u
                Kirigami.Icon { anchors.fill: parent; visible: card.blackout; source: "protocolos-blackout" }
                Image { id: shBase; anchors.fill: parent; visible: !card.blackout; smooth: true
                    source: Qt.resolvedUrl("../images/anim/shield-base.svg")
                    sourceSize: Qt.size(width * 2, height * 2) }
                // check mark redraws when the status refreshes
                Check { id: shChk; anchors.fill: parent; visible: !card.blackout && progress > 0.01
                    u: width / 64; w: 3; color: "#047857"; p: [26.75, 32, 30.5, 35.75, 37.25, 28.25] }
                NumberAnimation { id: shDraw; target: shChk; property: "progress"; from: 0; to: 1
                    duration: Math.max(1, Kirigami.Units.longDuration * 2.5); easing.type: Easing.OutCubic }
            }
            ColumnLayout {
                spacing: 2 * card.u; Layout.fillWidth: true
                Text { Layout.fillWidth: true; elide: Text.ElideRight
                    color: "white"; font.family: "Inter"; font.pixelSize: 26 * card.u; font.weight: Font.Bold
                    text: card.blackout ? "Blackout включён" : (card.ok ? "Защита активна" : "Требуется внимание") }
                Text { Layout.fillWidth: true; elide: Text.ElideRight
                    color: Qt.rgba(1, 1, 1, 0.85); font.family: "Inter"; font.pixelSize: 16 * card.u
                    text: card.st.db && card.st.db !== "нет"
                          ? ("ClamAV: базы обновлены · freshclam " + String(card.st.db).slice(-5))
                          : "ClamAV: базы обновляются…" }
            }
            Rectangle {
                visible: card.width > 560
                implicitWidth: rtRow.implicitWidth + 24 * card.u; implicitHeight: 30 * card.u; radius: height / 2
                color: card.st.realtime === "on" ? Qt.rgba(0.31, 1, 0.67, 0.25) : Qt.rgba(1, 0.75, 0.2, 0.25)
                border.color: card.st.realtime === "on" ? Qt.rgba(0.55, 1, 0.78, 0.6) : Qt.rgba(1, 0.85, 0.5, 0.7)
                Row { id: rtRow; anchors.centerIn: parent; spacing: 7 * card.u
                    Rectangle { width: 8 * card.u; height: width; radius: width / 2; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                    Text { color: "white"; font.family: "Inter"; font.pixelSize: 15 * card.u; font.weight: Font.Medium
                        text: "Реальное время" + (card.st.realtime === "on" ? "" : ": выкл") }
                }
            }
            Text { text: "Блэкаут: " + (card.blackout ? "вкл" : "выкл"); color: "white"; font.family: "Inter"; font.pixelSize: 15 * card.u; font.weight: Font.DemiBold
                Layout.leftMargin: 12 * card.u }
            Rectangle {
                implicitWidth: 54 * card.u; implicitHeight: 30 * card.u; radius: height / 2
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: card.blackout ? "#f43f5e" : Qt.rgba(1, 1, 1, 0.25) }
                    GradientStop { position: 1; color: card.blackout ? "#b91c1c" : Qt.rgba(1, 1, 1, 0.25) } }
                border.color: Qt.rgba(1, 1, 1, 0.5)
                Rectangle {
                    width: parent.height - 6; height: width; radius: width / 2; color: "white"
                    y: 3; x: card.blackout ? parent.width - width - 3 : 3
                    Behavior on x { NumberAnimation { duration: 160 } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: card.toggleBlackout() }
            }
        }
        GridLayout {
            columns: 4; Layout.fillWidth: true; Layout.fillHeight: true
            columnSpacing: 12 * card.u
            Repeater {
                // 4th field: action on click ("" = not clickable)
                model: [
                    [card.st.realtime === "on" ? "Вкл" : "Выкл", "Реальное время", "clamonacc", "clamtk", "Открыть ClamTk"],
                    [card.st.lastscan || "—", "Посл. проверка", "ClamTk", "konsole --hold -e clamscan -r -i --exclude-dir='^/proc' \"$HOME\"", "Проверить домашнюю папку"],
                    [card.st.apparmor || "0", "Песочницы", "AppArmor", "", ""],
                    [card.st.ufw === "on" ? "Вкл" : "Выкл", "Межсет. экран", "ufw" + (card.st.opensnitch === "on" ? " · OpenSnitch" : ""), "opensnitch-ui", "Открыть сетевой монитор"]
                ]
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                    radius: 16 * card.u
                    color: sm.containsMouse && modelData[3] ? Qt.rgba(1, 1, 1, sm.pressed ? 0.3 : 0.24) : Qt.rgba(1, 1, 1, 0.15)
                    border.color: Qt.rgba(1, 1, 1, sm.containsMouse && modelData[3] ? 0.55 : 0.3)
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; enabled: modelData[3] !== ""
                        cursorShape: Qt.PointingHandCursor; onClicked: card.run(modelData[3]) }
                    QQC2.ToolTip.visible: sm.containsMouse && modelData[4] !== ""
                    QQC2.ToolTip.delay: 600
                    QQC2.ToolTip.text: modelData[4]
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 14 * card.u; spacing: 1
                        Text { text: modelData[0]; color: "white"; font.weight: Font.Bold; font.family: "Inter"; font.pixelSize: 21 * card.u
                            Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: modelData[1]; color: "white"; font.family: "Inter"; font.pixelSize: 15 * card.u
                            Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: modelData[2]; color: "white"; font.family: "Inter"; font.pixelSize: 15 * card.u
                            Layout.fillWidth: true; elide: Text.ElideRight }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
