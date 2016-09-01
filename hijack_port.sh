#!/bin/bash
if [[ "$1" == "" ]] ; then
	echo ""
	echo "Usage: $0 <port> [dest_port]"
	echo ""
	echo "port - TCP port to hijack"
	echo "dest_port - local port where traffic should be redirected"
	echo ""
	exit 1
fi
FROM_PORT="$1";
if [[ "$2" == "" ]] ; then
	TO_PORT=8080;
else
	TO_PORT="$2";
fi
sudo iptables -t nat -A PREROUTING -p tcp --dport "$FROM_PORT" -j REDIRECT --to-ports "$TO_PORT"
