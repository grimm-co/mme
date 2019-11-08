#!/bin/sh
UPSTREAM_LAN_INTERFACE=eth0
UPSTREAM_WIFI_INTERFACE=eth0
DOWNSTREAM_WIFI_INTERFACE=wlan1
DOWNSTREAM_LAN_INTERFACE=eth1

# Detect which interface is actually connected to the internet
ifconfig $UPSTREAM_LAN_INTERFACE | grep 'inet ' &> /dev/null
if [ $? -eq 0 ]; then
  UPSTREAM_INTERFACE=$UPSTREAM_LAN_INTERFACE
else
  UPSTREAM_INTERFACE=$UPSTREAM_WIFI_INTERFACE
fi

# Flush all previous rules so we know we're starting from a clean slate
sudo /sbin/iptables -F
# Default policies are allow everything all the time, woohoo!
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT

# Masquerage packets coming out of the LAN interface
sudo /sbin/iptables -t nat -A POSTROUTING -o "$UPSTREAM_INTERFACE" -j MASQUERADE

# Connections which are established or related are allowed from downstream interfaces
sudo /sbin/iptables -A FORWARD -i "$UPSTREAM_INTERFACE" \
	-o "$DOWNSTREAM_WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo /sbin/iptables -A FORWARD -i "$UPSTREAM_INTERFACE" \
	-o "$DOWNSTREAM_LAN_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
# Outbound connections are allowed from downstream interfaces
sudo /sbin/iptables -A FORWARD -i "$DOWNSTREAM_WIFI_INTERFACE" -o "$UPSTREAM_INTERFACE" -j ACCEPT
sudo /sbin/iptables -A FORWARD -i "$DOWNSTREAM_LAN_INTERFACE" -o "$UPSTREAM_INTERFACE" -j ACCEPT

