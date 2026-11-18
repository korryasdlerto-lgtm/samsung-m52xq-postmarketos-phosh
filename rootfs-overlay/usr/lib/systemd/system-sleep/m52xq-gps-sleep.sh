#!/bin/sh
# M52XQ (Phosh, 2026-11-13): pause the GNSS engine of the modem for the sleep. With "Location" on, GeoClue keeps the
# ModemManager GPS sources (gps-nmea / gps-raw) enabled and the modem searches the satellites while the phone sleeps
# (pmOS Plasma, 24.10: ~150 mA). pre: remember the enabled GPS sources of every modem and disable them.
# post: give them back on a wake-up by the user (keys, touch); a dark wake-up (Wi-Fi, modem) keeps them paused,
# m52xq-wake-restore (started by m52xq-idle-suspend when a dark wake-up turns into a real one) gives them back then.
R=/run/m52xq-gps-paused
L=/var/log/m52xq-sleep.log
case "$1" in
pre)
	[ -f $R ] && exit 0	# still paused from an earlier sleep (dark wake-up in between)
	for m in $(mmcli -L 2>/dev/null | grep -o '/org/freedesktop/ModemManager1/Modem/[0-9]*'); do
		src=$(timeout 8 mmcli -m "$m" -K --location-status 2>/dev/null | awk -F': ' '/modem.location.enabled.value/ && ($2 == "gps-nmea" || $2 == "gps-raw") { printf "%s ", $2 }')
		[ -n "$src" ] || continue
		echo "$m $src" >> $R
		args=
		for s in $src; do args="$args --location-disable-$s"; done
		timeout 8 mmcli -m "$m" $args >/dev/null 2>&1
		echo "gps: $m paused for the sleep ($src)" >> $L
	done
	;;
post)
	[ -f $R ] || exit 0
	irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)
	name=
	[ -n "$irq" ] && name=$(awk -v i="$irq:" '$1 == i { print }' /proc/interrupts)
	case "$name" in
	*pwrkey* | *resin* | *synaptics* | *Volume* | *gpio-keys*) /usr/local/sbin/m52xq-wake-restore gps ;;
	*) echo "gps: dark wake-up, kept paused" >> $L ;;
	esac
	;;
esac
exit 0
