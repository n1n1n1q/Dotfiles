#!/usr/bin/sh

chosen=$(printf "  Power Off\n  Restart\n  Suspend\n  Log Out\n  Lock" | wofi --dmenu --lines 8 --no-fixed-num-lines)

case "$chosen" in
	"  Power Off") poweroff;;
	"  Restart") systemctl reboot ;;
	"  Suspend") systemctl suspend ;;
	"  Log Out") wayland-logout ;;
	"  Lock") swaylock ;;
	*) exit 1 ;;
esac
