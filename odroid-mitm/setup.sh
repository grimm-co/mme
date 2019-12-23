#!/bin/sh
# This will run all the scripts to install the software, scripts that need to
# be run on each boot and makes sure that every time the device boots, it is
# routing/intercepting as much traffic as possible.

if [ `whoami` != root ]; then
	sudo $0
	exit $?
fi

# Install DHCP server
./install_dhcp.sh

# Install hostapd so we can serve up an access point
./install_hostapd.sh

# Install scripts to do masqerading and IP forwarding
./masquerade.sh   # start masquerading now
sudo cp masquerade.sh /etc/rc.local  # and in the future
cat ./reset_wifi_radios.sh >> /etc/rc.local
echo "systemctl restart hostapd" >> /etc/rc.local
echo "systemctl restart isc-dhcp-server" >> /etc/rc.local
./enable_ip_forwarding.sh
