#!/bin/sh
wlan0=
wlan1=
# hostapd won't be able to configure driver mode unless this is done:
nmcli radio wifi off
rfkill unblock wlan
if [ -n "$wlan0" ]; then
  echo "Bringing up $wlan0"
  ip link set dev "$wlan0" up
fi
if [ -n "$wlan1" ]; then
  echo "Bringing up $wlan1"
ip link set dev "$wlan1" up
fi
