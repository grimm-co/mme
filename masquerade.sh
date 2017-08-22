#!/bin/bash
# eth0 points upstream (at the internet)
WAN_INTERFACE=eth0
# packets will be coming form our wifi interface
WIFI_INTERFACE=wlan0

# Masquerage packets coming out of the WAN interface
sudo /sbin/iptables -t nat -A POSTROUTING -o "$WAN_INTERFACE" -j MASQUERADE

# Connections which are established or related are allowed
sudo /sbin/iptables -A FORWARD -i "$WAN_INTERFACE" -o "$WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
# Outbound connections are allowed
sudo /sbin/iptables -A FORWARD -i "$WIFI_INTERFACE" -o "$WAN_INTERFACE" -j ACCEPT

