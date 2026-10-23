// ProtocolOS layout: top glass bar, floating centered dock, desktop tiles, right folder column, protection widget
var WALL = "file:///usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg";
var sg = screenGeometry(0);

// ---- desktop ----
var d = desktops()[0];
d.wallpaperPlugin = "org.kde.image";
d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
d.writeConfig("Image", WALL);
d.writeConfig("FillMode", "2");
d.currentConfigGroup = ["General"];
d.writeConfig("url", "desktop:/");
d.writeConfig("iconSize", "5");          // large tiles
d.writeConfig("arrangement", "1");       // columns? 0 rows,1 columns
d.writeConfig("flow", "0");
d.writeConfig("alignment", "0");
d.writeConfig("labelWidth", "1");
d.writeConfig("previews", "false");
d.writeConfig("sortMode", "0");

// right column of system folders
var pl = d.addWidget("org.kde.plasma.folder", sg.width - 170, 60, 150, 700);
pl.currentConfigGroup = ["General"];
pl.writeConfig("url", "file://" + userDataPath("protocolos/places"));
pl.writeConfig("labelMode", "0");
pl.writeConfig("iconSize", "4");
pl.writeConfig("arrangement", "1");
pl.writeConfig("sortMode", "0");
pl.writeConfig("toolTips", "false");
pl.currentConfigGroup = [];
pl.writeConfig("UserBackgroundHints", "NoBackground");

// protection status widget
var sh = d.addWidget("org.protocolos.shield", 40, Math.round(sg.height * 0.52), 640, 260);

// ---- top bar ----
var top = new Panel;
top.location = "top";
top.height = 30;
top.floating = true;
var k = top.addWidget("org.kde.plasma.kickoff");
k.currentConfigGroup = ["General"];
k.writeConfig("icon", "protocolos");
k.writeConfig("menuLabel", "ProtocolOS");
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
var ss = top.addWidget("org.protocolos.shield");
var t = top.addWidget("org.kde.plasma.systemmonitor");
t.currentConfigGroup = ["Appearance"];
t.writeConfig("chartFace", "org.kde.ksysguard.textonly");
t.writeConfig("title", "CPU");
t.currentConfigGroup = ["Sensors"];
t.writeConfig("highPrioritySensorIds", "[\"cpu/all/averageTemperature\"]");
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
dock.height = 56;
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.hiding = "none";
var dash = dock.addWidget("org.kde.plasma.kickerdash");
dash.currentConfigGroup = ["General"];
dash.writeConfig("icon", "view-app-grid-symbolic");
dash.globalShortcut = "Alt+F1";    // Meta (Win) -> activateLauncherMenu -> this dashboard
var tm = dock.addWidget("org.kde.plasma.icontasks");
tm.currentConfigGroup = ["General"];
tm.writeConfig("launchers", ["applications:org.kde.dolphin.desktop","applications:firefox-esr.desktop","applications:org.kde.konsole.desktop","applications:org.kde.discover.desktop","applications:clamtk.desktop","applications:org.kde.plasma-systemmonitor.desktop","applications:systemsettings.desktop","applications:protocolos-blackout.desktop"].join(","));
tm.writeConfig("showOnlyCurrentDesktop", "false");
tm.writeConfig("iconSpacing", "2");
dock.addWidget("org.kde.plasma.trash");
