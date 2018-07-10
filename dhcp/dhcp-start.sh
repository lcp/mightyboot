#!/bin/bash

set -e

# Exit if there is no assigned interface
if [ -z "$IFACE" ]; then
	echo "No Assigned Interace"
	exit
fi

# Exit if there is no assigned IP4_PREFIX
if [ -z "$IP4_PREFIX" ]; then
	echo "No IP4 Prefix"
	exit
fi

# Exit if there is no assigned PXE URI
if [ -z "$PXE_URI" ]; then
	echo "No PXE URI"
	exit
fi

# Exit if there is no assigned HTTPBoot URI
if [ -z "$HTTPBOOT_URI" ]; then
	echo "No HTTPBoot URI"
	exit
fi

# loop until interface is found, or we give up
NEXT_WAIT_TIME=1
until [ -e "/sys/class/net/$IFACE" ] || [ $NEXT_WAIT_TIME -eq 4 ]; do
	sleep $(( NEXT_WAIT_TIME++ ))
	echo "Waiting for interface '$IFACE' to become available... ${NEXT_WAIT_TIME}"
done
if [ -e "/sys/class/net/$IFACE" ]; then
	IFACE="$IFACE"
fi

# Run dhcpd

data_dir="/data"
if [ ! -d "$data_dir" ]; then
	echo "Please ensure '$data_dir' folder is available."
	echo 'If you just want to keep your configuration in "data/", add -v "$(pwd)/data:/data" to the docker run command line.'
	exit 1
fi

dhcpd_tmp="$data_dir/dhcpd.conf.template"
if [ ! -r "$dhcpd_tmp" ]; then
	echo "Please ensure '$dhcpd_tmp' exists and is readable."
	exit 1
fi

dhcpd_conf="$data_dir/dhcpd.conf"

sed "s,__IP4_PREFIX__,$IP4_PREFIX,g
     s,__PXE_URI__,$PXE_URI,g
     s,__HTTPBOOT_URI__,$HTTPBOOT_URI,g" \
    $dhcpd_tmp > $dhcpd_conf

[ -e "$data_dir/dhcpd.leases" ] || touch "$data_dir/dhcpd.leases"

container_id=$(grep docker /proc/self/cgroup | sort -n | head -n 1 | cut -d: -f3 | cut -d/ -f3)
if perl -e '($id,$name)=@ARGV;$short=substr $id,0,length $name;exit 1 if $name ne $short;exit 0' $container_id $HOSTNAME; then
	echo "You must add the 'docker run' option '--net=host' if you want to provide DHCP service to the host network."
fi

exec /usr/sbin/dhcpd -4 -f -d --no-pid -cf "$data_dir/dhcpd.conf" -lf "$data_dir/dhcpd.leases" $IFACE
