#!/bin/bash

set -eo pipefail

# template out all the config files using env vars
sed -i "s/right=.*/right=$VPN_SERVER_IPV4/" /etc/ipsec.conf
echo ": PSK $VPN_PSK" >/etc/ipsec.secrets
sed -i "s/lns = .*/lns = $VPN_SERVER_IPV4/" /etc/xl2tpd/xl2tpd.conf
sed -i "/^name/cname $VPN_USERNAME" /etc/ppp/options.l2tpd.client
sed -i "/^password/cpassword $VPN_PASSWORD" /etc/ppp/options.l2tpd.client

# startup ipsec tunnel
if [ -n "$VPN_PSK" ]; then
	ipsec initnss
	sleep 1
	ipsec pluto --stderrlog --config /etc/ipsec.conf
	sleep 5
	ipsec auto --up L2TP-PSK

	if ! (ipsec status | grep 'ISAKMP SA established' && ipsec status | grep 'IPsec SA established'); then
		echo "IPSEC connection couldn't be established. "
		exit 1
	fi
fi

# if USERPEERDNS not setted, disable usepeerdns
if [ -z "$USEPEERDNS" ]; then
	sed -i "/usepeerdns/d" /etc/ppp/options.l2tpd.client
fi

# if COUSTOM_ROUTE setted, disable default route in ppp options
# COUSTOM_ROUTE='192.168.42.0/24,192.168.43.0/24'
if [ -n "$CUSTOM_ROUTE" ]; then
	sed -i "/defaultroute/d" /etc/ppp/options.l2tpd.client
	(

		# background task for checking custom route
		while true; do
			sleep 3
			# determine ppp device
			ppp_dev=$(ls /var/run | grep ppp[0-9]\.pid | awk -F . '{print $1}')
			# if dev ppp ready add route
			if [[ -n $ppp_dev ]]; then
				CIDRs=${CUSTOM_ROUTE//,/ }
				gateway=$(ip a | grep "$ppp_dev"$ | awk '{print $4}' | awk -F / '{print $1}')
				# check if route exits otherwise add route
				for CIDR in ${CIDRs[@]}; do
					if ! (ip route | grep "$CIDR" >/dev/null); then
						ip route add "$CIDR" via "$gateway"
					fi
				done
				break
			fi
		done
	) &
fi

# if DEBUG not setted, disable DEBUG
if [ -z "$DEBUG" ]; then
	sed -i "/debug/d" /etc/xl2tpd/xl2tpd.conf
	sed -i "/debug/d" /etc/ppp/options.l2tpd.client
fi

if [ "${HEALTH_CHECK:-false}" == "true" ]; then
	# health-check
	/health-check.sh &
fi

# startup xl2tpd ppp daemon
exec /usr/sbin/xl2tpd -p /var/run/xl2tpd.pid -c /etc/xl2tpd/xl2tpd.conf -C /var/run/xl2tpd/l2tp-control -D
