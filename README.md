l2tp-client
===
[![](https://images.microbadger.com/badges/image/ubergarm/l2tp-ipsec-vpn-client.svg)](https://microbadger.com/images/ubergarm/l2tp-ipsec-vpn-client) [![](https://images.microbadger.com/badges/version/ubergarm/l2tp-ipsec-vpn-client.svg)](https://microbadger.com/images/ubergarm/l2tp-ipsec-vpn-client) [![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/ubergarm/l2tp-ipsec-vpn-client/blob/master/LICENSE)

A tiny Alpine based docker image to quickly setup an L2TP over IPsec (or not) VPN client.

forked from https://github.com/wolasss/l2tp-ipsec-vpn-client which fored from https://github.com/ubergarm/l2tp-ipsec-vpn-client

# Jimorsm fork changes

1. automatically chose whether use ipsec or not according to the variable VPN_PSK
2. add custom route if CUSTOM_ROUTE is setted

ex. `export CUSTOM_ROUTE='192.168.42.0/24,10.10.0.0/16'`

3. health check, if ppp interface is not found or connection not available (sometimes it is not established or connection is lost) it kills this container. (Allowing kubernetes or docker daemon to restart it and hence re-establish connection to the vpn)



# Usage

Main parameters which needed

1. VPN Server Address
2. Pre Shared Key (Optional)
3. Username
4. Password

## Run
- Setup environment variables for your credentials and config:
```
    export VPN_SERVER_IPV4='1.2.3.4'
    export VPN_PSK='my pre shared key'
    export VPN_USERNAME='myuser@myhost.com'
    export VPN_PASSWORD='mypass'
```
- Run it (you can daemonize of course after debugging):
```
    docker run --rm -it --privileged --net=host \
               -e VPN_SERVER_IPV4 \
               -e VPN_PSK \
               -e VPN_USERNAME \
               -e VPN_PASSWORD \
                  jimorsm/l2tp-client
```
- non privileged 
```
docker run --rm -it --cap-add=NET_ADMIN --device=/dev/ppp \
               -e VPN_SERVER_IPV4 \
               -e VPN_PSK \
               -e VPN_USERNAME \
               -e VPN_PASSWORD \
                  jimorsm/l2tp-client
```
## More parameters

- CUSTOM_ROUTE
    - By default set ppp0 device as gateway, pass environment variable CUSTOM_ROUTE to avoid it and using custom routes
    - Format: CIDRs split by comma
    - example: CUSTOM_ROUTE='10.7.0.0/16,192.168.3.0/24'

- USEPEERDNS
    - set true to enable usepeerdns

- DEBUG
    - set true to enable debug 



## Debugging
On your VPN client localhost machine you may need to `sudo modprobe af_key`
if you're getting this error when starting:
```
pluto[17]: No XFRM/NETKEY kernel interface detected
pluto[17]: seccomp security for crypto helper not supported
```


## References
* [royhills/ike-scan](https://github.com/royhills/ike-scan)
* [libreswan reference config](https://libreswan.org/wiki/VPN_server_for_remote_clients_using_IKEv1_with_L2TP)
* [Useful Config Example](https://lists.libreswan.org/pipermail/swan/2016/001921.html)
* [libreswan and Cisco ASA 5500](https://sgros.blogspot.com/2013/08/getting-libreswan-connect-to-cisco-asa.html)
* [NetDev0x12 IPSEC and IKE Tutorial](https://youtu.be/7oldcYljp4U?t=1586)
