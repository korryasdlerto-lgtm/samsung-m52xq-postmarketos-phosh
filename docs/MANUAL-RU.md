# postmarketOS + Phosh на mainline-ядре для Samsung Galaxy M52 5G (m52xq) — инструкция

Версия документа: 2026-11-09. Состояние: **собран первый образ корня, на телефоне ещё не загружался.**

## 1. Что это

- Устройство: Samsung Galaxy M52 5G, SM-M526B / SM-M526BR, Snapdragon 778G (SM7325, платформа «yupik»), кодовое имя `m52xq`.
- Ядро: **mainline Linux 7.1.13**, сборка **#444**: то же ядро, что у порта Ubuntu Lomiri. Halium и libhybris не используются.
- Система: **postmarketOS edge** с systemd (в `/etc/os-release` она называется «Nura edge»), оболочка **Phosh 0.58** (phoc 0.58,
  клавиатура stevia). В образе 1184 пакета (`docs/packages-phosh.txt`).
- Железо телефона (ядро, прошивки, службы `m52xq-*`) общее с портом Plasma, репозиторий
  [samsung-m52xq-mainline](https://github.com/korryasdlerto-lgtm/samsung-m52xq-mainline). Здесь хранится то, что сделано для Phosh.
- Личный любительский порт, проверяется на одном SM-M526B.

## 2. Что работает

| Функция | Состояние | Примечание |
|---|---|---|
| Образ корня | собран | pmOS edge, systemd, Phosh, наш пакет устройства r7, модули 7.1.13 #444 |
| Загрузка, оболочка, экран, касания | не проверено | |
| Звонки, SMS, мобильный интернет | не проверено | в образе стоковые calls, chatty, ModemManager 1.25.95 |
| Wi-Fi, Bluetooth, звук, камера, GPS, сон | не проверено | правки m52xq из портов Plasma и Lomiri ещё не перенесены |

## 3. Что в образе

- Пакеты Phosh по умолчанию: `postmarketos-ui-phosh`, `phosh-mobile-settings`, `phosh-tour`, `calls`, `chatty`, `firefox-esr`
  (`mobile-config-firefox`), `gnome-contacts`, `gnome-clocks`, `gnome-maps`, `gnome-weather`, `gnome-calendar`, `gnome-console`,
  `nautilus`, `snapshot` (камера), `loupe`, `papers`, `showtime`, `decibels`, `g4music`, `flatpak`, `cups` и др.
  Полный список заказанных пакетов: `image/world.txt`.
- `device-samsung-m52xq-1-r7` (`device-pkg/`).
- `/usr/lib/modules/7.1.13`: 23 модуля ядра #444 (`kernel/modules-7.1.13-444.txt`) и `depmod`.
- Пользователь `user`, пароль `1111`; sshd включён; файрвол nftables включён.

Чего в образе нет:
- **закрытых прошивок** (модем, ADSP, Venus, GPU zap, Bluetooth, датчики): их, как в других портах, будет копировать с телефона установщик;
- правок m52xq (службы `m52xq-*`, ModemManager с патчами DSDS, звук, сон Wi-Fi, камера). Их переносим по одной, каждую проверяем на телефоне;
- установщика TWRP.

## 4. Пакет устройства r7

`device-pkg/device-samsung-m52xq` — копия `device/testing/device-samsung-m52xq` из наших pmaports.

Изменение r6 → r7 (2026-11-09): в post-install стояла команда `ln -sf /usr/sbin/losetup /usr/bin/losetup`. Она осталась со времён,
когда в edge `/usr/sbin` был отдельным каталогом. Сейчас в edge объединённый `/usr` (`/usr/sbin → bin`), поэтому команда заменяла
настоящий `losetup` симлинком на самого себя, и `mkinitfs` падал:

```
hookfiles: unable to process hook file "/usr/share/mkinitfs/files/00-initramfs-base.files":
unable to add "/usr/sbin/losetup": EvalSymlinks: too many links
```

Теперь симлинк создаётся, только если `/usr/bin/losetup` нет, а `/usr/sbin` — отдельный каталог. Если петля уже есть (стоял r6),
бинарник возвращает `apk fix losetup`.

## 5. Сборка образа

Сборка идёт в отдельном рабочем каталоге pmbootstrap, чтобы не тронуть рабочие каталоги портов Plasma и Lomiri.
Скрипт: `image/build-rootfs.sh`; конфиг: `image/pmbootstrap-phosh.cfg`.

```sh
OUT=~/Templates/майнлайн/дроидиан/постмаркет PKGS=/путь/к/apk \
MODULES=/путь/к/lib/modules/7.1.13 \
PMB="/opt/python3.10/bin/python3.10 ~/Templates/майнлайн/tools/pmbootstrap/pmbootstrap.py" \
./image/build-rootfs.sh
```

Что делает скрипт:
1. создаёт рабочий каталог с файлом `version`, локальным репозиторием из двух уже собранных пакетов (`device-samsung-m52xq-1-r7`,
   `linux-samsung-m52xq-7.1.2-r1`; пакет ядра — заглушка, настоящее ядро в boot.img) и ключом подписи; владельцем ставит uid 12345
   (пользователь `pmos` внутри chroot), иначе `pmbootstrap index` не может подписать индекс;
2. пишет конфиг с `build_pkgs_on_install = False`, чтобы pmbootstrap не стал сам собирать пакеты из локальных правок `temp/`;
3. `pmbootstrap index`, `pmbootstrap install --password 1111 --split`, `pmbootstrap shutdown`;
4. накладывает модули 7.1.13 в `/usr/lib/modules` и запускает `depmod`;
5. пишет md5.

Результат (2026-11-09):

| Файл | Размер | md5 |
|---|---|---|
| `samsung-m52xq-root.img` | 2 463 105 024 байт (ext4, `pmOS_root`, блок 4096) | `461bc05abc084db7e91ab3d9b9a91bf9` |
| `samsung-m52xq-boot.img` | 536 870 912 байт | `798935345cba5ffcc2679e0e4833ce27` |

Проверка: `e2fsck 1.47.4 -fn` — ошибок нет. В образе включён `orphan_file`. Старый e2fsck (1.45 на хосте) считает это ошибкой
(«FEATURE_C12»); это нужно учесть для resize2fs и e2fsck в TWRP, когда будет установщик.

## 6. Дальше

1. установщик TWRP по образцу порта Lomiri (boot 7.1.13 #444, vendor_boot, dtbo-frag, system, прошивки с телефона);
2. первая загрузка, журналы;
3. перенос правок m52xq из портов Plasma и Lomiri по одной, с проверкой каждой.
