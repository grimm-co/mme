#!/bin/bash
sudo iptables -t nat -L --line-numbers $@
