import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

// ProtocolOS desktop: app tiles (left), folder columns (right), protection card (bottom-left).
// The whole arrangement is computed from the size of the desktop window, not from the widget
// geometry, so it cannot overlap and follows resolution changes (1024x768 ... 4K).
PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // glass blurs the wallpaper the desktop really uses (dark theme default = night)
    property url wall: "file:///usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg"
    // HTML mockup order (Sandbox Mod → Discord). Extra apps hidden by default.
    readonly property var apps: [
        ["firefox", "Firefox", "Браузер", "firefox-esr"],
        ["terminal", "Терминал", "Система", "konsole"],
        ["files", "Файлы", "Менеджер", "dolphin"],
        ["calc", "Калькулятор", "Счёт", "kcalc"],
        ["steam", "Steam", "Proton · GameMode", "/usr/local/bin/protocolos-steam"],
        ["settings", "Настройки", "Система", "systemsettings"],
        ["discord", "Discord", "Мессенджер", "flatpak run com.discordapp.Discord || plasma-discover --search discord"],
        ["store", "Магазин", "Приложения", "plasma-discover"],
        ["antivirus", "Защита", "ClamAV · Антивирус", "clamtk"],
        ["record", "Запись экрана", "Kooha", "kooha"],
        ["kdenlive", "Kdenlive", "Видеоредактор", "kdenlive"],
        ["blackout", "Blackout", "Отключить сеть", "konsole --hold -e /usr/local/bin/protocolos-blackout toggle"],
        ["network", "Сетевой монитор", "OpenSnitch", "opensnitch-ui"]
    ]
    // путь папки для файловых операций (Ctrl+C/X/V, новая папка/файл)
    property string fileTarget: "desktop"
    // first entry is the "Проекты" shortcut, shown in its own column like in the mockup
    readonly property var dirs: [
        ["projects", "Проекты", "d=$(xdg-user-dir DOCUMENTS)/Проекты; mkdir -p \"$d\"; xdg-open \"$d\"", "$(xdg-user-dir DOCUMENTS)/Проекты"],
        ["docs", "Документы", "xdg-open \"$(xdg-user-dir DOCUMENTS)\"", "$(xdg-user-dir DOCUMENTS)"],
        ["down", "Загрузки", "xdg-open \"$(xdg-user-dir DOWNLOAD)\"", "$(xdg-user-dir DOWNLOAD)"],
        ["pics", "Изображения", "xdg-open \"$(xdg-user-dir PICTURES)\"", "$(xdg-user-dir PICTURES)"],
        ["system", "Система", "dolphin /", "/"],
        ["trash", "Корзина", "dolphin trash:/", ""]
    ]

    // ---------- customization (edit mode) ----------
    readonly property var cfg: Plasmoid.configuration
    property bool editing: false
    property bool showLayoutSettings: false
    //PLASMA-ONLY-BEGIN
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.editing ? "Завершить настройку" : "Настроить рабочий стол"
            icon.name: "protocolos-edit"
            onTriggered: root.editing = !root.editing
        },
        PlasmaCore.Action {
            text: "Расположение…"
            icon.name: "preferences-desktop-display"
            onTriggered: root.showLayoutSettings = true
        }
    ]
    //PLASMA-ONLY-END
    // Settings launcher drops a flag file — pick it up without a busy poll.
    readonly property string layoutFlagCmd: "f=\"$HOME/.config/protocolos/open-layout-settings\"; if [ -f \"$f\" ]; then rm -f \"$f\"; echo open; fi #layout"
    P5Support.DataSource {
        id: layoutFlag; engine: "executable"
        connectedSources: [root.layoutFlagCmd]
        interval: 2500
        onNewData: (src, data) => {
            if ((data["stdout"] || "").indexOf("open") >= 0) {
                root.showLayoutSettings = true
                root.editing = true
            }
        }
    }
    function ordered(list, order) {
        var out = [], seen = {}
        for (var i = 0; i < (order ? order.length : 0); i++)
            for (var j = 0; j < list.length; j++)
                if (list[j][0] === order[i] && !seen[order[i]]) { out.push(list[j]); seen[order[i]] = true }
        for (var k = 0; k < list.length; k++) if (!seen[list[k][0]]) out.push(list[k])
        return out
    }
    readonly property var hiddenSet: cfg.hiddenItems || []
    readonly property var appAll: ordered(apps, cfg.appOrder)
    readonly property var dirAll: ordered(dirs, cfg.dirOrder)
    readonly property var appList: appAll.filter(a => hiddenSet.indexOf("app:" + a[0]) < 0)
    readonly property var dirList: dirAll.filter(d => hiddenSet.indexOf("dir:" + d[0]) < 0)
    readonly property var hiddenList: {
        var out = []
        appAll.forEach(a => { if (hiddenSet.indexOf("app:" + a[0]) >= 0) out.push(["app:" + a[0], a[1], "protocolos-" + a[0]]) })
        dirAll.forEach(d => { if (hiddenSet.indexOf("dir:" + d[0]) >= 0) out.push(["dir:" + d[0], d[1], "protocolos-fold-" + d[0]]) })
        if (!cfg.showCard) out.push(["card", "Карточка защиты", "protocolos-shield"])
        return out
    }
    function setHidden(key, on) {
        if (key === "card") { cfg.showCard = !on; return }
        var h = hiddenSet.slice(), i = h.indexOf(key)
        if (on && i < 0) h.push(key)
        if (!on && i >= 0) h.splice(i, 1)
        cfg.hiddenItems = h
    }
    // move visible item `id` of kind "app"/"dir" to visible position `to`
    function moveTo(kind, id, to) {
        var all = (kind === "app" ? appAll : dirAll).map(x => x[0])
        var vis = (kind === "app" ? appList : dirList).map(x => x[0])
        to = Math.max(0, Math.min(vis.length - 1, to))
        if (vis[to] === id) return
        var target = vis[to], from = vis.indexOf(id)
        all.splice(all.indexOf(id), 1)
        var ti = all.indexOf(target)
        all.splice(from < to ? ti + 1 : ti, 0, id)
        if (kind === "app") cfg.appOrder = all; else cfg.dirOrder = all
    }

    // follow primary-screen wallpaper (resolves 1920/3840 packages via protocolos-wall-resolve)
    readonly property string wallCmd: "/usr/local/bin/protocolos-wall-resolve --desktop #wall"
    P5Support.DataSource {
        id: wallSrc; engine: "executable"
        connectedSources: [root.wallCmd]
        interval: 60000
        onNewData: (src, data) => {
            var f = (data["stdout"] || "").trim().split("\n")[0]
            if (f === "" || (f[0] !== "/" && f.indexOf("file://") !== 0)) return
            if (f.indexOf("://") < 0) f = "file://" + f
            if (root.wall != f) root.wall = f
        }
    }
    P5Support.DataSource {
        id: ex; engine: "executable"
        onNewData: (src, data) => disconnectSource(src)
    }
    function resetLayout() {
        cfg.appOrder = ["firefox","terminal","files","calc","steam","settings","discord","store","antivirus","record","kdenlive","blackout","network"]
        cfg.dirOrder = ["projects","docs","down","pics","system","trash"]
        cfg.hiddenItems = ["app:record","app:kdenlive","app:blackout","app:network"]
        cfg.showCard = true
        cfg.columns = 4
        cfg.folderSide = "right"
        cfg.marginLeft = 80
        cfg.marginTop = 110
        cfg.appleOpen = true
    }
    function pinToDock(id) { launch("/usr/local/bin/protocolos-pin " + id) }
    function openTerminalIn(path) { launch("d=\"" + path + "\"; mkdir -p \"$d\"; konsole --workdir \"$d\"") }
    function filesOp(op, path) {
        var t = path && path !== "" ? path : root.fileTarget
        launch("/usr/local/bin/protocolos-files " + op + " \"" + String(t).replace(/"/g, "") + "\"")
    }
    function dirKey(id) {
        if (id === "projects") return "projects"
        if (id === "docs") return "docs"
        if (id === "down") return "down"
        if (id === "pics") return "pics"
        return "desktop"
    }
    // typing on the desktop hands the text to KRunner
    function krunner(text) {
        launch("dbus-send --session --type=method_call --dest=org.kde.krunner /App org.kde.krunner.App.query string:\"" + text.replace(/["\\$`]/g, "") + "\"")
    }
    // keyboard focus: 0..apps-1 = tiles, apps.. = folders, -1 = none
    property int kbd: -1
    function activate(i) {
        if (i < 0) return
        if (i < appList.length) launch(appList[i][3]); else launch(dirList[i - appList.length][2])
    }
    function launch(cmd) {
        ex.connectSource("setsid -f sh -c '" + cmd.replace(/'/g, "'\\''") + "' >/dev/null 2>&1")
    }

    fullRepresentation: Item {
        id: area
        focus: true
        Keys.onPressed: (e) => {
            var na = root.appList.length, nd = root.dirList.length, c = area.grid.c, k = root.kbd
            // Ctrl+C/V/X и создание папок/файлов — когда фокус на столе ProtocolOS
            if (e.modifiers & Qt.ControlModifier) {
                if (e.key === Qt.Key_V) { root.filesOp("paste", root.fileTarget); e.accepted = true; return }
                if (e.key === Qt.Key_C) { root.filesOp("copy-target", root.fileTarget); e.accepted = true; return }
                if (e.key === Qt.Key_X) { root.filesOp("cut-target", root.fileTarget); e.accepted = true; return }
                if ((e.modifiers & Qt.ShiftModifier) && e.key === Qt.Key_N) { root.filesOp("new-folder", root.fileTarget); e.accepted = true; return }
                if ((e.modifiers & Qt.AltModifier) && e.key === Qt.Key_N) { root.filesOp("new-file", root.fileTarget); e.accepted = true; return }
            }
            if (e.key === Qt.Key_Escape) { if (root.editing) root.editing = false; root.kbd = -1; e.accepted = true; return }
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { if (!root.editing) root.activate(k); e.accepted = true; return }
            var mv = { [Qt.Key_Left]: 1, [Qt.Key_Right]: 1, [Qt.Key_Up]: 1, [Qt.Key_Down]: 1 }
            if (mv[e.key]) {
                e.accepted = true
                if (k < 0) { root.kbd = 0; return }
                if (k < na) {
                    if (e.key === Qt.Key_Left) k = (k % c) ? k - 1 : k
                    else if (e.key === Qt.Key_Right) k = ((k % c) < c - 1 && k + 1 < na) ? k + 1 : (nd ? na + Math.min(nd - 1, Math.floor(k / c)) : k)
                    else if (e.key === Qt.Key_Up) k = k - c >= 0 ? k - c : k
                    else k = k + c < na ? k + c : k
                } else {
                    var j = k - na
                    if (e.key === Qt.Key_Up) j = Math.max(0, j - 1)
                    else if (e.key === Qt.Key_Down) j = Math.min(nd - 1, j + 1)
                    else if (e.key === Qt.Key_Left && na) { k = Math.min(na - 1, j * c + c - 1); root.kbd = k; return }
                    k = na + j
                    if (k >= na && k - na < nd) root.fileTarget = root.dirKey(root.dirList[k - na][0])
                }
                root.kbd = k; return
            }
            if (!root.editing && e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                root.krunner(e.text); e.accepted = true
            }
        }
        Layout.minimumWidth: 200
        Layout.minimumHeight: 200
        Layout.preferredWidth: Screen.width
        Layout.preferredHeight: Screen.height

        // where this widget sits inside the desktop window
        property point gp: Qt.point(0, 0)
        function sync() {
            var p = area.mapToItem(null, 0, 0)
            if (p.x !== gp.x || p.y !== gp.y) gp = Qt.point(p.x, p.y)
        }
        Component.onCompleted: Qt.callLater(sync)
        Timer { interval: 5000; running: true; repeat: true; onTriggered: area.sync() }

        // ---------- geometry (HTML mockup base @1920×1080, adjustable in settings) ----------
        readonly property real sw: area.Window.width > 0 ? area.Window.width : Screen.width
        readonly property real sh: area.Window.height > 0 ? area.Window.height : Screen.height
        readonly property int cols: Math.max(3, Math.min(6, root.cfg.columns || 4))
        readonly property int rows: Math.max(1, Math.ceil(root.appList.length / cols))
        readonly property real refNeed: (root.cfg.marginTop || 110) + rows * 200 + 40 + 270 + 120
        readonly property real s: Math.max(0.45, Math.min(1.0, sw / 1920, sh / 1080, sh / refNeed))
        readonly property bool foldersLeft: root.cfg.folderSide === "left"
        readonly property real leftX: Math.round((root.cfg.marginLeft || 80) * s) + (foldersLeft ? Math.round(280 * s) : 0)
        readonly property real topY: Math.round((root.cfg.marginTop || 110) * s)
        readonly property real cell: Math.round(150 * s)
        readonly property real gap: Math.round(30 * s)
        readonly property real rowGap: Math.round(30 * s)
        readonly property var grid: ({ c: cols, cell: cell })
        readonly property real tilesEnd: topY + rows * (Math.round(170 * s) + rowGap) - rowGap
        readonly property real labelY: tilesEnd + Math.round(20 * s)
        readonly property real labelH: Math.round(28 * s)
        readonly property real cardW: Math.round(820 * s)
        readonly property real cardH: Math.round(270 * s)
        readonly property real cardY: labelY + labelH + Math.round(12 * s)
        readonly property real foldW: Math.round(130 * s)
        readonly property real foldX: foldersLeft ? Math.round(80 * s) : Math.round(1740 * s)
        readonly property real foldProjX: foldersLeft ? Math.round(230 * s) : Math.round(1590 * s)
        readonly property real foldTop: Math.round(100 * s)
        readonly property real foldStep: Math.round(150 * s)

        Item {
            id: stage
            x: -area.gp.x; y: -area.gp.y
            width: area.sw; height: area.sh

            // ПКМ по пустому месту — создать папку/файл (как на рабочем столе Windows)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                z: 0
                onClicked: (m) => { if (m.button === Qt.RightButton) deskMenu.popup() }
            }
            QQC2.Menu {
                id: deskMenu
                QQC2.MenuItem { text: "Новая папка"; onTriggered: root.filesOp("new-folder", "desktop") }
                QQC2.MenuItem { text: "Новый файл"; onTriggered: root.filesOp("new-file", "desktop") }
                QQC2.MenuItem { text: "Вставить"; onTriggered: root.filesOp("paste", "desktop") }
                QQC2.MenuItem { text: "Открыть рабочий стол"; onTriggered: root.launch("/usr/local/bin/protocolos-files open-desktop") }
                QQC2.MenuItem { text: "Поиск приложений…"; onTriggered: root.launch("dbus-send --session --type=method_call --dest=org.kde.krunner /App org.kde.krunner.App.display") }
                QQC2.MenuItem { text: root.editing ? "Завершить настройку" : "Настроить рабочий стол"; onTriggered: root.editing = !root.editing }
            }

            // One shared wallpaper blur for every Glass tile/card/bar on this desktop.
            WallBlur {
                id: sharedWall
                wallpaper: root.wall
                texWidth: Math.min(960, Math.max(640, Math.round(area.sw / 2)))
                texHeight: Math.min(540, Math.max(360, Math.round(area.sh / 2)))
            }

            // ---------- app tiles ----------
            Repeater {
                model: root.appList
                delegate: Item {
                    id: tile
                    readonly property int col: index % area.grid.c
                    readonly property int row: Math.floor(index / area.grid.c)
                    property real dx: 0
                    property real dy: 0
                    property real launchScale: 1
                    property real launchOpacity: 1
                    readonly property bool dragging: ma.drag.active || dx !== 0 || dy !== 0
                    z: dragging || launchScale > 1.01 ? 20 : 0
                    x: area.leftX + col * (area.cell + area.gap) + dx
                    y: area.topY + row * (Math.round(170 * area.s) + area.rowGap) + dy
                    Behavior on x { enabled: !tile.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: !tile.dragging; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Wiggle { target: tile; running: root.editing && !tile.dragging; phase: index }
                    width: area.cell; height: Math.round(170 * area.s)
                    scale: (ma.pressed && launchScale === 1 ? 0.95 : 1) * launchScale
                    opacity: launchOpacity
                    Behavior on scale { enabled: launchScale === 1; NumberAnimation { duration: 100 } }
                    readonly property real k: area.cell / 150
                    // Apple-like open: zoom + fade the tile, then start the app (KWin scale finishes the window).
                    SequentialAnimation {
                        id: appleOpen
                        property string cmd: ""
                        ParallelAnimation {
                            NumberAnimation { target: tile; property: "launchScale"; from: 1; to: 1.45; duration: 260; easing.type: Easing.OutCubic }
                            NumberAnimation { target: tile; property: "launchOpacity"; from: 1; to: 0.05; duration: 260; easing.type: Easing.InQuad }
                        }
                        ScriptAction { script: { root.launch(appleOpen.cmd); tile.launchScale = 1; tile.launchOpacity = 1 } }
                    }
                    function openApp() {
                        aicon.kick()
                        if (root.cfg.appleOpen && root.cfg.animIcons && Kirigami.Units.longDuration > 0) {
                            appleOpen.cmd = modelData[3]; appleOpen.restart()
                        } else {
                            root.launch(modelData[3])
                        }
                    }

                    Glass {
                        anchors.fill: parent; radius: 28 * tile.k
                        hovered: ma.containsMouse || tile.kfocus
                        wallpaper: root.wall; wallLayer: sharedWall
                        wallW: area.sw; wallH: area.sh
                    }
                    readonly property bool kfocus: root.kbd === index && area.activeFocus
                    // keyboard focus ring
                    Rectangle { anchors.fill: parent; anchors.margins: -4 * tile.k; radius: 32 * tile.k; color: "transparent"
                        border.width: Math.max(2, 3 * tile.k); border.color: Qt.rgba(1, 1, 1, 0.9); visible: tile.kfocus }
                    QQC2.ToolTip.visible: ma.containsMouse && !root.editing && !tile.dragging
                    QQC2.ToolTip.delay: 800
                    QQC2.ToolTip.text: modelData[1] + " — " + modelData[2]
                    // sandbox badge (top-right)
                    Rectangle {
                        anchors { top: parent.top; right: parent.right; margins: 10 * tile.k }
                        width: 26 * tile.k; height: 18 * tile.k; radius: 8 * tile.k
                        color: Qt.rgba(0, 0, 0, 0.25)
                        Kirigami.Icon { anchors.centerIn: parent; width: 12 * tile.k; height: width; source: "protocolos-badge" }
                    }
                    // Cheap icon shadow (no MultiEffect blur)
                    Rectangle {
                        width: 84 * tile.k; height: width; radius: 24 * tile.k
                        x: (tile.width - width) / 2; y: tileCol.y + 14 * tile.k
                        color: Qt.rgba(0, 0, 0, 0.22); z: -1
                    }
                    Column {
                        id: tileCol
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 0
                        AnimIcon {
                            id: aicon
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: modelData[0]
                            hovered: (ma.containsMouse || tile.kfocus) && !root.editing
                            enabled: root.cfg.animIcons
                            width: Math.round(84 * tile.k); height: width
                        }
                        Item { width: 1; height: 10 * tile.k }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 10 * tile.k; height: Math.ceil(22 * tile.k)
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            fontSizeMode: Text.HorizontalFit; minimumPixelSize: 8
                            text: modelData[1]; color: "white"
                            font.family: "Inter"; font.pixelSize: Math.max(10, 17 * tile.k); font.weight: Font.DemiBold
                            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.3)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 10 * tile.k; height: Math.ceil(17 * tile.k)
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            fontSizeMode: Text.HorizontalFit; minimumPixelSize: 7
                            text: modelData[2]; color: Qt.rgba(1, 1, 1, 0.85)
                            font.family: "Inter"; font.pixelSize: Math.max(8, 13 * tile.k); font.weight: Font.Medium
                            style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.3)
                        }
                    }
                    EditDecor { k: tile.k; radius: 28 * tile.k; editing: root.editing; onHide: root.setHidden("app:" + modelData[0], true) }
                    MouseArea {
                        id: ma; anchors.fill: parent; hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: root.editing ? Qt.OpenHandCursor : Qt.PointingHandCursor
                        pressAndHoldInterval: 600
                        property point p0
                        onPressed: (m) => { p0 = mapToItem(stage, m.x, m.y); area.forceActiveFocus(); root.kbd = index }
                        onPressAndHold: (m) => { if (m.button === Qt.LeftButton) root.editing = true }
                        onPositionChanged: (m) => {
                            if (!root.editing || !pressed) return
                            var p = mapToItem(stage, m.x, m.y)
                            tile.dx = p.x - p0.x; tile.dy = p.y - p0.y
                        }
                        onReleased: (m) => {
                            if (tile.dx !== 0 || tile.dy !== 0) {
                                var cx = tile.x + tile.width / 2 - area.leftX, cy = tile.y + tile.height / 2 - area.topY
                                var c = Math.max(0, Math.min(area.grid.c - 1, Math.floor(cx / (area.cell + area.gap))))
                                var r = Math.max(0, Math.floor(cy / (Math.round(170 * area.s) + area.rowGap)))
                                var id = modelData[0]
                                tile.dx = 0; tile.dy = 0
                                root.moveTo("app", id, r * area.grid.c + c)
                            }
                        }
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) { tileMenu.popup(); return }
                            if (!root.editing) tile.openApp()
                        }
                    }
                    QQC2.Menu {
                        id: tileMenu
                        QQC2.MenuItem { text: "Открыть"; onTriggered: tile.openApp() }
                        QQC2.MenuItem { text: "Открыть в песочнице"; onTriggered: root.launch("/usr/local/bin/protocolos-sandbox --ask " + modelData[3]) }
                        QQC2.MenuItem { text: "Закрепить в доке"; onTriggered: root.pinToDock(modelData[0]) }
                        QQC2.MenuItem { text: "Скрыть с рабочего стола"; onTriggered: root.setHidden("app:" + modelData[0], true) }
                        QQC2.MenuItem { text: "Расположение…"; onTriggered: root.showLayoutSettings = true }
                        QQC2.MenuItem { text: root.editing ? "Завершить настройку" : "Настроить рабочий стол"; onTriggered: root.editing = !root.editing }
                    }
                }
            }

            Text {
                x: area.leftX + 4 * area.s
                y: Math.min(area.labelY, area.cardY - area.labelH - Math.round(8 * area.s))
                height: area.labelH; verticalAlignment: Text.AlignVCenter
                text: "УСТАНОВЛЕННЫЕ ПРИЛОЖЕНИЯ"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: "Inter"; font.pixelSize: Math.max(10, 14 * area.s); font.weight: Font.Bold; font.letterSpacing: 2 * area.s
            }

            // ---------- protection card ----------
            ShieldCard {
                id: card
                visible: root.cfg.showCard
                x: area.leftX; y: area.cardY
                width: area.cardW; height: area.cardH
                wallpaper: root.wall
                wallLayer: sharedWall
                wallW: area.sw; wallH: area.sh
                animate: root.cfg.animIcons
                EditDecor { k: area.s; radius: 28 * area.s; editing: root.editing; onHide: root.setHidden("card", true) }
            }

            // ---------- folders (Проекты offset left + caption, like HTML) ----------
            Repeater {
                model: root.dirList
                delegate: Item {
                    id: fold
                    property real dy: 0
                    property real dx: 0
                    readonly property bool isProj: modelData[0] === "projects"
                    readonly property int colIndex: isProj ? 0 : Math.max(0, index - (root.dirList[0] && root.dirList[0][0] === "projects" ? 1 : 0))
                    readonly property bool dragging: dx !== 0 || dy !== 0
                    z: dragging ? 10 : 0
                    x: (isProj ? area.foldProjX : area.foldX) + dx
                    y: area.foldTop + (isProj ? 0 : colIndex * area.foldStep) + dy
                    Behavior on y { enabled: !fold.dragging; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    readonly property bool kfocus: root.kbd === root.appList.length + index && area.activeFocus
                    Rectangle { anchors.fill: parent; anchors.margins: -6 * area.s; radius: 18 * area.s; color: fm.containsMouse || fold.kfocus ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        border.width: fold.kfocus ? Math.max(2, 3 * area.s) : 0; border.color: Qt.rgba(1, 1, 1, 0.9) }
                    QQC2.ToolTip.visible: fm.containsMouse && !root.editing && !fold.dragging && fl.truncated
                    QQC2.ToolTip.delay: 800
                    QQC2.ToolTip.text: modelData[1]
                    Wiggle { target: fold; running: root.editing && !fold.dragging; phase: index + 3 }
                    width: area.foldW
                    height: fi.height + fl.height + (isProj ? Math.round(22 * area.s) : 0) + 8 * area.s
                    scale: fm.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Kirigami.Icon {
                        id: fi
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "protocolos-fold-" + modelData[0]
                        // svg 104×96; mockup body 96×78 in a 130px column
                        width: Math.round(Math.min(104 * area.s, (area.foldStep - 30 * area.s) * 104 / 96))
                        height: Math.round(width * 96 / 104)
                        opacity: fm.containsMouse ? 1 : 0.95
                        readonly property bool lift: (fm.containsMouse || fold.kfocus) && !root.editing && root.cfg.animIcons && Kirigami.Units.longDuration > 0
                        transform: Translate { y: fi.lift ? -5 * area.s : 0
                            Behavior on y { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutBack } } }
                        scale: lift ? 1.04 : 1
                        Behavior on scale { NumberAnimation { duration: Kirigami.Units.longDuration } }
                    }
                    Text {
                        id: fl
                        elide: Text.ElideRight
                        anchors.top: fi.bottom; anchors.topMargin: 6 * area.s
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width; horizontalAlignment: Text.AlignHCenter
                        fontSizeMode: Text.HorizontalFit; minimumPixelSize: 8
                        text: modelData[1]; color: "white"
                        font.family: "Inter"; font.pixelSize: Math.max(10, 16 * area.s); font.weight: Font.DemiBold
                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.45)
                    }
                    Text {
                        visible: fold.isProj
                        anchors.top: fl.bottom; anchors.topMargin: 2 * area.s
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width + 20 * area.s; horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "ярлык → ~/Документы/Проекты"
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.family: "Inter"; font.pixelSize: Math.max(8, 12 * area.s); font.weight: Font.Medium
                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.4)
                    }
                    EditDecor { k: area.s; radius: 16 * area.s; editing: root.editing; onHide: root.setHidden("dir:" + modelData[0], true) }
                    MouseArea {
                        id: fm; anchors.fill: parent; hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: root.editing ? Qt.OpenHandCursor : Qt.PointingHandCursor
                        pressAndHoldInterval: 600
                        property point p0
                        onPressed: (m) => {
                            p0 = mapToItem(stage, m.x, m.y); area.forceActiveFocus()
                            root.kbd = root.appList.length + index
                            if (modelData[0] !== "trash" && modelData[0] !== "system")
                                root.fileTarget = root.dirKey(modelData[0])
                        }
                        onPressAndHold: (m) => { if (m.button === Qt.LeftButton) root.editing = true }
                        onPositionChanged: (m) => {
                            if (!root.editing || !pressed) return
                            var p = mapToItem(stage, m.x, m.y)
                            fold.dx = p.x - p0.x; fold.dy = p.y - p0.y
                        }
                        onReleased: {
                            if (fold.dx !== 0 || fold.dy !== 0) {
                                var to = Math.round((fold.y - (area.topY - 10 * area.s)) / area.foldStep)
                                var id = modelData[0]
                                fold.dx = 0; fold.dy = 0
                                root.moveTo("dir", id, to)
                            }
                        }
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) { foldMenu.popup(); return }
                            if (!root.editing) root.launch(modelData[2])
                        }
                    }
                    QQC2.Menu {
                        id: foldMenu
                        QQC2.MenuItem { text: "Открыть"; onTriggered: root.launch(modelData[2]) }
                        QQC2.MenuItem { text: "Новая папка здесь"; visible: modelData[0] !== "trash" && modelData[0] !== "system"; height: visible ? implicitHeight : 0
                            onTriggered: { root.fileTarget = root.dirKey(modelData[0]); root.filesOp("new-folder", root.fileTarget) } }
                        QQC2.MenuItem { text: "Новый файл здесь"; visible: modelData[0] !== "trash" && modelData[0] !== "system"; height: visible ? implicitHeight : 0
                            onTriggered: { root.fileTarget = root.dirKey(modelData[0]); root.filesOp("new-file", root.fileTarget) } }
                        QQC2.MenuItem { text: "Вставить сюда"; visible: modelData[0] !== "trash" && modelData[0] !== "system"; height: visible ? implicitHeight : 0
                            onTriggered: { root.fileTarget = root.dirKey(modelData[0]); root.filesOp("paste", root.fileTarget) } }
                        QQC2.MenuItem { text: "Копировать папку"; visible: modelData[0] !== "trash" && modelData[0] !== "system"; height: visible ? implicitHeight : 0
                            onTriggered: root.filesOp("copy-target", root.dirKey(modelData[0])) }
                        QQC2.MenuItem { text: "Открыть в терминале"; visible: modelData[3] !== ""; height: visible ? implicitHeight : 0
                            onTriggered: root.openTerminalIn(modelData[3]) }
                        QQC2.MenuItem { text: "Скрыть с рабочего стола"; onTriggered: root.setHidden("dir:" + modelData[0], true) }
                        QQC2.MenuItem { text: root.editing ? "Завершить настройку" : "Настроить рабочий стол"; onTriggered: root.editing = !root.editing }
                    }
                }
            }

            // ---------- edit mode bar: hidden items + "Готово" ----------
            EditBar {
                visible: root.editing && !root.showLayoutSettings
                s: area.s; wallpaper: root.wall
                wallLayer: sharedWall
                wallW: area.sw; wallH: area.sh
                hiddenList: root.hiddenList
                // right of the tile grid, left of the folder column, so it never covers anything
                x: Math.max(area.leftX + area.grid.c * (area.cell + area.gap),
                            Math.min((area.sw - width) / 2,
                                     (area.foldersLeft ? area.sw - width - 40 * area.s
                                                       : area.foldX - 20 * area.s - width)))
                y: area.topY
                onRestore: (key) => root.setHidden(key, false)
                onDone: root.editing = false
                animIcons: root.cfg.animIcons
                onReset: root.resetLayout()
                onToggleAnim: root.cfg.animIcons = !root.cfg.animIcons
                onOpenLayout: root.showLayoutSettings = true
            }

            LayoutSettings {
                visible: root.showLayoutSettings
                s: area.s; cfg: root.cfg
                wallpaper: root.wall; wallLayer: sharedWall
                wallW: area.sw; wallH: area.sh
                x: Math.max(24 * area.s, (area.sw - width) / 2)
                y: Math.max(24 * area.s, area.topY)
                onClose: { root.showLayoutSettings = false }
            }

        }
    }
}
