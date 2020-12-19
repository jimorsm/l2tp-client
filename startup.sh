#!/bin/sh

# template out all the config files using env vars
sed -i 's/right=.*/right='$VPN_SERVER_IPV4'/' /etc/ipsec.conf
echo ': PSK "'$VPN_PSK'"' > /etc/ipsec.secrets
sed -i 's/lns = .*/lns = '$VPN_SERVER_IPV4'/' /etc/xl2tpd/xl2tpd.conf
sed -i 's/name .*/name '$VPN_USERNAME'/' /etc/ppp/options.l2tpd.client
sed -i 's/password .*/password '$VPN_PASSWORD'/' /etc/ppp/options.l2tpd.client

# startup ipsec tunnel
ipsec initnss
sleep 1
ipsec pluto --stderrlog --config /etc/ipsec.conf
sleep 5
ipsec auto --up L2TP-PSK

if ! (ipsec status | grep 'ISAKMP SA established' && ipsec status | grep 'IPsec SA established')
    then
        echo "IPSEC connection couldn't be established. "
        exit 1
fi

(
    sleep 25 && echo "c myVPN" > /var/run/xl2tpd/l2tp-control && sleep 15 && (/monitor-vpn.sh start &) && sleep 2 && eval "$VPN_CMD_ON_CONNECTED"
) &

# startup xl2tpd ppp daemon then send it a connect command
exec /usr/sbin/xl2tpd -p /var/run/xl2tpd.pid -c /etc/xl2tpd/xl2tpd.conf -C /var/run/xl2tpd/l2tp-control -D
