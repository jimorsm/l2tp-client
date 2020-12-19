#!/bin/sh

# Delay in secconds
DELAY=45

if [ $VPN_LOCAL_GATEWAY ]
    then
        while [ "true" ]; do
            if ! (ifconfig | grep "$VPN_LOCAL_GATEWAY" 1> /dev/null)
                then
                    pkill xl2tpd
            fi

            sleep $DELAY
        done
fi
