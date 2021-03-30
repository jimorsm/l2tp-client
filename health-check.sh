#!/bin/bash

# Delay in secconds
DELAY=45

while true; do
    if (ip a | grep ppp >/dev/null); then
        if ! (ping -c 3 "$(ip a | grep ppp | grep inet | grep -E "\d{1,3}(\.\d{1,3}){1,3}" -o | tail -1)" >/dev/null); then
            pkill xl2tpd
        fi
    fi

    sleep $DELAY
done
