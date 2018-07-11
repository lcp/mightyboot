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

# Exit if there is no assigned IP6_PREFIX
if [ -z "$IP6_PREFIX" ]; then
	echo "No IP6 Prefix"
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

# Run dnsmasq

data_dir="/data"
if [ ! -d "$data_dir" ]; then
	echo "Please ensure '$data_dir' folder is available."
	echo 'If you just want to keep your configuration in "data/", add -v "$(pwd)/data:/data" to the docker run command line.'
	exit 1
fi

dnsmasq_conf="$data_dir/dnsmasq.conf"
if [ ! -r "$dnsmasq_conf" ]; then
	echo "Please ensure '$dnsmasq_conf' exists and is readable."
	exit 1
fi

hosts_tmp="$data_dir/hosts.conf.template"
if [ ! -r "$hosts_tmp" ]; then
	echo "Please ensure '$hosts_tmp' exists and is readable."
	exit 1
fi

hosts_conf="$data_dir/hosts.conf"

sed "s,__IP4_PREFIX__,$IP4_PREFIX,g
     s,__IP6_PREFIX__,$IP6_PREFIX,g" \
    $hosts_tmp > $hosts_conf

container_id=$(grep docker /proc/self/cgroup | sort -n | head -n 1 | cut -d: -f3 | cut -d/ -f3)
if perl -e '($id,$name)=@ARGV;$short=substr $id,0,length $name;exit 1 if $name ne $short;exit 0' $container_id $HOSTNAME; then
	echo "You must add the 'docker run' option '--net=host' if you want to provide DHCP service to the host network."
fi

exec /usr/sbin/dnsmasq -d -R -C $dnsmasq_conf -h -H $hosts_conf -i $IFACE
