#!/bin/sh -e
# Arguments are network interface names
lan_mitm="$1"  # Serve up DHCP here
wlan_mitm="$2" # Serve up DHCP here

nameserver="4.2.2.2"
search_domain="example.lan"

apt-get install -y isc-dhcp-server # Ubuntu
# It'd be nice to add the following in the [Service] section
# of /lib/systemd/system/isc-dhcp-server.service...
#Restart=on-failure
#RestartSec=5s


if [ -n "$wlan_mitm" ]; then
  ip="192.168.101.1"
  network="192.168.101.0"
  netmask="255.255.255.0"
  cidr="24"
  dhcp_start="192.168.101.10"
  dhcp_end="192.168.101.100"

  # Make sure IP gets set properly now and in the future
  echo "network:"            | tee /etc/netplan/wifi-server.yaml
  echo "  version: 2"        | tee -a /etc/netplan/wifi-server.yaml
  echo "  ethernets:"        | tee -a /etc/netplan/wifi-server.yaml
  echo "    $wlan_mitm:"     | tee -a /etc/netplan/wifi-server.yaml
  echo "      addresses:"    | tee -a /etc/netplan/wifi-server.yaml
  echo "        - $ip/$cidr" | tee -a /etc/netplan/wifi-server.yaml
  netplan generate
  netplan apply

  echo "subnet $network netmask $netmask {"  | tee /etc/dhcp/dhcpd.conf
  echo "  option routers $ip;"               | tee -a /etc/dhcp/dhcpd.conf
  echo "  option subnet-mask $netmask;"      | tee -a /etc/dhcp/dhcpd.conf
  echo "  option domain-search   \"$search_domain\";" | tee -a /etc/dhcp/dhcpd.conf
  echo "  option domain-name-servers $nameserver;" | tee -a /etc/dhcp/dhcpd.conf
  echo "  range $dhcp_start $dhcp_end;"      | tee -a /etc/dhcp/dhcpd.conf
  echo "}"                                   | tee -a /etc/dhcp/dhcpd.conf
fi

if [ -n "$lan_mitm" ]; then
  ip="192.168.102.1"
  network="192.168.102.0"
  netmask="255.255.255.0"
  cidr="24"
  dhcp_start="192.168.102.10"
  dhcp_end="192.168.102.100"

  # Make sure IP gets set properly now and in the future
  echo "network:"            | tee /etc/netplan/lan-server.yaml
  echo "  version: 2"        | tee -a /etc/netplan/lan-server.yaml
  echo "  ethernets:"        | tee -a /etc/netplan/lan-server.yaml
  echo "    $lan_mitm:"      | tee -a /etc/netplan/lan-server.yaml
  echo "      addresses:"    | tee -a /etc/netplan/lan-server.yaml
  echo "        - $ip/$cidr" | tee -a /etc/netplan/lan-server.yaml
  netplan generate
  netplan apply

  echo "subnet $network netmask $netmask {"  | tee -a /etc/dhcp/dhcpd.conf
  echo "  option routers $ip;"               | tee -a /etc/dhcp/dhcpd.conf
  echo "  option subnet-mask $netmask;"      | tee -a /etc/dhcp/dhcpd.conf
  echo "  option domain-search   \"$search_domain\";" | tee -a /etc/dhcp/dhcpd.conf
  echo "  option domain-name-servers $nameserver;" | tee -a /etc/dhcp/dhcpd.conf
  echo "  range $dhcp_start $dhcp_end;"      | tee -a /etc/dhcp/dhcpd.conf
  echo "}"                                   | tee -a /etc/dhcp/dhcpd.conf
fi

systemctl start isc-dhcp-server
systemctl enable isc-dhcp-server
