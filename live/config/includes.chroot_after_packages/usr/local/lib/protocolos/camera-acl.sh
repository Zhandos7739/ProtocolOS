#!/bin/bash
# root-хелпер: доступ к /dev/video* (pkexec)
set -eu
op="${1:-deny}"
case "$op" in
  deny)
    for v in /dev/video*; do
      [ -e "$v" ] || continue
      chmod 000 "$v" || true
    done
    ;;
  allow)
    modprobe uvcvideo 2>/dev/null || true
    sleep 0.2
    udevadm trigger --subsystem-match=video4linux --action=change 2>/dev/null || true
    for v in /dev/video*; do
      [ -e "$v" ] || continue
      chmod 660 "$v" || true
      chgrp video "$v" 2>/dev/null || true
    done
    ;;
  *)
    echo "usage: $0 allow|deny" >&2
    exit 2
    ;;
esac
