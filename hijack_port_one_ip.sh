#!/bin/bash
if [[ "$1" == "" || "$2" == "" ]] ; then
	echo ""
	echo "Usage: $0 <port> <IP> [dest_port]"
	echo ""
	echo "port - TCP port to hijack"
	echo "IP - the destination IP to hijack"
	echo "dest_port - local port where traffic should be redirected (default: 8080)"
	echo ""
	exit 1
fi
FROM_PORT="$1";
FROM_IP="$2";
if [[ "$3" == "" ]] ; then
	TO_PORT=8080;
else
	TO_PORT="$3";
fi
sudo iptables -t nat -A PREROUTING -p tcp --dport "$FROM_PORT" -d "$FROM_IP" -j REDIRECT --to-ports "$TO_PORT"
