#!/bin/bash

set -e

# Exit if there is no assigned interface
if [ -z "$IFACE" ]; then
	echo "No Assigned Interace"
	exit
fi

# Exit if there is no assigned IP6_PREFIX
if [ -z "$IP6_PREFIX" ]; then
	echo "No IP6 Prefix"
	exit
fi

# Exit if there is no assigned PXE URI
if [ -z "$PXE_URI" ]; then
	echo "No PXE URI"
	exit
fi

# Exit if there is no assigned HTTPBoot6 URI
if [ -z "$HTTPBOOT6_URI" ]; then
	echo "No HTTPBoot6 URI"
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

dhcpd6_tmp="$data_dir/dhcpd6.conf.template"
if [ ! -r "$dhcpd6_tmp" ]; then
	echo "Please ensure '$dhcpd6_tmp' exists and is readable."
	exit 1
fi

dhcpd6_conf="$data_dir/dhcpd6.conf"

sed "s,__IP6_PREFIX__,$IP6_PREFIX,g
     s,__PXE_URI__,$PXE_URI,g
     s,__HTTPBOOT6_URI__,$HTTPBOOT6_URI,g" \
    $dhcpd6_tmp > $dhcpd6_conf

[ -e "$data_dir/dhcpd6.leases" ] || touch "$data_dir/dhcpd6.leases"

container_id=$(grep docker /proc/self/cgroup | sort -n | head -n 1 | cut -d: -f3 | cut -d/ -f3)
if perl -e '($id,$name)=@ARGV;$short=substr $id,0,length $name;exit 1 if $name ne $short;exit 0' $container_id $HOSTNAME; then
	echo "You must add the 'docker run' option '--net=host' if you want to provide DHCP service to the host network."
fi

exec /usr/sbin/dhcpd -6 -f -d --no-pid -cf "$data_dir/dhcpd6.conf" -lf "$data_dir/dhcpd6.leases" $IFACE
