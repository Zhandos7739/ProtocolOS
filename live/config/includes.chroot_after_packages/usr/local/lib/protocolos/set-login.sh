#!/bin/sh
# Login: protocol / protocol
# live session only: never touch an installed system
[ -d /run/live/medium ] || grep -qw "boot=live" /proc/cmdline || exit 0
id protocol >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,cdrom protocol
echo 'protocol:protocol' | chpasswd
