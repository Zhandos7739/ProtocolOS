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
# SDDM фон
T=/usr/share/sddm/themes/breeze; [ -d $T ] && printf '[General]\nbackground=/usr/share/wallpapers/ProtocolOS/contents/images/1920x1080.jpg\ntype=image\n' > $T/theme.conf.user
# ufw: deny incoming
sed -i 's/^DEFAULT_INPUT_POLICY=.*/DEFAULT_INPUT_POLICY="DROP"/; s/^DEFAULT_OUTPUT_POLICY=.*/DEFAULT_OUTPUT_POLICY="ACCEPT"/' /etc/default/ufw 2>/dev/null
sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf 2>/dev/null
# OpenSnitch: неизвестное = запрет
C=/etc/opensnitchd/default-config.json; if [ -f $C ]; then
  python3 - "$C" <<'PY'
import json,sys; p=sys.argv[1]; c=json.load(open(p))
c["DefaultAction"]="deny"; c["DefaultDuration"]="once"; c["InterceptUnknown"]=True; c["ProcMonitorMethod"]="ebpf"
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
# сервисы
for s in ufw apparmor opensnitch clamav-daemon clamav-freshclam clamav-clamonacc earlyoom preload fstrim.timer protocolos-firstboot protocolos-cpugov protocolos-sigs.timer protocolos-net-reask.timer protocolos-login NetworkManager sddm; do systemctl enable $s >/dev/null 2>&1 && log "enabled $s"; done
for s in NetworkManager-wait-online.service systemd-networkd-wait-online.service ModemManager.service man-db.timer e2scrub_all.timer e2scrub_reap.service apt-daily.timer cups-browsed.service avahi-daemon.service; do systemctl disable $s >/dev/null 2>&1 && log "disabled $s"; done
systemctl mask NetworkManager-wait-online.service >/dev/null 2>&1 || true
# Flathub + Discord
if command -v flatpak >/dev/null; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
  [ "${PROTOCOLOS_SKIP_DISCORD:-0}" = 1 ] || flatpak install -y --noninteractive flathub com.discordapp.Discord || log "Discord: будет установлен при первом запуске"
fi
# GRUB timeout для установленной системы
[ -f /etc/default/grub ] && sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
log done
