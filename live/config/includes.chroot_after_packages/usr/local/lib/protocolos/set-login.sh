#!/bin/sh
# Login: protocol / protocol
id protocol >/dev/null 2>&1 || useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,cdrom protocol
echo 'protocol:protocol' | chpasswd
