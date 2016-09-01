#!/bin/bash
if [[ "$1" == "" ]] ; then
	TO_PORT=8080;
else
	TO_PORT="$1";
fi
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports "$TO_PORT"
