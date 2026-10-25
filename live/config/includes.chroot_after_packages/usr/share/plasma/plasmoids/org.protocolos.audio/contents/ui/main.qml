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
    property bool micUse: false
    property bool camUse: false
    property string micApps: ""
    property string camApps: ""
    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    toolTipMainText: "Микрофон, камера и наушники"
    toolTipSubText: (micUse ? "Микрофон используется: " + micApps + " · " : "")
                    + (camUse ? "Камера: " + camApps + " · " : "")
                    + (sourceMuted ? "Микрофон выкл" : "Микрофон вкл") + " · "
                    + (sinkMuted ? "Наушники выкл" : "Наушники вкл")

    readonly property string statusCmd: "/usr/local/bin/protocolos-privacy status #p"

    P5Support.DataSource {
        id: ex; engine: "executable"
        connectedSources: [root.statusCmd]
        interval: 2500
        onNewData: (src, data) => {
            if (src.indexOf("protocolos-privacy status") >= 0) {
                var o = {}
                ;(data.stdout || "").split("\n").forEach(l => {
                    var i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1)
                })
                root.sinkMuted = o.sink === "1"
                root.sourceMuted = o.source === "1"
                root.micUse = o.mic_use === "1"
                root.camUse = o.cam_use === "1"
                root.micApps = o.mic_apps || ""
                root.camApps = o.cam_apps || ""
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
                active: root.micUse
                onIcon: "protocolos-mic"
                offIcon: "protocolos-mic-off"
                tip: root.micUse
                     ? ("Микрофон используется: " + root.micApps)
                     : (muted ? "Включить микрофон" : "Выключить микрофон")
                onClicked: root.toggle("source")
            }
            AudioBtn {
                muted: !root.camUse
                active: root.camUse
                onIcon: "protocolos-cam"
                offIcon: "protocolos-cam-off"
                tip: root.camUse
                     ? ("Камера: " + root.camApps + " · клик — запретить/разрешить")
                     : "Камера запрещена · клик — разрешить"
                onClicked: ex.connectSource("/usr/local/bin/protocolos-camera toggle #" + Date.now())
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
        property bool active: false
        property string onIcon
        property string offIcon
        property string tip
        signal clicked()
        width: 28; height: 28
        Rectangle {
            anchors.fill: parent; radius: 8
            color: b.active ? Qt.rgba(1, 0.35, 0.2, 0.45)
                 : ma.containsMouse ? (b.muted ? Qt.rgba(1, 0.3, 0.35, 0.35) : Qt.rgba(1, 1, 1, 0.22))
                                    : (b.muted ? Qt.rgba(1, 0.25, 0.3, 0.22) : Qt.rgba(1, 1, 1, 0.10))
            border.color: b.active ? Qt.rgba(1, 0.55, 0.25, 0.95)
                         : b.muted ? Qt.rgba(1, 0.45, 0.5, 0.7) : Qt.rgba(1, 1, 1, 0.35)
            border.width: b.active ? 2 : 1
        }
        // пульс при использовании мик/камеры
        Rectangle {
            id: ring
            anchors.fill: parent; anchors.margins: -2; radius: 10
            color: "transparent"; border.width: 2
            border.color: Qt.rgba(1, 0.4, 0.15, 0.85)
            visible: b.active
            opacity: 0.85
            SequentialAnimation on opacity {
                running: b.active; loops: Animation.Infinite
                NumberAnimation { to: 1; duration: 700 }
                NumberAnimation { to: 0.2; duration: 700 }
            }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 18; height: 18
            source: (b.muted && !b.active) ? b.offIcon : b.onIcon
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
