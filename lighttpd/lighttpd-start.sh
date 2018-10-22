#!/bin/bash

set -e

# Exit if there is no assigned interface
if [ -z "$IFACE" ]; then
	echo "No Assigned Interace"
	exit
fi

data_dir="/data"
if [ ! -d "$data_dir" ]; then
	echo "Please ensure '$data_dir' folder is available."
	echo 'If you just want to keep your configuration in "data/", add -v "$(pwd)/data:/data" to the docker run command line.'
	exit 1
fi

if [ -z "$SERVER_KEY" ]; then
	lighttpd_conf="$data_dir/lighttpd-ssl.conf"

	server_key=$data_dir/$SERVER_KEY
	if [ ! -r "$server_key" ]; then
		echo "Please ensure '$server_key' exists and is readable"
		exit 1
	fi
	cp $server_key /etc/ssl/private/
else
	lighttpd_conf="$data_dir/lighttpd.conf"
fi
if [ ! -r "$lighttpd_conf" ]; then
	echo "Please ensure '$lighttpd_conf' exists and is readable."
	echo "Run the container with arguments 'man lighttpd.conf' if you need help with creating the configuration."
	exit 1
fi

cp $lighttpd_conf /etc/lighttpd/lighttpd.conf
exec /usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
