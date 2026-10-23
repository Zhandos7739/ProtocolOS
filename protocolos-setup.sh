#!/bin/bash
# ProtocolOS setup: превращает установленный Debian 13 / Ubuntu 24.04+ / KDE neon (KDE Plasma 6) в ProtocolOS.
# Запуск: sudo ./protocolos-setup.sh   (из распакованного архива ProtocolOS_build)
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Запустите через sudo"; exit 1; }
HERE=$(cd "$(dirname "$0")" && pwd)
INC="$HERE/live/config/includes.chroot_after_packages"
LIST="$HERE/live/config/package-lists/protocolos.list.chroot"
[ -d "$INC" ] || { echo "Не найден $INC"; exit 1; }
. /etc/os-release; echo "Система: $PRETTY_NAME"
command -v apt-get >/dev/null || { echo "Нужен Debian/Ubuntu (apt)"; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
# пакеты: пропускаем live-*/ядро/calamares и всё, чего нет в репозиториях
PKGS=()
for p in $(grep -vE '^\s*(#|$)' "$LIST" | grep -vE '^(live-|linux-image|calamares)'); do
  apt-cache show "$p" >/dev/null 2>&1 && PKGS+=("$p") || echo "пропуск: $p (нет в репозитории)"
done
# на Ubuntu firefox-esr нет — используем firefox
if ! apt-cache show firefox-esr >/dev/null 2>&1; then PKGS+=(firefox); fi
apt-get install -y "${PKGS[@]}"
# файлы ProtocolOS
cp -a "$INC"/. /
# скопировать skel всем существующим пользователям (uid>=1000), не перезаписывая их файлы
for h in /home/*; do u=$(basename "$h"); id "$u" >/dev/null 2>&1 || continue
  cp -an /etc/skel/. "$h"/; chown -R "$u:$u" "$h/Desktop" "$h/.config/Kvantum" "$h/.config/user-dirs.dirs" 2>/dev/null || true
  # применить раскладку при следующем входе: удалить старую конфигурацию панелей (бэкап)
  f="$h/.config/plasma-org.kde.plasma.desktop-appletsrc"; [ -f "$f" ] && mv "$f" "$f.pre-protocolos"
done
# Firefox ESR -> обычный firefox на Ubuntu
command -v firefox-esr >/dev/null || sed -i 's/firefox-esr/firefox/g' /etc/skel/Desktop/01-firefox.desktop /home/*/Desktop/01-firefox.desktop 2>/dev/null || true
/usr/local/lib/protocolos/apply-system.sh
systemctl daemon-reload
systemctl start protocolos-firstboot.service || true
echo "Готово. Перезагрузитесь и войдите в сеанс Plasma."
