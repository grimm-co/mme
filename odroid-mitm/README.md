# ODroid MitM Box
These scripts and instructions are for an ODroid board with a number of USB
networking devices.  The hardware is described in hardware.txt.  The purpose
of this setup is to intercept network traffic so you can see what your mobile
apps (or laptop apps) are doing.  The cost of this setup is approximately
$350, but it could be done fore less without the screen, keyboard, mouse or
USB hub

# Troubleshooting
The hardware on the odroid seems to be extremely flakey.  Things just stop
working... frequently.  We haven't found any obvious source of these problems,
but we did figue out how to reset it when it breaks.

## Wired interface broken
This mean it's not serving up DHCP, or SSH isn't responding.

- Reboot the hardware
- Restart networking
-- sudo service networking restart # or
-- sudo systemctl restart networking
- Re-apply netplan
-- sudo netplan generate && sudo netplan apply
- Restart DHCP server
-- sudo systemctl restart isc-dhcp-server



