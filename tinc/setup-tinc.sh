#!/bin/sh

# Based on http://xmodulo.com/how-to-install-and-configure-tinc-vpn.html

export PS4="\[\033[32;1m++++\[\033[0m "
set -ex

TINCNAME=$1
TINCIP=$2

VPNNAME=scaleway
TINCPATH=/etc/tinc/$VPNNAME
MYIP=$(ip addr show eth0 | grep -o 'inet [^/]*' | cut -d' ' -f 2)

dpkg -l tinc > /dev/null || apt-get install tinc

mkdir -p ${TINCPATH}/hosts

if [ ! -f ${TINCPATH}/tinc.conf ]; then
	echo "Name = ${TINCNAME}" > ${TINCPATH}/tinc.conf
	echo "AddressFamily = ipv4" >> ${TINCPATH}/tinc.conf
	echo "Interface = tun0" >> ${TINCPATH}/tinc.conf
fi

if [ ! -f ${TINCPATH}/hosts/${TINCNAME} ]; then
	echo "Address = $MYIP" > ${TINCPATH}/hosts/${TINCNAME}
	echo "Subnet = 0.0.0.0/0" >> ${TINCPATH}/hosts/${TINCNAME}
	tincd -n $VPNNAME -K4096
fi

echo "#!/bin/sh" > ${TINCPATH}/tinc-up
echo 'ifconfig $INTERFACE '${TINCIP}' netmask 255.255.255.0' >> ${TINCPATH}/tinc-up

echo "#!/bin/sh" > ${TINCPATH}/tinc-down
echo 'ifconfig \$INTERFACE down' >> ${TINCPATH}/tinc-down
chmod +x ${TINCPATH}/tinc-{up,down}

modprobe tun
tincd -n $VPNNAME -k HUP || tincd -n $VPNNAME

# And set up forwarding/nat
echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT

