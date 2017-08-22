#!/bin/bash
# Will need to create /etc/pf.anchors/forwarding
# Will need to modify /etc/pf.conf
# See https://www.appsecconsulting.com/blog/running-stubborn-devices-through-burp-suite-via-osx-mountain-lion-and-above for more details

sudo pfctl -ef /etc/pf.conf
