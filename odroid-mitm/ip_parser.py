#!/usr/bin/env python3
from argparse import ArgumentParser
from pprint import pprint

def get_type(line):
    """
    Returns either a string, indicating whether this is a wired, wireless,
    or loopback interface, or None if this can not be determinted.
    :param line: line of output from: ip a
    """
    if "fq_codel" in line:
        return "wired"
    if "mq" in line:
        return "wireless"
    if "noqueue" in line:
        return "loopback"
    return None

def is_up(line):
    """
    Returns True if the interface is up, False if it's down, and None if there
    is not enuough information present to determine whether it's up or down
    """
    if "UP" in line:
        return True
    if "DOWN" in line:
        return False
    return None

def get_ip(line, needle="inet6"):
    parts = line.split(needle)
    if len(parts) > 1:
        return parts[1].strip().split("/")[0]

if __name__ == "__main__":
    p = ArgumentParser(description="Swiss army knife of parsing the output of `ip a` (pipe `ip a` to this script)")
    p.add_argument("--without-ips", help="only without ips", action="store_true")
    p.add_argument("--with-ips", help="only with ips", action="store_true")
    p.add_argument("--wireless", help="only wireless interfaces", action="store_true")
    p.add_argument("--wired", help="only wired interfaces", action="store_true")
    p.add_argument("--up", help="only interfaces which are up", action="store_true")
    p.add_argument("--down", help="only interfaces which are down", action="store_true")
    p.add_argument("--only", help="Interface name to get info on")
    p.add_argument("--show-ip", help="Outputs the IP addresses in addition to the interface name", action="store_true")
    args = p.parse_args()
    
    ifaces = []
    iface = None
    try:
        line = input()
        while line:
            #print(line)
            if line[0] != ' ':
                # New thing
                if iface != None:
                    ifaces.append(iface)
                iface = {}
                iface["name"] = line.split(':')[1].strip()
            ip = get_ip(line, "inet6")
            if ip:
                iface["ip6"] = ip
            else:
                # If this line doesn't have IPv6 info, look for IPv4
                ip = get_ip(line, "inet")
                if ip:
                    iface["ip"] = ip
            card_type = get_type(line)
            if card_type:
                iface["type"] = card_type
            up = is_up(line)
            if up != None:
                iface["up"] = up
            line = input()
    except EOFError:
        pass
    ifaces.append(iface)

    # Now we output the requested data
    if args.wired:
        ifaces = [x for x in ifaces if "type" in x and x["type"] == "wired"]
    if args.wireless:
        ifaces = [x for x in ifaces if "type" in x and x["type"] == "wireless"]
    if args.with_ips:
        ifaces = [x for x in ifaces if "ip" in x or "ip6" in x]
    if args.without_ips:
        ifaces = [x for x in ifaces if "ip" not in x and "ip6" not in x]
    if args.up:
        ifaces = [x for x in ifaces if "up" in x and x["up"]]
    if args.down:
        ifaces = [x for x in ifaces if "up" in x and not x["up"]]
    if args.only:
        ifaces = [x for x in ifaces if x["name"] == args.only]

    # Print what's left
    if args.show_ip:
        for x in ifaces:
            ip = x["ip"] if "ip" in x else ""
            print(x["name"] + " " + ip)
    else:
        print("\n".join([x["name"] for x in ifaces]))
    #pprint(ifaces)
