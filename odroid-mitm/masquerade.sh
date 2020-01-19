#!/bin/sh
UPSTREAM_LAN_INTERFACE="$1"
UPSTREAM_WIFI_INTERFACE="$2"
DOWNSTREAM_LAN_INTERFACE="$3"
DOWNSTREAM_WIFI_INTERFACE="$4"

# Detect which interface is actually connected to the internet
ip link set dev $UPSTREAM_LAN_INTERFACE | grep 'inet ' &> /dev/null
if [ $? -eq 0 ]; then
  echo "Using LAN interface for Internet access"
  UPSTREAM_INTERFACE=$UPSTREAM_LAN_INTERFACE
else
  echo "Using WiFi interface for Internet access"
  UPSTREAM_INTERFACE=$UPSTREAM_WIFI_INTERFACE
fi

# Flush all previous rules so we know we're starting from a clean slate
/sbin/iptables -F
# Default policies are allow everything all the time, woohoo!
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

# Masquerage packets coming out of the LAN interface
/sbin/iptables -t nat -A POSTROUTING -o "$UPSTREAM_INTERFACE" -j MASQUERADE

# Connections which are established or related are allowed from downstream interfaces
/sbin/iptables -A FORWARD -i "$UPSTREAM_INTERFACE" \
	-o "$DOWNSTREAM_WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i "$UPSTREAM_INTERFACE" \
	-o "$DOWNSTREAM_LAN_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
# Outbound connections are allowed from downstream interfaces
/sbin/iptables -A FORWARD -i "$DOWNSTREAM_WIFI_INTERFACE" -o "$UPSTREAM_INTERFACE" -j ACCEPT
/sbin/iptables -A FORWARD -i "$DOWNSTREAM_LAN_INTERFACE" -o "$UPSTREAM_INTERFACE" -j ACCEPT

