#!/bin/sh
# Install and configure hostapd
$wlan_iface="$1"
$wlan_mitm="$2"

# Install hostapd
apt-get install -y hostapd

# Configure hostapd
echo "DAEMON_CONF=/etc/hostapd/hostapd.conf" | tee -a /etc/default/hostapd
cp hostapd.conf /etc/hostapd/

# hostapd won't be able to configure driver mode unless this is done:
nmcli radio wifi off
rfkill unblock wlan

ip link set dev "$wlan_iface" up
ip link set dev "$wlan_mitm" up

# Start hostapd
systemctl unmask hostapd

systemctl start hostapd
systemctl enable hostapd
