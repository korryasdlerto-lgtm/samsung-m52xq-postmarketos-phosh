#!/bin/sh
# m52xq (pmOS Phosh, from pm-Plasma v50): no camera may stay powered while the system sleeps. m52xq-virtualcam sees
# /run/m52xq-camera-sleep and stops its real camera pipeline (black frames only); after the resume the flag goes away.
F=/run/m52xq-camera-sleep
VSTATE=/home/user/.cache/m52xq-virtualcam-state
case "$1" in
pre)
	touch $F
	i=0
	while [ $i -lt 40 ] && [ -f $VSTATE ] && [ "$(cat $VSTATE 2>/dev/null)" != off ]; do sleep 0.1; i=$((i + 1)); done
	;;
post)
	rm -f $F
	;;
esac
exit 0
