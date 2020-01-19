#!/bin/sh
wlan0=
wlan0=
# hostapd won't be able to configure driver mode unless this is done:
nmcli radio wifi off
rfkill unblock wlan
ip link set dev "$wlan0" up
ip link set dev "$wlan1" up
