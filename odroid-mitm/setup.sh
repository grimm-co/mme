#!/bin/sh
# This will run all the scripts to install the software, scripts that need to
# be run on each boot and makes sure that every time the device boots, it is
# routing/intercepting as much traffic as possible.

if [ `whoami` != root ]; then
	sudo $0
	exit $?
fi

# Bring up all the interfaces that are down
for d in `ip a | ./ip_parser.py --down`; do
	ip link set dev "$d" up
done

lan_iface=`ip a | ./ip_parser.py --wired --with-ip`
wlan_iface=`ip a | ./ip_parser.py --wireless --with-ip`
lan_mitm=`ip a | ./ip_parser.py --wired --without-ip`
wlan_mitm=`ip a | ./ip_parser.py --wireless --without-ip`

echo "Installing DHCP server to serve IPs on: $lan_mitm $wlan_mitm"
./install_dhcp.sh "$lan_mitm" "$wlan_mitm"

echo "Installing hostapd so we can serve up an access point on $wlan_mitm"
sed -i "s/interface=.*/interface=$wlan_mitm/g" hostapd.conf
./install_hostapd.sh "$wlan_iface" "$wlan_mitm"

echo "Installing scripts to do masqerading and IP forwarding"
./masquerade.sh "$lan_iface" "$wlan_iface" "$lan_mitm" "$wlan_mitm"
cp masquerade.sh /etc  # and start it in the future on each boot
echo "/etc/masquerade.sh" >> /etc/rc.local
sed -i "s/wlan0=.*/wlan0=$wlan_iface/g" ./reset_wifi_radios.sh
sed -i "s/wlan1=.*/wlan0=$wlan_mitm/g" ./reset_wifi_radios.sh
cat ./reset_wifi_radios.sh >> /etc/rc.local
echo "systemctl restart hostapd" >> /etc/rc.local
echo "systemctl restart isc-dhcp-server" >> /etc/rc.local
./enable_ip_forwarding.sh
systemctl restart isc-dhcp-server
