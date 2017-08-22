#!/bin/bash

iptables -t nat -A PREROUTING -p tcp --dport 5223 -j REDIRECT --to-ports 8082

