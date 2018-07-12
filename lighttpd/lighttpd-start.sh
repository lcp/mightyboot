#!/bin/bash

set -e

# Exit if there is no assigned interface
if [ -z "$IFACE" ]; then
	echo "No Assigned Interace"
	exit
fi

conf_dir="/conf"
if [ ! -d "$conf_dir" ]; then
	echo "Please ensure '$conf_dir' folder is available."
	echo 'If you just want to keep your configuration in "conf/", add -v "$(pwd)/conf:/conf" to the docker run command line.'
	exit 1
fi

lighttpd_conf="$conf_dir/lighttpd.conf"
if [ ! -r "$lighttpd_conf" ]; then
	echo "Please ensure '$lighttpd_conf' exists and is readable."
	echo "Run the container with arguments 'man lighttpd.conf' if you need help with creating the configuration."
	exit 1
fi

cp $lighttpd_conf /etc/lighttpd/lighttpd.conf
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
