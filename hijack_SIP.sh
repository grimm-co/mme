#!/bin/bash

iptables -t nat -A PREROUTING -p tcp --dport 5061 -j REDIRECT --to-ports 8081

