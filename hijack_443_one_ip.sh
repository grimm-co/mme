#!/bin/bash
if [[ "$1" == "" ]] ; then
	echo ""
	echo "Usage: $0 <IP> [dest_port]"
	echo ""
	exit 1
fi
if [[ "$2" == "" ]] ; then
	TO_PORT=8080;
else
	TO_PORT="$2";
fi
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -d "$1" -j REDIRECT --to-ports "$TO_PORT"
