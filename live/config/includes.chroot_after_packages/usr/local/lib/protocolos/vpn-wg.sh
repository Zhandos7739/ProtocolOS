#!/bin/bash
# root: wg-quick up/down для профилей ProtocolOS
set -eu
op="${1:-}"
case "$op" in
  up)
    conf=${2:-}; name=${3:-protocolos}
    [ -f "$conf" ] || exit 1
    # интерфейс = имя профиля (ограничим символы)
    iface=$(echo "$name" | tr -cd 'a-zA-Z0-9_-' | head -c 15)
    [ -z "$iface" ] && iface=posvpn0
    cp "$conf" "/etc/wireguard/${iface}.conf"
    chmod 600 "/etc/wireguard/${iface}.conf"
    wg-quick down "$iface" 2>/dev/null || true
    wg-quick up "$iface"
    ;;
  down)
    iface=${2:-}
    [ -n "$iface" ] && wg-quick down "$iface" 2>/dev/null || true
    ;;
  down-all)
    for f in /etc/wireguard/*.conf; do
      [ -e "$f" ] || continue
      wg-quick down "$(basename "$f" .conf)" 2>/dev/null || true
    done
    ;;
  *)
    echo "usage: $0 up <conf> <name>|down <iface>|down-all" >&2
    exit 2
    ;;
esac
