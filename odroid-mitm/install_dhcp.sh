#!/bin/sh -e
# Assumptions:
# eth0 may be used to connect to a LAN
# eth1 will serve up DHCP
# wlan0 may be used to connect to wifi
# wlan1 will be the AP

eth0="wlan1"  # serve up DHCP addresses on wlan1
ip="192.168.101.1"
network="192.168.101.0"
netmask="255.255.255.0"
cidr="24"
search_domain="example.lan"
nameserver="4.2.2.2"
dhcp_start="192.168.101.10"
dhcp_end="192.168.101.100"

# Make sure IP gets set properly now and in the future
echo "network:"            | sudo tee /etc/netplan/wifi-server.yaml
echo "  version: 2"        | sudo tee -a /etc/netplan/wifi-server.yaml
echo "  ethernets:"        | sudo tee -a /etc/netplan/wifi-server.yaml
echo "    $eth0:"          | sudo tee -a /etc/netplan/wifi-server.yaml
echo "      addresses:"    | sudo tee -a /etc/netplan/wifi-server.yaml
echo "        - $ip/$cidr" | sudo tee -a /etc/netplan/wifi-server.yaml
sudo netplan generate
sudo netplan apply

sudo apt-get install -y isc-dhcp-server # Ubuntu

echo "subnet $network netmask $netmask {"  | sudo tee /etc/dhcp/dhcpd.conf
echo "  option routers $ip;"               | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option subnet-mask $netmask;"      | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option domain-search   \"$search_domain\";" | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers $nameserver;" | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  range $dhcp_start $dhcp_end;"      | sudo tee -a /etc/dhcp/dhcpd.conf
echo "}"                                   | sudo tee -a /etc/dhcp/dhcpd.conf

# Now we set up another DHCP server on eth1
eth0="eth1"  # serve up DHCP addresses on eth1
ip="192.168.102.1"
network="192.168.102.0"
netmask="255.255.255.0"
cidr="24"
search_domain="example.lan"
nameserver="4.2.2.2"
dhcp_start="192.168.102.10"
dhcp_end="192.168.102.100"

# Make sure IP gets set properly now and in the future
echo "network:"            | sudo tee /etc/netplan/lan-server.yaml
echo "  version: 2"        | sudo tee -a /etc/netplan/lan-server.yaml
echo "  ethernets:"        | sudo tee -a /etc/netplan/lan-server.yaml
echo "    $eth0:"          | sudo tee -a /etc/netplan/lan-server.yaml
echo "      addresses:"    | sudo tee -a /etc/netplan/lan-server.yaml
echo "        - $ip/$cidr" | sudo tee -a /etc/netplan/lan-server.yaml
sudo netplan generate
sudo netplan apply

echo "subnet $network netmask $netmask {"  | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option routers $ip;"               | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option subnet-mask $netmask;"      | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option domain-search   \"$search_domain\";" | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  option domain-name-servers $nameserver;" | sudo tee -a /etc/dhcp/dhcpd.conf
echo "  range $dhcp_start $dhcp_end;"      | sudo tee -a /etc/dhcp/dhcpd.conf
echo "}"                                   | sudo tee -a /etc/dhcp/dhcpd.conf

sudo systemctl start isc-dhcp-server
sudo systemctl status isc-dhcp-server
sudo systemctl enable isc-dhcp-server
