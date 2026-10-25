// ProtocolOS layout locked to HTML mockup (1920×1080 reference).
// Dark theme: desktop = night wallpaper; lock screen swapped via wallsync.
// Multi-monitor: wallpaper on every screen; tiles + panels only on primary.
var WALL = "file:///usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg";
var EMPTY = "file:///usr/share/protocolos/emptydesk";

function setupDesktop(d, withTiles) {
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", WALL);
    d.writeConfig("FillMode", "2");
    d.currentConfigGroup = ["General"];
    d.writeConfig("url", EMPTY);
    d.writeConfig("showToolbox", "false");
    if (!withTiles) return;
    var sg = screenGeometry(d.screen);
    var desk = d.addWidget("org.protocolos.tiles", 0, 0, sg.width, sg.height);
    desk.currentConfigGroup = ["General"];
    desk.writeConfig("mode", "desktop");
}

var desks = desktops();
var primary = null;
var i;
for (i = 0; i < desks.length; i++) {
    if (primary === null || desks[i].screen === 0) primary = desks[i];
}
if (primary === null && desks.length) primary = desks[0];

for (i = 0; i < desks.length; i++) {
    setupDesktop(desks[i], desks[i] === primary);
}

var sg = primary ? screenGeometry(primary.screen) : screenGeometry(0);
var W = sg.width, H = sg.height;
// Mockup bar: height 44, radius 22, inset 16/12 — keep floating Plasma panel close to that.
var S = Math.max(0.6, Math.min(1.0, H / 1080, W / 1920));
var primaryScreen = primary ? primary.screen : 0;

var top = new Panel;
top.location = "top";
top.screen = primaryScreen;
top.height = Math.round(Math.max(36, Math.min(48, 44 * S)));
top.floating = true;
top.offset = 0;
var k = top.addWidget("org.kde.plasma.kickoff");
k.currentConfigGroup = ["General"];
k.writeConfig("icon", "protocolos-mark");
k.writeConfig("menuLabel", "ProtocolOS");
k.globalShortcut = "Alt+F1";
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.protocolos.shield");
top.addWidget("org.protocolos.audio");   // mic + headphones mute
var tray = top.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("iconSpacing", 2);
var c = top.addWidget("org.kde.plasma.digitalclock");
c.currentConfigGroup = ["Appearance"];
c.writeConfig("showDate", "true");
c.writeConfig("dateDisplayFormat", "BesideTime");
c.writeConfig("dateFormat", "custom");
c.writeConfig("customDateFormat", "ddd, d MMM");

// Mockup dock: height 84, radius 30, bottom 18, centered icons with separator + shield
var dock = new Panel;
dock.location = "bottom";
dock.screen = primaryScreen;
dock.height = Math.round(Math.max(64, Math.min(96, 84 * S)));
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";
var tm = dock.addWidget("org.kde.plasma.icontasks");
tm.currentConfigGroup = ["General"];
tm.writeConfig("launchers", ["files","firefox","terminal","store","av","monitor","settings"].map(function (n) {
    return "applications:protocolos-dock-" + n + ".desktop"; }).join(","));
tm.writeConfig("showOnlyCurrentDesktop", "false");
tm.writeConfig("showOnlyCurrentScreen", "false");
tm.writeConfig("showOnlyCurrentActivity", "false");
tm.writeConfig("iconSpacing", "3");
tm.writeConfig("maxStripes", "1");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.protocolos.shield");
