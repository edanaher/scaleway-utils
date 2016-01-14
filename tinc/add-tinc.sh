#!/bin/sh

# Based on http://xmodulo.com/how-to-install-and-configure-tinc-vpn.html

export PS4="\[\033[32;1m++\[\033[0m "
set -ex

HOST=$1
TINCIP=$2
TINCNAME=${3:-$1}
PORT=$4

VPNNAME=scaleway
TINCPATH=/etc/tinc/$VPNNAME

MYTINCIP=$(ip addr show tun0 | grep -o 'inet [^/]*' | cut -d' ' -f 2)
MYIP=$(ip addr show eth0 | grep -o 'inet [^/]*' | cut -d' ' -f 2)
MYNAME=$(cat $TINCPATH/tinc.conf | awk '/Name/ { print $3}')

rsync -Pavvzessh /var/cache/apt/archives/{tinc_*.deb,liblzo2-*.deb} root@${HOST}:/tmp

ssh -l root $HOST <<EOF
export PS4="\[\033[32;1m++++\[\033[0m "
set -ex
dpkg -l tinc > /dev/null || dpkg -i /tmp/liblzo2-*.deb /tmp/tinc_*.deb

mkdir -p ${TINCPATH}/hosts

if [ ! -f ${TINCPATH}/tinc.conf ]; then
	echo "Name = ${TINCNAME}" > ${TINCPATH}/tinc.conf
	echo "AddressFamily = ipv4" >> ${TINCPATH}/tinc.conf
	echo "Interface = tun0" >> ${TINCPATH}/tinc.conf
	echo "ConnectTo = $MYNAME" >> ${TINCPATH}/tinc.conf
fi

if [ ! -f ${TINCPATH}/hosts/${TINCNAME} ]; then
	echo "Subnet = ${TINCIP}/32" > ${TINCPATH}/hosts/${TINCNAME}
	tincd -n $VPNNAME -K4096
fi

echo "#!/bin/sh" > ${TINCPATH}/tinc-up
echo 'ifconfig \$INTERFACE '$TINCIP' netmask 255.255.255.0' >> ${TINCPATH}/tinc-up

echo "#!/bin/sh" > ${TINCPATH}/tinc-down
echo 'ifconfig \$INTERFACE down' >> ${TINCPATH}/tinc-down
chmod +x ${TINCPATH}/tinc-{up,down}

modprobe tun
EOF

rsync -Pavvzessh ${TINCPATH}/hosts/$MYNAME $HOST:${TINCPATH}/hosts/
rsync -Pavvzessh $HOST:${TINCPATH}/hosts/${TINCNAME} ${TINCPATH}/hosts/
tincd -n $VPNNAME -k HUP || tincd -n $VPNNAME

ssh -l root $HOST <<EOF
tincd -n $VPNNAME -k HUP || tincd -n $VPNNAME
GATEWAY=\$(route -n | grep '^0.0.0.0 .*eth0' | awk '{print \$2}')
route add -host $MYIP gw \$GATEWAY
route add default gw $MYTINCIP
route del default gw \$GATEWAY
EOF
