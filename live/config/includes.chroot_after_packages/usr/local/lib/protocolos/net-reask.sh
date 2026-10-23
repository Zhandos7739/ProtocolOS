#!/bin/sh
# Раз в неделю: удалить разрешения, выданные пользователем, чтобы OpenSnitch спросил заново.
# Системные правила (имена 0xx-*) не трогаем.
D=/etc/opensnitchd/rules
find "$D" -name '*.json' ! -name '0[0-9][0-9]-*' -mtime +6 -delete
systemctl restart opensnitch 2>/dev/null || systemctl restart opensnitchd 2>/dev/null || true
