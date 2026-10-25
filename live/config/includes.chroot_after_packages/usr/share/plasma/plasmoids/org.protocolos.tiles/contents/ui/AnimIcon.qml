import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// App icon built from SVG layers (../images/anim) so parts can move.
// Animates only on launch (kick/burst) — not on hover.
Item {
    id: ic
    property string name: ""
    property bool hovered: false // kept for API; does not drive animation
    property bool enabled: true
    readonly property real u: width / 64
    // honours the Plasma animation speed; 0 = animations off
    readonly property real f: Kirigami.Units.longDuration / 200
    readonly property bool on: enabled && f > 0
    readonly property bool play: on && burst.running
    readonly property bool layered: ["firefox","antivirus","terminal","files","settings","store","discord","record","kdenlive","blackout","network"].indexOf(name) >= 0
    function d(ms) { return Math.max(1, Math.round(ms * f)) }
    function kick() { if (on) burst.restart() }
    function dir(n) { return Qt.resolvedUrl("../images/anim/" + n + ".svg") }
    Timer { id: burst; interval: d(1600) }

    component L: Image {
        anchors.fill: parent
        sourceSize: Qt.size(Math.max(64, ic.width * 2), Math.max(64, ic.height * 2))
        smooth: true
    }

    // fallback: plain theme icon
    Kirigami.Icon { anchors.fill: parent; visible: !ic.layered; source: ic.layered ? "" : "protocolos-" + ic.name }

    Loader {
        anchors.fill: parent
        active: ic.layered
        sourceComponent: ({
            firefox: firefoxC, antivirus: avC, terminal: termC, files: filesC, settings: setC, store: storeC,
            discord: discordC, record: recC, kdenlive: kdenC, blackout: blackC, network: netC
        })[ic.name] || null
    }

    // ---------- Firefox: the flame flickers ----------
    Component { id: firefoxC; Item {
        L { source: ic.dir("firefox-bg") }
        L { id: fl; source: ic.dir("firefox-flame")
            transform: [ Scale { id: fs; origin.x: 32 * ic.u; origin.y: 50 * ic.u },
                         Rotation { id: fr; origin.x: 32 * ic.u; origin.y: 50 * ic.u } ] }
        L { id: core; source: ic.dir("firefox-core"); opacity: 0
            transform: Scale { id: cs; origin.x: 32 * ic.u; origin.y: 48 * ic.u } }
        ParallelAnimation {
            running: ic.play; loops: Animation.Infinite
            onRunningChanged: if (!running) { fs.yScale = 1; fs.xScale = 1; fr.angle = 0; core.opacity = 0; cs.yScale = 1 }
            SequentialAnimation {
                NumberAnimation { target: fs; property: "yScale"; to: 1.08; duration: ic.d(140); easing.type: Easing.InOutSine }
                NumberAnimation { target: fs; property: "yScale"; to: 0.97; duration: ic.d(110); easing.type: Easing.InOutSine }
                NumberAnimation { target: fs; property: "yScale"; to: 1.05; duration: ic.d(170); easing.type: Easing.InOutSine }
                NumberAnimation { target: fs; property: "yScale"; to: 1.0; duration: ic.d(130); easing.type: Easing.InOutSine }
            }
            SequentialAnimation {
                NumberAnimation { target: fr; property: "angle"; to: -3; duration: ic.d(190) }
                NumberAnimation { target: fr; property: "angle"; to: 2.5; duration: ic.d(210) }
                NumberAnimation { target: fr; property: "angle"; to: 0; duration: ic.d(150) }
            }
            SequentialAnimation {
                NumberAnimation { target: core; property: "opacity"; to: 0.9; duration: ic.d(160) }
                NumberAnimation { target: core; property: "opacity"; to: 0.4; duration: ic.d(140) }
                NumberAnimation { target: core; property: "opacity"; to: 0.75; duration: ic.d(250) }
            }
            SequentialAnimation {
                NumberAnimation { target: cs; property: "yScale"; to: 1.18; duration: ic.d(230) }
                NumberAnimation { target: cs; property: "yScale"; to: 0.95; duration: ic.d(320) }
            }
        }
    } }

    // ---------- Защита: shield spins, lens fades, check draws in ----------
    Component { id: avC; Item {
        L { source: ic.dir("antivirus-bg") }
        Connections { target: ic; function onPlayChanged() { if (!ic.play) { ar.angle = 0; lens.opacity = 1; chk.progress = 0 } } }
        Item { anchors.fill: parent
            transform: Rotation { id: ar; origin.x: 32 * ic.u; origin.y: 32 * ic.u; axis { x: 0; y: 1; z: 0 } }
            L { source: ic.dir("antivirus-shield") }
            L { id: lens; source: ic.dir("antivirus-lens") }
        }
        Check { id: chk; anchors.fill: parent; u: ic.u; progress: 0 }
        SequentialAnimation {
            running: ic.play
            ParallelAnimation {
                NumberAnimation { target: ar; property: "angle"; from: 0; to: 360; duration: ic.d(700); easing.type: Easing.InOutCubic }
                NumberAnimation { target: lens; property: "opacity"; to: 0; duration: ic.d(350) }
            }
            NumberAnimation { target: chk; property: "progress"; from: 0; to: 1; duration: ic.d(380); easing.type: Easing.OutCubic }
        }
    } }

    // ---------- Терминал: ">" types in, "_" blinks ----------
    Component { id: termC; Item {
        L { source: ic.dir("terminal-bg") }
        L { id: chev; source: ic.dir("terminal-chev") }
        L { id: cur; source: ic.dir("terminal-cur") }
        SequentialAnimation {
            running: ic.play
            onRunningChanged: if (!running) { chev.opacity = 1; chev.x = 0; cur.opacity = 1; cur.x = 0 }
            PropertyAction { target: chev; property: "opacity"; value: 0 }
            PropertyAction { target: cur; property: "x"; value: -14 * ic.u }
            PauseAnimation { duration: ic.d(120) }
            PropertyAction { target: chev; property: "opacity"; value: 1 }
            NumberAnimation { target: cur; property: "x"; to: 0; duration: ic.d(180); easing.type: Easing.OutQuad }
            SequentialAnimation { loops: Animation.Infinite
                NumberAnimation { target: cur; property: "opacity"; to: 0; duration: ic.d(60) }
                PauseAnimation { duration: ic.d(380) }
                NumberAnimation { target: cur; property: "opacity"; to: 1; duration: ic.d(60) }
                PauseAnimation { duration: ic.d(380) }
            }
        }
    } }

    // ---------- Файлы: folder lid opens, a sheet peeks out ----------
    Component { id: filesC; Item {
        L { source: ic.dir("files-bg") }
        Connections { target: ic; function onPlayChanged() { if (!ic.play) { lid.angle = 0; paper.y = 4 * ic.u } } }
        L { source: ic.dir("files-back") }
        L { id: paper; source: ic.dir("files-paper"); y: 4 * ic.u }
        L { source: ic.dir("files-lid")
            transform: [ Rotation { id: lid; origin.x: 32 * ic.u; origin.y: 44 * ic.u; axis { x: 1; y: 0; z: 0 } } ] }
        ParallelAnimation {
            running: ic.play
            NumberAnimation { target: lid; property: "angle"; to: 58; duration: ic.d(380); easing.type: Easing.OutBack }
            NumberAnimation { target: paper; property: "y"; to: -6 * ic.u; duration: ic.d(420); easing.type: Easing.OutCubic }
        }
    } }

    // ---------- Настройки: gear turns ----------
    Component { id: setC; Item {
        L { source: ic.dir("settings-bg") }
        L { id: gear; source: ic.dir("settings-gear") }
        RotationAnimation { target: gear; running: ic.play; loops: Animation.Infinite; from: 0; to: 360; duration: ic.d(2400)
            onRunningChanged: if (!running) gear.rotation = 0 }
    } }

    // ---------- Магазин: bag bounces ----------
    Component { id: storeC; Item {
        L { source: ic.dir("store-bg") }
        L { id: bag; source: ic.dir("store-bag")
            transform: Scale { id: bs; origin.x: 32 * ic.u; origin.y: 43 * ic.u } }
        SequentialAnimation {
            running: ic.play; loops: Animation.Infinite
            onRunningChanged: if (!running) { bag.y = 0; bs.yScale = 1; bs.xScale = 1 }
            ParallelAnimation {
                NumberAnimation { target: bs; property: "yScale"; to: 0.88; duration: ic.d(110) }
                NumberAnimation { target: bs; property: "xScale"; to: 1.08; duration: ic.d(110) } }
            ParallelAnimation {
                NumberAnimation { target: bag; property: "y"; to: -7 * ic.u; duration: ic.d(220); easing.type: Easing.OutQuad }
                NumberAnimation { target: bs; property: "yScale"; to: 1.04; duration: ic.d(160) }
                NumberAnimation { target: bs; property: "xScale"; to: 0.97; duration: ic.d(160) } }
            ParallelAnimation {
                NumberAnimation { target: bag; property: "y"; to: 0; duration: ic.d(220); easing.type: Easing.InQuad }
                NumberAnimation { target: bs; property: "yScale"; to: 1; duration: ic.d(220) }
                NumberAnimation { target: bs; property: "xScale"; to: 1; duration: ic.d(220) } }
            PauseAnimation { duration: ic.d(380) }
        }
    } }

    // ---------- Discord: bubble pops, typing dots ----------
    Component { id: discordC; Item {
        L { source: ic.dir("discord-bg") }
        Connections { target: ic; function onPlayChanged() { if (!ic.play) { ds.xScale = 1; ds.yScale = 1; lines.opacity = 1; dots.opacity = 0 } } }
        L { id: bub; source: ic.dir("discord-bubble")
            transform: Scale { id: ds; origin.x: 22 * ic.u; origin.y: 44 * ic.u } }
        L { id: lines; source: ic.dir("discord-lines") }
        Row {
            id: dots; opacity: 0; spacing: 3 * ic.u
            x: 32 * ic.u - width / 2 + 0; y: 30.5 * ic.u - 2 * ic.u
            Repeater { model: 3; Rectangle { id: dt; width: 4 * ic.u; height: width; radius: width / 2; color: "white"
                SequentialAnimation on y { running: ic.play; loops: Animation.Infinite
                    PauseAnimation { duration: ic.d(index * 120) }
                    NumberAnimation { to: -2.5 * ic.u; duration: ic.d(180); easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: ic.d(180); easing.type: Easing.InQuad }
                    PauseAnimation { duration: ic.d(360 - index * 120) } } } }
        }
        SequentialAnimation {
            running: ic.play
            ParallelAnimation {
                NumberAnimation { target: ds; properties: "xScale,yScale"; from: 0.8; to: 1.08; duration: ic.d(180); easing.type: Easing.OutQuad }
                NumberAnimation { target: lines; property: "opacity"; to: 0; duration: ic.d(120) } }
            NumberAnimation { target: ds; properties: "xScale,yScale"; to: 1; duration: ic.d(160); easing.type: Easing.OutBack }
            NumberAnimation { target: dots; property: "opacity"; to: 1; duration: ic.d(120) }
        }
    } }

    // ---------- Запись экрана: red dot pulses ----------
    Component { id: recC; Item {
        L { source: ic.dir("record-bg") }
        L { source: ic.dir("record-dot") }
        L { id: red; source: ic.dir("record-red"); opacity: 0
            transform: Scale { id: rs; origin.x: 32 * ic.u; origin.y: 29 * ic.u } }
        Rectangle { id: ring; width: 10 * ic.u; height: width; radius: width / 2; color: "transparent"
            border.color: "#ff2d55"; border.width: 1.5 * ic.u; opacity: 0
            x: 32 * ic.u - width / 2; y: 29 * ic.u - height / 2 }
        ParallelAnimation {
            running: ic.play; loops: Animation.Infinite
            onRunningChanged: if (!running) { red.opacity = 0; rs.xScale = 1; rs.yScale = 1; ring.opacity = 0 }
            PropertyAction { target: red; property: "opacity"; value: 1 }
            SequentialAnimation {
                NumberAnimation { target: rs; properties: "xScale,yScale"; to: 1.35; duration: ic.d(380); easing.type: Easing.OutQuad }
                NumberAnimation { target: rs; properties: "xScale,yScale"; to: 1; duration: ic.d(420); easing.type: Easing.InOutQuad } }
            NumberAnimation { target: ring; property: "width"; from: 8 * ic.u; to: 20 * ic.u; duration: ic.d(800) }
            NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: ic.d(800) }
        }
    } }

    // ---------- Kdenlive: film strip scrolls ----------
    Component { id: kdenC; Item {
        L { source: ic.dir("kdenlive-bg") }
        Item { // window between top and bottom edge of the frame
            x: 0; y: 20.75 * ic.u; width: parent.width; height: 22.5 * ic.u; clip: true
            L { id: holes; source: ic.dir("kdenlive-holes"); anchors.fill: undefined
                width: ic.width; height: ic.height; y: -20.75 * ic.u }
        }
        NumberAnimation { target: holes; property: "y"; running: ic.play; loops: Animation.Infinite
            from: -20.75 * ic.u; to: -28.25 * ic.u; duration: ic.d(420)
            onRunningChanged: if (!running) holes.y = -20.75 * ic.u }
    } }

    // ---------- Blackout: the minus pulses red ----------
    Component { id: blackC; Item {
        L { source: ic.dir("blackout-bg") }
        L { source: ic.dir("blackout-minus") }
        L { id: mr; source: ic.dir("blackout-minus-red"); opacity: 0
            transform: Scale { id: ms; origin.x: 32 * ic.u; origin.y: 32 * ic.u } }
        SequentialAnimation {
            running: ic.play; loops: Animation.Infinite
            onRunningChanged: if (!running) { mr.opacity = 0; ms.xScale = 1 }
            ParallelAnimation {
                NumberAnimation { target: mr; property: "opacity"; to: 1; duration: ic.d(300); easing.type: Easing.OutQuad }
                NumberAnimation { target: ms; property: "xScale"; to: 1.2; duration: ic.d(300) } }
            ParallelAnimation {
                NumberAnimation { target: mr; property: "opacity"; to: 0.25; duration: ic.d(450); easing.type: Easing.InQuad }
                NumberAnimation { target: ms; property: "xScale"; to: 1; duration: ic.d(450) } }
        }
    } }

    // ---------- Сетевой монитор: meridians turn ----------
    Component { id: netC; Item {
        L { source: ic.dir("network-bg") }
        Repeater { model: 2
            L { source: ic.dir("network-mer")
                property real ph: 0
                opacity: 0.35 + 0.65 * Math.abs(Math.cos((ph + index * 90) * Math.PI / 180))
                transform: Scale { origin.x: 32 * ic.u; xScale: Math.cos((ph + index * 90) * Math.PI / 180) * (index ? 1 : 1) }
                NumberAnimation on ph { running: ic.play; loops: Animation.Infinite; from: 0; to: 180; duration: ic.d(1400)
                    onRunningChanged: if (!running) ph = index ? 90 : 0 }
                Component.onCompleted: if (index) ph = 90 }
        }
    } }
}
