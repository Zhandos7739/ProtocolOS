# ProtocolOS — оптимизация производительности

| Настройка | Где | Зачем (кратко) |
|---|---|---|
| zram (zstd, min(RAM/2, 8 ГБ)) | `/etc/systemd/zram-generator.conf.d/protocolos.conf` | Сжатый swap в RAM вместо медленного диска — меньше фризов при нехватке памяти. |
| `vm.swappiness=100` | `/etc/sysctl.d/90-protocolos.conf` | Со zram выгоднее раньше вытеснять холодные страницы в сжатую память, сохраняя кэш файлов. |
| `vm.page-cluster=0` | там же | zram не любит упреждающее чтение swap — уменьшает задержки. |
| `vm.vfs_cache_pressure=50` | там же | Дольше держит кэш каталогов/inode — Dolphin и поиск быстрее. |
| `dirty_ratio 15 / background 5`, writeback 1.5 с | там же | Запись на диск мелкими порциями, без долгих «подвисаний» при копировании. |
| BBR + fq_codel + TCP Fast Open | там же | Меньше bufferbloat, быстрее коротких HTTPS-сессий. |
| earlyoom (`-m 5 -s 10`, бережёт plasmashell/kwin, первым убивает вкладки браузера/Electron) | `/etc/default/earlyoom` | Система не «замерзает» при OOM — убивается тяжёлый процесс, а не рабочий стол. |
| preload | пакет `preload` | Предзагружает часто используемые программы в кэш — быстрее старт Firefox/Kdenlive. |
| ananicy-cpp | — | **Нет в Debian 13**, не включён (на Arch можно поставить из AUR). |
| fstrim.timer | systemd | Еженедельный TRIM для SSD — стабильная скорость записи и ресурс. |
| CPU governor schedutil | `protocolos-cpugov.service` | Частота подстраивается по нагрузке планировщика: отзывчиво и экономно. |
| Отключены wait-online, ModemManager, man-db.timer, e2scrub, apt-daily/-upgrade, avahi, cups-browsed | `apply-system.sh` | Меньше сервисов при загрузке и в фоне — быстрее старт, меньше RAM. |
| Nice/idle для ClamAV, freshclam, preload, OpenSnitch | override-юниты | Фоновая защита не отбирает CPU у UI. |
| journald ≤64 МБ, coredump=none | `journald.conf.d`, `coredump.conf.d` | Меньше IO и диска на логи/дампы. |
| `DefaultTimeoutStartSec=15s`, `StopSec=10s` | `/etc/systemd/system.conf.d/protocolos.conf` | Зависший сервис не задерживает загрузку/выключение на 90 с. |
| GRUB_TIMEOUT=5 (дуалбут) | `/etc/default/grub.d/protocolos.cfg` | Меню видно для Windows; не ужимать в ущерб dual-boot. |
| Без сплэш-экрана KSplash | `/etc/xdg/ksplashrc` | Рабочий стол появляется сразу. |
| Baloo (индексатор файлов) выключен | `/etc/xdg/baloofilerc` | Главный «пожиратель» CPU/IO в KDE после входа. |
| KWin: Low latency, MaxFPS=60, blur×8 без noise, без тяжёлых эффектов | `/etc/xdg/kwinrc` | Лёгкий композитинг; tear для игр/видео разрешён. |
| Анимации ×0.55 | `kdeglobals` | Короче переходы, отзывчивее UI. |
| **Один** shared wallpaper blur (`WallBlur`) + маска на плитках | `org.protocolos.tiles` | Раньше каждая стеклянная плитка делала свой MultiEffect blur обоев — главный GPU-расход на столе. |
| wallsync на inotify (не poll 4 с) | `protocolos-wallsync` + `inotify-tools` | Почти ноль CPU в простое; синхрон при смене обоев/темы. |
| Статус защиты раз в 45 с, один `systemctl is-active` | `protocolos-status`, shield/tiles | Меньше fork/exec в фоне. |
| `--apt-recommends false` в сборке | `lb config` (`live/auto/config`) | Меньше лишних пакетов — образ меньше, система легче. |
