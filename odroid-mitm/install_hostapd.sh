#!/bin/sh
# Install and configure hostapd
wlan_iface="$1"
wlan_mitm="$2"

# Install hostapd
apt-get install -y hostapd

# Configure hostapd
echo "DAEMON_CONF=/etc/hostapd/hostapd.conf" | tee -a /etc/default/hostapd
cp hostapd.conf /etc/hostapd/

# hostapd won't be able to configure driver mode unless this is done:
nmcli radio wifi off
rfkill unblock wlan

if [ -n "$wlan_iface" ]; then
	echo "Bringing up $wlan_iface"
	ip link set dev "$wlan_iface" up
fi
if [ -n "$wlan_mitm" ]; then
	echo "Bringing up $wlan_mitm"
	ip link set dev "$wlan_mitm" up
fi

# Start hostapd
systemctl unmask hostapd

systemctl start hostapd
systemctl enable hostapd
