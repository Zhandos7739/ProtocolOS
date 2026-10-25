#!/bin/bash
# ProtocolOS: системная настройка. Используется и в сборке ISO (chroot hook), и в protocolos-setup.sh.
set -u
log(){ echo "[protocolos] $*"; }
# locale
sed -i 's/^# *ru_RU.UTF-8/ru_RU.UTF-8/; s/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen 2>/dev/null && locale-gen >/dev/null 2>&1 || true
# Kvantum "ProtocolGlass" = KvArcDark + прозрачность + blur
KV=/usr/share/Kvantum; if [ -d $KV/KvArcDark ]; then
  mkdir -p $KV/ProtocolGlass; cp $KV/KvArcDark/KvArcDark.svg $KV/ProtocolGlass/ProtocolGlass.svg
  sed -e 's/^translucent_windows=.*/translucent_windows=true/' -e 's/^blurring=.*/blurring=true/' -e 's/^popup_blurring=.*/popup_blurring=true/' \
      -e 's/^reduce_window_opacity=.*/reduce_window_opacity=18/' -e 's/^reduce_menu_opacity=.*/reduce_menu_opacity=20/' -e 's/^menu_blur_radius=.*/menu_blur_radius=12/' \
      $KV/KvArcDark/KvArcDark.kvconfig > $KV/ProtocolGlass/ProtocolGlass.kvconfig
  grep -q '^translucent_windows' $KV/ProtocolGlass/ProtocolGlass.kvconfig || sed -i '/^\[General\]/a translucent_windows=true\nblurring=true\npopup_blurring=true\nreduce_window_opacity=18' $KV/ProtocolGlass/ProtocolGlass.kvconfig
fi
# SDDM: ночной бренд-фон (логин). Стол/блокировка меняются местами через wallsync (тёмная тема).
T=/usr/share/sddm/themes/breeze; [ -d $T ] && printf '[General]\nbackground=/usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg\ntype=image\n' > $T/theme.conf.user
# Исполняемые хелперы темы/обоев
chmod +x /usr/local/bin/protocolos-wallsync /usr/local/bin/protocolos-wall-resolve /usr/local/bin/protocolos-theme /usr/local/bin/protocolos-sound /usr/local/bin/protocolos-audio /usr/local/bin/protocolos-desktop-settings /usr/local/bin/protocolos-screenshot 2>/dev/null || true
# ufw: deny incoming
sed -i 's/^DEFAULT_INPUT_POLICY=.*/DEFAULT_INPUT_POLICY="DROP"/; s/^DEFAULT_OUTPUT_POLICY=.*/DEFAULT_OUTPUT_POLICY="ACCEPT"/' /etc/default/ufw 2>/dev/null
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf 2>/dev/null
# OpenSnitch: неизвестное = запрет
C=/etc/opensnitchd/default-config.json; if [ -f $C ]; then
  python3 - "$C" <<'PY'
import json,sys; p=sys.argv[1]; c=json.load(open(p))
c["DefaultAction"]="deny"; c["DefaultDuration"]="once"; c["InterceptUnknown"]=True; c["ProcMonitorMethod"]="proc"
json.dump(c,open(p,"w"),indent=2)
PY
fi
# ClamAV on-access (clamonacc) для домашних каталогов
CF=/etc/clamav/clamd.conf; if [ -f $CF ] && ! grep -q '^OnAccessIncludePath' $CF; then
  cat >> $CF <<C
OnAccessIncludePath /home
OnAccessExcludeUname clamav
OnAccessExcludeRootUID yes
OnAccessPrevention no
OnAccessExtraScanning yes
C
fi
mkdir -p /etc/systemd/system/clamav-clamonacc.service.d
printf '[Service]\nNice=10\nIOSchedulingClass=idle\n' > /etc/systemd/system/clamav-clamonacc.service.d/protocolos.conf
mkdir -p /etc/systemd/system/clamav-daemon.service.d /etc/systemd/system/clamav-freshclam.service.d /etc/systemd/system/opensnitch.service.d /etc/systemd/system/opensnitchd.service.d /etc/systemd/system/preload.service.d
printf '[Service]\nNice=10\nIOSchedulingClass=idle\n' > /etc/systemd/system/clamav-daemon.service.d/protocolos.conf
printf '[Service]\nNice=15\nIOSchedulingClass=idle\n' > /etc/systemd/system/clamav-freshclam.service.d/protocolos.conf
printf '[Service]\nNice=5\n' > /etc/systemd/system/opensnitch.service.d/protocolos.conf
printf '[Service]\nNice=5\n' > /etc/systemd/system/opensnitchd.service.d/protocolos.conf
printf '[Service]\nNice=15\nIOSchedulingClass=idle\n' > /etc/systemd/system/preload.service.d/protocolos.conf
# BBR if the module exists (faster WAN, lower bufferbloat)
modprobe tcp_bbr 2>/dev/null || true
# сервисы
for s in ufw apparmor opensnitch clamav-daemon clamav-freshclam clamav-clamonacc earlyoom preload fstrim.timer protocolos-firstboot protocolos-cpugov protocolos-sigs.timer protocolos-net-reask.timer protocolos-login NetworkManager sddm; do systemctl enable $s >/dev/null 2>&1 && log "enabled $s"; done
for s in NetworkManager-wait-online.service systemd-networkd-wait-online.service ModemManager.service man-db.timer e2scrub_all.timer e2scrub_reap.service apt-daily.timer apt-daily-upgrade.timer cups-browsed.service avahi-daemon.service; do systemctl disable $s >/dev/null 2>&1 && log "disabled $s"; done
systemctl mask NetworkManager-wait-online.service >/dev/null 2>&1 || true
# Flathub + Discord
if command -v flatpak >/dev/null; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
  [ "${PROTOCOLOS_SKIP_DISCORD:-0}" = 1 ] || flatpak install -y --noninteractive flathub com.discordapp.Discord || log "Discord: будет установлен при первом запуске"
fi
# GRUB timeout для установленной системы
# GRUB timeout: set in /etc/default/grub.d/protocolos.cfg (5 s, menu visible for dual boot)
log done
# Ярлыки рабочего стола исполняемые (иначе Plasma 6 рисует "!")
chmod +x /etc/skel/Desktop/*.desktop 2>/dev/null
# Установщик: своё имя вместо "Install Debian"
for f in $(grep -rl "Install Debian" /usr/share/applications /etc/skel 2>/dev/null); do sed -i 's/^Name\(\[[a-zA-Z_]*\]\)\?=.*/Name=Установить ProtocolOS/' "$f"; chmod +x "$f"; done
# Стеклянная тема Plasma: недостающие элементы берём из breeze-dark/default (наши файлы не перезаписываются)
T=/usr/share/plasma/desktoptheme/protocolos-glass
for src in breeze-dark default; do
  [ -d /usr/share/plasma/desktoptheme/$src ] && cp -rn /usr/share/plasma/desktoptheme/$src/. "$T"/ 2>/dev/null || true
done
rm -f "$T"/metadata.desktop
for f in widgets/panel-background dialogs/background widgets/tooltip; do rm -f "$T/$f.svgz"; done
# Иконки ProtocolOS
gtk-update-icon-cache -f -q /usr/share/icons/hicolor 2>/dev/null || true
