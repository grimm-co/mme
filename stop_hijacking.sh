#!/bin/bash
# This assumes that the first pre-routing rule is most likely the one you want
# to remove, as you are probably only using one rule.  If you want to delete a
# specific rule, use show_hijacking.sh to get the rule number first.
if [[ "$1" == "" ]] ; then
	RULE_NUMBER=1;
else
	RULE_NUMBER="$1";
fi
sudo iptables -t nat -D PREROUTING "$RULE_NUMBER"
