import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property bool sinkMuted: false
    property bool sourceMuted: false
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Микрофон и наушники"
    toolTipSubText: (sourceMuted ? "Микрофон выкл" : "Микрофон вкл") + " · "
                    + (sinkMuted ? "Наушники выкл" : "Наушники вкл")

    readonly property string statusCmd: "/usr/local/bin/protocolos-audio status #a"

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: [root.statusCmd]
        interval: 4000
        onNewData: (src, data) => {
            if (src.indexOf("protocolos-audio status") >= 0) {
                var o = {}
                ;(data.stdout || "").split("\n").forEach(l => {
                    var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                })
                root.sinkMuted = o.sink === "1"
                root.sourceMuted = o.source === "1"
            } else {
                disconnectSource(src)
                disconnectSource(root.statusCmd); connectSource(root.statusCmd)
            }
        }
    }
    function toggle(kind) {
        ex.connectSource("/usr/local/bin/protocolos-audio " + kind + " toggle #" + Date.now())
    }

    compactRepresentation: Item {
        Layout.preferredWidth: row.implicitWidth + 8
        Layout.minimumWidth: Layout.preferredWidth
        Layout.fillHeight: true
        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            AudioBtn {
                muted: root.sourceMuted
                onIcon: "protocolos-mic"
                offIcon: "protocolos-mic-off"
                tip: muted ? "Включить микрофон" : "Выключить микрофон"
                onClicked: root.toggle("source")
            }
            AudioBtn {
                muted: root.sinkMuted
                onIcon: "protocolos-headphone"
                offIcon: "protocolos-headphone-off"
                tip: muted ? "Включить наушники" : "Выключить наушники"
                onClicked: root.toggle("sink")
            }
        }
    }

    component AudioBtn: Item {
        id: b
        property bool muted: false
        property string onIcon
        property string offIcon
        property string tip
        signal clicked()
        width: 28; height: 28
        Rectangle {
            anchors.fill: parent; radius: 8
            color: ma.containsMouse ? (b.muted ? Qt.rgba(1, 0.3, 0.35, 0.35) : Qt.rgba(1, 1, 1, 0.22))
                                    : (b.muted ? Qt.rgba(1, 0.25, 0.3, 0.22) : Qt.rgba(1, 1, 1, 0.10))
            border.color: b.muted ? Qt.rgba(1, 0.45, 0.5, 0.7) : Qt.rgba(1, 1, 1, 0.35)
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18; height: 18
            source: b.muted ? b.offIcon : b.onIcon
        }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: b.clicked()
        }
        QQC2.ToolTip.visible: ma.containsMouse
        QQC2.ToolTip.delay: 500
        QQC2.ToolTip.text: b.tip
    }

    fullRepresentation: compactRepresentation
}
