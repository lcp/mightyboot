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

if [ "$HTTPS" == "TRUE" ]; then
	lighttpd_conf="$conf_dir/lighttpd-ssl.conf"

	if [ -z "$SERVER_KEY" ]; then
		echo "No Assigned Server Key"
		exit 1
	fi
	server_key=$conf_dir/$SERVER_KEY
	if [ ! -r "$server_key" ]; then
		echo "Please ensure '$server_key' exists and is readable"
		exit 1
	fi
	cp $server_key /etc/ssl/private/
else
	lighttpd_conf="$conf_dir/lighttpd.conf"
fi
if [ ! -r "$lighttpd_conf" ]; then
	echo "Please ensure '$lighttpd_conf' exists and is readable."
	echo "Run the container with arguments 'man lighttpd.conf' if you need help with creating the configuration."
	exit 1
fi

cp $lighttpd_conf /etc/lighttpd/lighttpd.conf
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
