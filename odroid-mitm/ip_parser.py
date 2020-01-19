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

def get_ip(line, needle="inet6"):
    parts = line.split(needle)
    if len(parts) > 1:
        return parts[1].strip().split("/")[0]

if __name__ == "__main__":
    p = ArgumentParser("Swiss army knife of parsing the output of `ip a`")
    p.add_argument("--without-ips", help="only without ips", action="store_true")
    p.add_argument("--with-ips", help="only with ips", action="store_true")
    p.add_argument("--wireless", help="only wireless interfaces", action="store_true")
    p.add_argument("--wired", help="only wired interfaces", action="store_true")
    p.add_argument("--only", help="Interface name to get info on")
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
            line = input()
    except EOFError:
        pass
    ifaces.append(iface)

    # Now we output the requested data
    if args.wired:
        ifaces = [x for x in ifaces if x["type"] == "wired"]
    if args.wireless:
        ifaces = [x for x in ifaces if x["type"] == "wireless"]
    if args.with_ips:
        ifaces = [x for x in ifaces if "ip" in x or "ip6" in x]
    if args.without_ips:
        ifaces = [x for x in ifaces if "ip" not in x and "ip6" not in x]
    if args.only:
        ifaces = [x for x in ifaces if x["name"] == args.only]

    # Print what's left
    print("\n".join([x["name"] for x in ifaces]))
    #pprint(ifaces)
