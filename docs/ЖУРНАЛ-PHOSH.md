# Журнал: postmarketOS + Phosh для m52xq

## 2026-11-09 — первый образ корня

Цель: рутфс postmarketOS с Phosh в `~/Templates/майнлайн/дроидиан/постмаркет`. Чистый Phosh и модули 7.1.13; правки m52xq потом,
по одной.

1. Отдельный рабочий каталог pmbootstrap: основной (`~/.local/var/pmbootstrap`) настроен под Plasma (ui=plasma-mobile, закреплённые
   версии KDE 6.28), смена ui там пересоздала бы его rootfs-chroot.

   ```sh
   D=~/Templates/майнлайн/дроидиан/постмаркет; W=$D/work; O=~/.local/var/pmbootstrap
   mkdir -p $W/packages/edge/aarch64 $W/config_apk_keys $W/config_abuild
   cp $O/version $W/
   cp $O/packages/edge/aarch64/device-samsung-m52xq-1-r6.apk $O/packages/edge/aarch64/linux-samsung-m52xq-7.1.2-r1.apk $W/packages/edge/aarch64/
   cp $O/config_apk_keys/pmos@local-6aa7025b.rsa.pub $W/config_apk_keys/
   sudo cp -a $O/config_abuild/. $W/config_abuild/; sudo chown -R 12345:12345 $W/config_abuild
   PB="/opt/python3.10/bin/python3.10 ~/Templates/майнлайн/tools/pmbootstrap/pmbootstrap.py -c $D/pmbootstrap-phosh.cfg"
   ```

   Конфиг: `image/pmbootstrap-phosh.cfg`. Канал systemd-edge, pmaports main (с локальными правками).

2. `$PB index` упал: `Can't open ".SIGN.RSA.pmos@local-6aa7025b.rsa.pub" for writing, Permission denied`.
   Причина: папку `packages` создал пользователь хоста, а подписывает `pmos` (uid 12345). Исправление:
   `sudo chown -R 12345:12345 $W/packages`, затем `$PB index` — DONE.

3. `$PB -y install --password 1111 --split` — пакеты встали (1072 в рутфс), упал `mkinitfs`:

   ```
   unable to add "/usr/sbin/losetup": EvalSymlinks: too many links
   ```

   `usr/sbin -> bin`, а `usr/bin/losetup -> /usr/sbin/losetup` (сам на себя). Пакет `losetup` 2.42.4-r3 ставит обычный файл
   `sbin/losetup`; симлинк создал post-install нашего `device-samsung-m52xq` r6 (`ln -sf /usr/sbin/losetup /usr/bin/losetup`,
   костыль из времени до объединения /usr).

   Восстановление в собираемом рутфс: `$PB chroot -r -- apk fix losetup` (файл 67688 байт вернулся).

4. Повторный `$PB -y install --password 1111 --split` — EXIT=0. Образы `samsung-m52xq-root.img` (2 463 105 024 байт) и
   `samsung-m52xq-boot.img` (536 870 912 байт) скопированы из `work/chroot_native/home/pmos/rootfs/` в `$D`.

5. Модули ядра #444 (23 .ko, из `убунтутач24/003/в6/rootfs-files/lib/modules/7.1.13`):

   ```sh
   sudo mount -o loop $D/samsung-m52xq-root.img $D/mnt
   sudo mkdir -p $D/mnt/usr/lib/modules; sudo cp -a .../lib/modules/7.1.13 $D/mnt/usr/lib/modules/
   sudo chown -R 0:0 $D/mnt/usr/lib/modules/7.1.13; sudo depmod -b $D/mnt 7.1.13
   sudo umount $D/mnt
   ```

   depmod хоста печатает `kmod_builtin_iter_next: unexpected string without modname prefix` (старый kmod), modules.dep записан (18 строк).

6. Проверка: e2fsck хоста 1.45.5 — «unsupported feature(s): FEATURE_C12» (это orphan_file). e2fsck 1.47.4 из native-chroot Alpine:
   `pmOS_root: 32321/300960 files, 527738/601344 blocks`, rc=0.

   md5: root `461bc05abc084db7e91ab3d9b9a91bf9`, boot `798935345cba5ffcc2679e0e4833ce27`.

7. Пакет устройства r7: post-install (post-upgrade — симлинк на него) делает симлинк losetup только если `/usr/bin/losetup` нет и
   `/usr/sbin` — отдельный каталог; `pkgrel=7`. Копия r6: `постмаркет/backup-device-r6/`.

   ```sh
   $PB build --arch aarch64 device-samsung-m52xq      # device-samsung-m52xq-1-r7.apk, 3563 байт
   ```

На телефоне образ ещё не загружался.
