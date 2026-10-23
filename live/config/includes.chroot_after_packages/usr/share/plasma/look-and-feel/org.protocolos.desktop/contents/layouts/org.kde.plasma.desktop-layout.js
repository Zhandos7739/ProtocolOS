// ProtocolOS layout: glass top bar, floating centered dock, glass app tiles (left),
// folder column (right), protection card (bottom-left). Sizes are relative to the screen.
// desktop = day wallpaper; SDDM + lock screen stay on the night one (ProtocolOS)
var WALL = "file:///usr/share/wallpapers/ProtocolOS-day/contents/images/1920x1080.jpg";
var sg = screenGeometry(0);
var W = sg.width, H = sg.height;

// ---- desktop ----
var d = desktops()[0];
d.wallpaperPlugin = "org.kde.image";
d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
d.writeConfig("Image", WALL);
d.writeConfig("FillMode", "2");
d.currentConfigGroup = ["General"];
// show no raw file icons: point the desktop folder view at an empty directory
d.writeConfig("url", "file:///usr/share/protocolos/emptydesk");
d.writeConfig("showToolbox", "false");

// One full-screen widget draws tiles, folders and the protection card. It lays itself out
// from the desktop window size (see org.protocolos.tiles), so nothing overlaps at any resolution
// and a later resolution change (VirtualBox guest resize, monitor change) is followed live.
var desk = d.addWidget("org.protocolos.tiles", 0, 0, W, H);
desk.currentConfigGroup = ["General"];
desk.writeConfig("mode", "desktop");

var S = Math.max(0.6, Math.min(1.5, H / 1080, W / 1280));

// ---- top bar ----
var top = new Panel;
top.location = "top";
top.height = Math.round(Math.max(30, Math.min(48, 44 * S)));
top.floating = true;
var k = top.addWidget("org.kde.plasma.kickoff");
k.currentConfigGroup = ["General"];
k.writeConfig("icon", "protocolos");
k.writeConfig("menuLabel", "ProtocolOS");
k.globalShortcut = "Alt+F1";   // Meta opens the launcher
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.protocolos.shield");   // pills: CPU temp + protection status
var tray = top.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("iconSpacing", 2);
// no separate keyboardlayout widget: the system tray already shows the layout (was shown twice)
var c = top.addWidget("org.kde.plasma.digitalclock");
c.currentConfigGroup = ["Appearance"];
c.writeConfig("showDate", "true");
c.writeConfig("dateDisplayFormat", "BesideTime");
c.writeConfig("dateFormat", "custom");
c.writeConfig("customDateFormat", "ddd, d MMM");

// ---- floating dock ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(Math.max(52, Math.min(90, 84 * S)));
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";
var tm = dock.addWidget("org.kde.plasma.icontasks");
tm.currentConfigGroup = ["General"];
tm.writeConfig("launchers", ["files","firefox","terminal","store","av","monitor","settings"].map(function (n) {
    return "applications:protocolos-dock-" + n + ".desktop"; }).join(","));
tm.writeConfig("showOnlyCurrentDesktop", "false");
tm.writeConfig("iconSpacing", "3");
tm.writeConfig("maxStripes", "1");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.protocolos.shield");   // green shield icon after the separator
