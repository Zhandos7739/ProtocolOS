// ProtocolOS layout: glass top bar, floating centered dock, glass app tiles (left),
// folder column (right), protection card (bottom-left). Sizes are relative to the screen.
var WALL = "file:///usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg";
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

// geometry
var M = Math.round(Math.max(16, W * 0.03));            // side margin
var TOP = 72;                                          // below the top bar
var BOTTOM = Math.round(Math.max(96, H * 0.11));       // space for the dock
var foldW = Math.round(Math.min(150, Math.max(104, W * 0.075)));
var cardH = Math.round(Math.min(270, Math.max(180, H * 0.27)));
var cardW = Math.round(Math.min(840, W - 2 * M - foldW - 24));
var cardY = H - BOTTOM - cardH;
var tilesW = Math.round(Math.min(800, W - 2 * M - foldW - 24));
var tilesH = cardY - TOP - 18;

// glass app tiles (top-left)
var tiles = d.addWidget("org.protocolos.tiles", M, TOP, tilesW, tilesH);
tiles.currentConfigGroup = ["General"];
tiles.writeConfig("mode", "apps");

// folder column (right)
var folders = d.addWidget("org.protocolos.tiles", W - M - foldW, TOP, foldW, H - TOP - BOTTOM);
folders.currentConfigGroup = ["General"];
folders.writeConfig("mode", "folders");

// protection card (bottom-left)
d.addWidget("org.protocolos.shield", M, cardY, cardW, cardH);

// ---- top bar ----
var top = new Panel;
top.location = "top";
top.height = 40;
top.floating = true;
var k = top.addWidget("org.kde.plasma.kickoff");
k.currentConfigGroup = ["General"];
k.writeConfig("icon", "protocolos");
k.writeConfig("menuLabel", "ProtocolOS");
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.protocolos.shield");   // pills: CPU temp + protection status
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.keyboardlayout");
var c = top.addWidget("org.kde.plasma.digitalclock");
c.currentConfigGroup = ["Appearance"];
c.writeConfig("showDate", "true");
c.writeConfig("dateDisplayFormat", "BesideTime");
c.writeConfig("dateFormat", "custom");
c.writeConfig("customDateFormat", "ddd, d MMM");

// ---- floating dock ----
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(Math.max(56, Math.min(72, H * 0.065)));
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";
var dash = dock.addWidget("org.kde.plasma.kickerdash");
dash.currentConfigGroup = ["General"];
dash.writeConfig("icon", "protocolos-grid");
dash.globalShortcut = "Alt+F1";    // Meta -> activateLauncherMenu -> this dashboard
var tm = dock.addWidget("org.kde.plasma.icontasks");
tm.currentConfigGroup = ["General"];
tm.writeConfig("launchers", ["files","firefox","terminal","store","av","monitor","settings"].map(function (n) {
    return "applications:protocolos-dock-" + n + ".desktop"; }).join(","));
tm.writeConfig("showOnlyCurrentDesktop", "false");
tm.writeConfig("iconSpacing", "2");
tm.writeConfig("maxStripes", "1");
dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.protocolos.shield");   // green shield icon after the separator
