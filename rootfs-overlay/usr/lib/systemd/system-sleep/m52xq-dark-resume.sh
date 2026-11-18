#!/bin/sh
# M52XQ (Phosh): "dark" resume. The panel driver (dark_resume, boot v230+) keeps the OLED panel dark for $DARK seconds
# after the resume, so phoc's mode setting no longer flashes the display when the modem / Wi-Fi / mobile data wakes the
# phone. m52xq-idle-suspend (user service) puts the phone to sleep again. A wake-up by the power / volume keys or the
# touchscreen (or a call) is not dark: dark_resume 0. The power / volume keys end the dark window in the panel driver.
DR=/sys/module/panel_samsung_s6e3hab_amb667an01/parameters/dark_resume
DARK=${M52XQ_DARK_S:-15}
QS=/run/m52xq-qrtr-sms-events
# modem wakeup source event count (SMS / voice call): pm_wakeup_irq stays empty for the modem
qrtr_events() { for w in /sys/class/wakeup/wakeup*; do [ "$(cat $w/name 2>/dev/null)" = qrtr-voice-sms ] && cat $w/event_count && return; done; echo 0; }
[ -w "$DR" ] || exit 0
case "$1" in
pre)
	qrtr_events > $QS
	echo 0 > $DR
	# m52xq (2026-11-14): m52xq-idle-suspend (user, group video) writes 0 here when a call arrives, so the display comes on at
	# once instead of after the dark window (a call after the sleep: picture after 20-30 s)
	chgrp video $DR 2>/dev/null && chmod 664 $DR 2>/dev/null
	;;
post)
	irq=$(cat /sys/power/pm_wakeup_irq 2>/dev/null)
	name=
	[ -n "$irq" ] && name=$(awk -v i="$irq:" '$1 == i { print }' /proc/interrupts)
	case "$name" in
	*pwrkey* | *resin* | *synaptics* | *Volume* | *gpio-keys*) echo 0 > $DR ;;
	*) echo $DARK > $DR ;;
	esac
	;;
esac
exit 0
