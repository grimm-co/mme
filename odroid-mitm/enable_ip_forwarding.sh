#!/bin/bash
# This enables ip forwarding both now and on subsequent reboots
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
