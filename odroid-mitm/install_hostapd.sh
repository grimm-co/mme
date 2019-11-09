#!/bin/sh
# Install and configure hostapd

# Install hostapd
sudo apt-get install -y hostapd

# Configure hostapd
echo "DAEMON_CONF=/etc/hostapd/hostapd.conf" | sudo tee -a /etc/default/hostapd
sudo cp hostapd.conf /etc/hostapd/

# Start hostapd
sudo systemctl unmask hostapd

sudo systemctl start hostapd
