#!/bin/sh
# This will run all the scripts to install the software, scripts that need to
# be run on each boot and makes sure that every time the device boots, it is
# routing/intercepting as much traffic as possible.

# Install DHCP server
./install_dhcp.sh

# Install scripts to do masqerading and IP forwarding
sudo cp masquerade.sh /etc/rc.local
./enable_ip_forwarding.sh

