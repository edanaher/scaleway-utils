Tinc setup for Scaleway private-IP only nat
===========================================

Note that these scripts are raw and poorly tested, but are working for me.

Basic usage:

Run the following commands as root on your "gateway" box with a public IP, (ideally with passwordless ssh to the other instances, but it should work fine with passwords as well):

```bash
setup-tinc.sh gateway 192.168.1.1
add-tinc.sh [internal-host-ip] 192.168.1.2 [tinc-name-of-host]
add-tinc.sh [internal-host-ip] 192.168.1.3 [tinc-name-of-host]
etc...
```

Explanation
----------

In a perfect world, Scaleway would properly NAT internal-only hosts so that they can talk to the outside world.  Unfortunately, that's not the case.

In a less perfect world, we could set up routing through a host with a public IP and nat ourselves.  Unfortunately, hosts tend to be on different /23 subnets, so need to go through the default gateways to talk to each other.  And AFAICT, Linux (very reasonably) won't let you route through a host not on the local network.

So my solution is to set up a dumb VPN using tinc, and then set up routing so that we can hit the other end of the VPN via the default gateway, and then use the other end of the VPN as the gateway.  Ugly and probably slower than it should be, but easy and convenient.

For more details, read the scripts; there pretty barebones and fragile, but work for me.

