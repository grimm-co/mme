#!/bin/sh
# Install and configure hostapd

# Install hostapd
sudo apt-get install -y hostapd

# Configure hostapd
echo "DAEMON_CONF=/etc/hostapd/hostapd.conf" | sudo tee -a /etc/default/hostapd
sudo cp hostapd.conf /etc/hostapd/

# hostapd won't be able to configure driver mode unless this is done:
sudo nmcli radio wifi off
sudo rfkill unblock wlan
sudo ifconfig wlan0 up
sudo ifconfig wlan1 up

# Start hostapd
sudo systemctl unmask hostapd

sudo systemctl start hostapd
