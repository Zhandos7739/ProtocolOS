# ProtocolOS — оптимизация производительности

| Настройка | Где | Зачем (кратко) |
|---|---|---|
| zram (zstd, min(RAM/2, 8 ГБ)) | `/etc/systemd/zram-generator.conf.d/protocolos.conf` | Сжатый swap в RAM вместо медленного диска — меньше фризов при нехватке памяти. |
| `vm.swappiness=100` | `/etc/sysctl.d/90-protocolos.conf` | Со zram выгоднее раньше вытеснять холодные страницы в сжатую память, сохраняя кэш файлов. |
| `vm.page-cluster=0` | там же | zram не любит упреждающее чтение swap — уменьшает задержки. |
| `vm.vfs_cache_pressure=50` | там же | Дольше держит кэш каталогов/inode — Dolphin и поиск быстрее. |
| `dirty_ratio 15 / background 5` | там же | Запись на диск мелкими порциями, без долгих «подвисаний» при копировании. |
| earlyoom (`-m 5 -s 10`, бережёт plasmashell/kwin, первым убивает вкладки браузера/Electron) | `/etc/default/earlyoom` | Система не «замерзает» при OOM — убивается тяжёлый процесс, а не рабочий стол. |
| preload | пакет `preload` | Предзагружает часто используемые программы в кэш — быстрее старт Firefox/Kdenlive. |
| ananicy-cpp | — | **Нет в Debian 13**, не включён (на Arch можно поставить из AUR). |
| fstrim.timer | systemd | Еженедельный TRIM для SSD — стабильная скорость записи и ресурс. |
| CPU governor schedutil | `protocolos-cpugov.service` | Частота подстраивается по нагрузке планировщика: отзывчиво и экономно. |
| Отключены wait-online, ModemManager, man-db.timer, e2scrub, apt-daily, avahi, cups-browsed | `apply-system.sh` | Меньше сервисов при загрузке и в фоне — быстрее старт, меньше RAM. |
| `DefaultTimeoutStartSec=15s`, `StopSec=10s` | `/etc/systemd/system.conf.d/protocolos.conf` | Зависший сервис не задерживает загрузку/выключение на 90 с. |
| GRUB_TIMEOUT=1 (установленная система) | `/etc/default/grub` | Быстрее загрузка. |
| Без сплэш-экрана KSplash | `/etc/xdg/ksplashrc` | Рабочий стол появляется сразу. |
| Baloo (индексатор файлов) выключен | `/etc/xdg/baloofilerc` | Главный «пожиратель» CPU/IO в KDE после входа. |
| KWin: `LatencyPolicy=Low`, анимации ×0.7, без wobbly | `/etc/xdg/kwinrc`, `kdeglobals` | Лёгкий композитинг: отзывчивость; оставлен только blur/contrast ради «стекла». |
| ClamAV clamonacc и сигнатуры с `Nice`/IO idle | override-юниты | Антивирус не мешает интерактивной работе. |
| `--apt-recommends false` в сборке | `lb config` (`live/config/common`) | Меньше лишних пакетов — образ меньше, система легче. |
