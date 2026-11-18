# postmarketOS + Phosh на ядре mainline для Samsung Galaxy M52 5G (m52xq) — полное руководство

Релиз «unofficial v1», 18.11.2026. English: [MANUAL-EN.md](MANUAL-EN.md).

## 1. Что это

postmarketOS edge с systemd и Phosh 0.58 на ядре mainline Linux 7.1.13 для Samsung Galaxy M52 5G
(SM-M526B / SM-M526BR, Snapdragon 778G / SM7325 «yupik»). Без Halium, libhybris, ядра и служб Android.
Аппаратный слой (ядро, дерево устройства, службы `m52xq-*`) общий с портами Plasma Mobile, Ubuntu Lomiri и
postmarketOS Lomiri для этого же телефона. Личный неофициальный проект, проверен на одном SM-M526B.

## 2. Что работает

Таблица — в [README](../README.md#what-works). Коротко: звонки, SMS и мобильный интернет на двух SIM, Wi-Fi, Bluetooth
(со звуком), GPS, датчики, звук, Phosh на GPU, все четыре камеры (фото 64 Мп, видео через Venus до 4K), глубокий сон
с пробуждением на звонки, SMS и будильник. Не работает: отпечаток пальца, VoLTE.

Известные недостатки: качество картинки камер при слабом свете (пелена, шум), редкое замирание видоискателя после многих
переключений, экран у уха иногда включается, около 80 мА во сне (аудио-DSP пока не засыпает), редкое падение прошивки Wi-Fi
при засыпании, короткая чёрная пауза при повороте.

## 3. Что нужно

- Разблокированный загрузчик (OEM unlock), TWRP для m52xq:
  <https://github.com/saadelasfur/Action-Recovery-Builder/releases/tag/20261004173308>.
- Резервные копии EFS, persist, modem, boot, vendor_boot, vbmeta (TWRP Backup) и стоковая прошивка для Odin.
- Перед установкой должна стоять прошивка на базе Samsung (сток, UN1CA или LineageOS): установщик берёт прошивки
  устройства из её разделов `vendor`, `apnhlos`, `modem`, `persist`, `efs`. UN1CA_3.1.0 даёт самый большой раздел `system`.

## 4. Установка

### 4.1. Архив для TWRP

1. Скачайте [postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip](https://drive.google.com/file/d/1j3U80MAcUWkaXCpt41vcyFUClD5SpIIp/view?usp=sharing) (md5 `946280ae620d3f04feb7e25a009fb492`) и скопируйте на карту microSD (или `adb push` в `/data` после
   Format Data в TWRP).
2. В TWRP:

```
Wipe - Format Data - yes - enter - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - Select Storage - Micro SD card - postmarketos-phosh-m52xq-mainline-v1-UNOFFICIAL.zip - Swipe to confirm Flash - Reboot System
```

3. Дождитесь `Updater process ended with RC=0`. Первая загрузка дольше обычной.

Что делает установщик: увеличивает `system` до 8 000 000 000 байт в метаданных LP, проверяет, что образ помещается,
записывает образ из двух частей, записывает boot, vendor_boot и dtbo, копирует прошивки устройства из разделов самого
телефона (только чтение), добавляет прошивку IPA в рамдиск boot, готовит реестр датчиков для ADSP, накладывает файлы
`m52xq-*` и включает службы, а при первой загрузке переносит `/home` на раздел userdata.

Телефон при установке греется. Если на экране уже есть вертикальные цветные полосы — не ставьте: нагрев может их усилить.

### 4.2. Пароль и доступ

- Пароль по умолчанию (разблокировка экрана, `user`, `root`): `1111`. Сменить: `passwd` в приложении «Консоль».
- SSH по USB (RNDIS, примерно через 30 с после загрузки): `ssh root@172.16.42.1`, пароль `1111`.
- Снимок экрана: громкость вверх + вниз, файл в `~/Pictures/Screenshots`.
- Приложение «Меню перезагрузки»: перезагрузка, перезагрузка в рекавери (TWRP), выключение.
- Приложение «SIM cards manager» (`m52xq-sim-manager`): обе SIM / только SIM 1 / только SIM 2, SIM для интернета.
- Мобильный интернет: Настройки - Мобильная сеть или плитка данных в быстрых настройках Phosh (подключение «Mobile data»,
  APN `internet`; если оператору нужен другой APN — поменяйте его в Настройки - Мобильная сеть).

## 5. Возврат на Android

Войдите в TWRP («Меню перезагрузки» - «Перезагрузка в рекавери» или кнопки питание + громкость). Заранее скопируйте архив
прошивки на карту microSD.

```
Wipe - Format Data - yes - enter - Back - Back - Back - Advanced Wipe - Data - Repair or Change File System - Change File System - EXT4 - Swipe to Change - Back - Back - Back - Back - Back - Install - lineage-23.2-2026-nightly-m52xq-signed.zip - Back - Back - Wipe - Format Data - enter - Reboot System
```

Архивы LineageOS и UN1CA сами перезаписывают boot, vendor_boot и dtbo. Сток: Odin или Heimdall (BL, AP, CP, CSC).

## 6. Ядро

Mainline Linux 7.1.13, исходники <https://github.com/korryasdlerto-lgtm/sc7280-mainline-linux-m52xq>, конфиг и
патчи этого релиза — в [`../kernel/`](../kernel/README.md). Образы boot, vendor_boot и dtbo лежат в архиве (`firmware/`).
DTB — из [`../device-tree/`](../device-tree).

## 7. Сборка с нуля

1. pmbootstrap 3.x со своим рабочим каталогом; конфиг [`../image/pmbootstrap-phosh.cfg`](../image/pmbootstrap-phosh.cfg)
   (устройство `samsung-m52xq`, оболочка `phosh`, systemd, `build_pkgs_on_install = False`).
2. Пакет устройства: [`../device-pkg/device-samsung-m52xq`](../device-pkg/device-samsung-m52xq) в pmaports `device/testing`.
3. Пересобранные пакеты: каждую папку из [`../build/`](../build) — в pmaports `temp/`, затем
   `pmbootstrap build --arch aarch64 <имя>` (calls, snapshot, libcamera, phosh, phosh-mobile-settings, modemmanager,
   chatty, ffmpeg7, libssc, m52xq-rawphoto). Snapshot под qemu собирать с `options="net !check"` (тесты cargo там виснут).
4. Образ и архив: [`../image/build-image.sh`](../image/build-image.sh): `pmbootstrap install`, образ 5 ГБ с сектором 4096,
   замена пакетов, которые pmbootstrap ставит новее проверенных (Phosh 0.59, phoc 0.59, ModemManager git20261005),
   состояние первой загрузки, ужатие ФС (+ около 200 МБ под прошивки, которые добавит установщик), нарезка на две части, zip.
5. Состав папки архива: `META-INF/` ([`../installer/`](../installer)), `mainline-extras/rootfs-files/`
   ([`../rootfs-overlay/`](../rootfs-overlay) + бинарные файлы из `EXCLUDED-FILES.txt`), `firmware/` (boot, vendor_boot,
   dtbo-frag), `data/rootfs-chunks/`.

Все команды сборки релиза с выводом — [ИНСТРУКЦИЯ.md](ИНСТРУКЦИЯ.md), раздел «в8: сборка релизного архива».

## 8. Устройство репозитория

См. [README](../README.md#repository-layout).

## 9. Пересобранные пакеты (`build/`)

См. [README](../README.md#rebuilt-packages-build).

## 10. Службы и скрипты (overlay)

| Имя | Что делает |
|---|---|
| `m52xq-adsp-start`, `m52xq-audio-reprobe`, `m52xq-audio-rescue` | запуск ADSP, когда прошивка доступна на корне; подъём звуковой карты после гонки старта ADSP |
| `m52xq-modem-setup`, `m52xq-sim-mode*`, `m52xq-dds`, `m52xq-nas-mode`, `m52xq-flight-mode` | сессия модема и GNSS, режим SIM (обе / SIM 1 / SIM 2), SIM для интернета, режимы сети, режим полёта для сотовой части |
| `m52xq-voicecall`, `m52xq-callaudiod`, `m52xq-voice-mixers.sh`, `m52xq-usb-call-bridge` | голосовой тракт модема на время звонка (q6voice + микшеры кодека), D-Bus API CallAudio для Calls, мост на USB-гарнитуру |
| `m52xq-tfa-guard` | повторно открывает громкий динамик, если настройка усилителя TFA9878 не удалась |
| `m52xq-audio-route`, `m52xq-voip-audio`, `m52xq-speakerphone` | звук приложений (звонки Telegram, медиа): динамик, разговорный динамик, гарнитуры |
| `m52xq-incall-proximity` | у уха в звонке гасит экран и блокирует касания |
| `m52xq-idle-suspend` | свой уход в сон по бездействию (не спит, пока приложение запрещает, например при записи видео) |
| хуки system-sleep | тёмное пробуждение (панель не загорается от сети), пауза GPS, модем в 2G во сне, Wi-Fi не рвётся, уровень питания UFS, камеры выключены, меньше лишних пробуждений |
| `m52xq-wake-restore`, `m52xq-bt-restore` | возвращают Bluetooth, режимы сети и GPS, когда пользователь действительно взял телефон |
| `m52xq-wow-params`, `m52xq-wpss-guard`, `m52xq-wpss-restart` | флаги пробуждения по Wi-Fi, защита от цикла падений WPSS и холодный перезапуск |
| `m52xq-bt-firmware`, `m52xq-bt-addr.py`, `m52xq-bt-autoconnect` | перезагрузка прошивки Bluetooth, собственный BD-адрес телефона, подключение сопряжённых наушников |
| `m52xq-sensor-kick` | перезапуск iio-sensor-proxy, когда поднялись датчики ADSP (автоповорот) |
| `m52xq-virtualcam` | виртуальные веб-камеры V4L2 (libcamera → v4l2loopback) для Telegram и браузеров |
| `m52xq-home-on-userdata` | `/home` на разделе userdata |
| `m52xq-vol-screenshot`, `m52xq-reboot-menu`, `m52xq-sim-manager` | снимок экрана кнопками, меню перезагрузки, менеджер SIM |
| `m52xq-backlight-min` | после перезагрузки с притушенным экраном яркость не остаётся почти чёрной |

## 11. Ловушки (коротко)

- Таблицу разделов образа писать на loop-устройство с сектором 4096, а не в файл образа (сектор 512).
- e2fsck старого хоста не понимает функции ext4 образа (`orphan_file`): проверять e2fsck из native-chroot pmbootstrap.
- pmbootstrap ставит самые новые Phosh, phoc и ModemManager: заменить на проверенные (см. скрипт сборки).
- Две копии libcamera (PipeWire и приложение с libcamerasrc) оставляли включёнными связи camss друг у друга за спиной;
  патч libcamera 0010 выставляет связи, не доверяя кэшу флагов.
- Датчик приближения стоит под OLED и при выключенной панели ничего не видит.
- `MODVERSIONS` выключен: модули ядра — только с тем же Image.

## 12. Благодарности

postmarketOS и pmbootstrap, Phosh / phoc / GNOME (Calls, Snapshot), libcamera, ModemManager, разработчики mainline Linux
для Qualcomm SC7280 / QCM6490, LineageOS (исходники для сверки), сопровождающие TWRP для m52xq.
