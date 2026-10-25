# ProtocolOS — сборка и установка

База: **Debian 13 «trixie» + KDE Plasma 6** (live-build). Выбрана, потому что сборочная машина — Debian 13 с sudo, и live-build работает нативно.

## Состав архива
- `live/` — профиль live-build (`config/package-lists`, `config/includes.chroot_after_packages`, `config/hooks`).
- `protocolos-setup.sh` — превращает уже установленный Debian 13 / Ubuntu 24.04+ / KDE neon с Plasma 6 в ProtocolOS.
- `OPTIMIZATION.md` — список оптимизаций.
- `test_shots/` — скриншоты из тестового запуска в QEMU.

## Сборка ISO
```
sudo apt install live-build debootstrap squashfs-tools xorriso
cd live && sudo lb build        # ~20–40 минут, нужно ~15 ГБ места и интернет
# результат: live/live-image-amd64.hybrid.iso
```
Live-пользователь: `protocol`, пароль live-boot по умолчанию: `live`. Установка на диск — ярлык «Install Debian» (Calamares).

## Вариант без ISO
```
unzip ProtocolOS_build.zip && cd ProtocolOS_build
sudo ./protocolos-setup.sh
```
Скрипт ставит пакеты, копирует файлы, включает сервисы и применяет раскладку рабочего стола (старый конфиг панелей сохраняется как `*.pre-protocolos`). Потом перезагрузка.

## Тест в VirtualBox
1. Новая ВМ: Linux / Debian 64-bit, 4 ГБ RAM (минимум 3), 2+ CPU, диск 30 ГБ.
2. Дисплей: VMSVGA, 128 МБ видео, включить 3D (для blur).
3. Система → включить EFI (по желанию; ISO грузится и в BIOS, и в UEFI).
4. Носители → вставить ISO → запуск → «Live system».

## Запись на флешку
- **Ventoy**: установить Ventoy на флешку, просто скопировать ISO на неё, загрузиться с флешки и выбрать ProtocolOS.
- **Rufus** (Windows): выбрать ISO, схема GPT для UEFI (MBR для старых ПК). На вопрос о режиме выбрать **«DD-образ»** (ISO гибридный).
- Linux: `sudo dd if=live-image-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync`.

## Что включено
- Firefox ESR, Discord (Flatpak, Flathub; если при сборке не было сети — ставится при первом запуске с сетью).
- ClamAV + clamd + clamonacc (реальное время в /home) + ClamTk; доп. сигнатуры URLhaus и Sanesecurity — `protocolos-sigs-update` по таймеру каждые 6 ч (пакета clamav-unofficial-sigs в Debian 13 нет, поэтому своя замена).
- OpenSnitch: `DefaultAction=deny` — неизвестный процесс не выходит в интернет, пока вы не разрешите во всплывающем окне. Заранее (навсегда) разрешены только системные службы: NetworkManager/DHCP, resolved/timesyncd, freshclam, apt, flatpak-helper, curl только к зеркалам сигнатур. Firefox, Discord, Discover и остальные приложения спрашивают при каждом выходе в сеть; раз в неделю пользовательские разрешения сбрасываются.
- Тема: по умолчанию тёмная — на рабочем столе ночные/чёрные обои (`ProtocolOS`), на экране блокировки дневные (`ProtocolOS-day`). Переключение: `protocolos-theme toggle` (или «Тема ProtocolOS» в меню). Мультимонитор: плитки и панели только на основном экране, обои на всех; окна в доке со всех мониторов.
- ufw: входящие запрещены, исходящие разрешены. AppArmor включён, профили в enforce.
- Blackout: `protocolos-blackout on|off|toggle|status`, ярлык на столе и в доке, переключатель в виджете «Защита». Делает `nmcli networking off` + rfkill + таблицу nftables с drop-all (приоритет −500, работает поверх ufw/OpenSnitch).
- Kooha и OBS Studio (запись экрана), Kdenlive (видеоредактор).
- Иконки — тема Papirus-Dark (никаких эмодзи).

## Соответствие макету (shots/01_desktop.png, 18–20)
| Элемент макета | Реализация | Совпадение |
|---|---|---|
| Ночные обои | стол = `ProtocolOS` (night), блокировка = `ProtocolOS-day` (swap), SDDM = night | полное |
| Верхняя полупрозрачная строка | плавающая панель Plasma сверху, тема Breeze Dark + blur | близко |
| «ProtocolOS» слева | Kickoff с подписью «ProtocolOS» и иконкой-щитом | близко (вместо ромба — щит) |
| «Файл Вид Окно» | виджет «Глобальное меню» (показывает меню активного приложения) | функционально |
| Значок «Защита активна» | собственный плазмоид `org.protocolos.shield` (капсула) | близко |
| Wi‑Fi, батарея, RU, дата | системный лоток + раскладка + часы с датой | близко |
| Температура CPU | System Monitor Sensor (text-only), `cpu/all/averageTemperature` | близко (в ВМ датчика нет — пусто) |
| Стеклянные плитки приложений | значки рабочего стола (Folder View, крупные) | **частично**: Plasma рисует значки без «стеклянной» подложки-карточки |
| «Sandbox Mod» (игра 4.2 ГБ) | заменён на Discord — игры в составе нет | нет |
| Правая колонка папок | второй Folder View справа (Проекты, Документы, Загрузки, Изображения, Система, Корзина) | близко |
| Виджет «Защита активна» + Блэкаут | плазмоид: статусы clamonacc/последняя проверка/AppArmor/ufw + переключатель Blackout | близко |
| Плавающий док по центру | нижняя плавающая панель Plasma 6, «по содержимому», по центру; Latte Dock не используется (заброшен, не работает с Plasma 6) | близко |
| Win → полноэкранное меню | Meta → `activateLauncherMenu` → Application Dashboard (kickerdash) | функционально; анимация «выезжающей шторки» из 19–20 не воспроизводится — Plasma показывает дашборд с затуханием |
| Liquid Glass | Kvantum «ProtocolGlass» (KvArcDark + прозрачность + blur) + эффект KWin Blur/Contrast | приближённо: настоящего преломления/«жидкого» стекла в KDE нет |
