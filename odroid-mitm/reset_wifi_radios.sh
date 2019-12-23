#!/bin/sh
# hostapd won't be able to configure driver mode unless this is done:
sudo nmcli radio wifi off
sudo rfkill unblock wlan
sudo ifconfig wlan0 up
sudo ifconfig wlan1 up
