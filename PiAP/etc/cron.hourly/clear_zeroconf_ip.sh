#! /bin/bash

for IFACE in lan0 dmz0 br0 eth0 eth1 eth2 eth3 eth4 wlan0 wlan1 wlan2 wlan3 wlan4 vnet0 ; do
        if [[ ( -n $(echo -n $(ip addr show ${IFACE:-eth0} 2>/dev/null | fgrep 169.254 | grepCIDR | grepCIDR -m1) ) ) ]] ; then
                ip addr del $(ip addr show ${IFACE:-eth0} 2>/dev/null | fgrep 169.254 | grepCIDR | grepCIDR -m1) dev ${IFACE:-eth0} 2>/dev/null || true
        fi
        if [[ ( -n $(echo -n $(ip route show default 2>/dev/null | fgrep default | fgrep ${IFACE}) ) ) && ( -z $(echo -n $(ip route show ${IFACE:-eth0} 2>/dev/null | fgrep default | fgrep ${IFACE:-eth0} | fgrep src) ) ) ]] ; then
                ip route change $(echo -n $(ip route show default 2>/dev/null | fgrep default | fgrep ${IFACE})) src $(echo -n $(ip addr show ${IFACE:-eth0} 2>/dev/null | fgrep inet | tr -s ' ' ' ' | cut -d \   -f 3 | cut -d / -f 1)) 2>/dev/null || true
        fi
done

exit 0 ;
