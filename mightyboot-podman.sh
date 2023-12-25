#!/bin/bash

set -e

# Global Variables
POD_NAME="mightyboot"
SERVICES="dhcp dhcp6 dnsmasq lighttpd"

REGISTRY="localhost"

ENV_FILE="${PWD}/env"

LOG_DRIVER="journald"

REBUILD=""

function usage()
{
	echo "$0: manage mightyboot containers with podman"
	echo "Usage:"
	echo "  $0 command (service) "
	echo ""
	echo "Services: ${SERVICES}"
	echo ""
	echo "Commands:"
	echo "  start"
	echo "     start a service or start all services if not specified"
	echo ""
	echo "  rebuild"
	echo "     rebuild a service or rebuild all services if not specified"
	echo ""
	echo "  stop"
	echo "     stop a service or stop all services if not specified"
	echo ""
	echo "  remove"
	echo "     remove a service or remove all services if not specified"
	echo ""
	echo "  status"
	echo "     print the status of services"
}

function check_service()
{
	target=$1
	for service in $SERVICES; do
		if [ "$target" == "$service" ]; then
			return 0
		fi
	done
	return 1
}

function check_pod()
{
	podman pod exists ${POD_NAME}
}

function check_image()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi
	podman image exists ${REGISTRY}/${POD_NAME}-${service}
}

function check_container()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi
	podman container exists ${POD_NAME}-${service}
}

function check_running_container()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi
	podman container ps --format "{{.Names}}" | grep -q "${POD_NAME}-${service}\$"
}

function mount_arg()
{
	SRC=$1
	DST=$2
	RO=$3

	mount_arg="--mount type=bind,src=${SRC},dst=${DST}"
	if [ "${RO}" == "y" ]; then
		mount_arg="${mount_arg},ro"
	fi
	echo ${mount_arg}
}

function create_container_real()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	local extra_opt=

	case ${service} in
		"dhcp")
			MOUNT_ARGS=$(mount_arg ${PWD}/data/dhcp /data n)
			extra_opt="--privileged"
			;;

		"dhcp6")
			MOUNT_ARGS=$(mount_arg ${PWD}/data/dhcp6 /data n)
			;;

		"dnsmasq")
			MOUNT_ARGS=$(mount_arg ${PWD}/data/dnsmasq /data n)
			MOUNT_ARGS="${MOUNT_ARGS} $(mount_arg ${PWD}/data/tftproot /srv/tftproot y)"
			;;

		"lighttpd")
			MOUNT_ARGS=$(mount_arg ${PWD}/data/lighttpd /data n)
			MOUNT_ARGS="${MOUNT_ARGS} $(mount_arg ${PWD}/data/www/htdocs /srv/www/htdocs y)"
			;;
		*)
			echo "unknown service"
			exit 1
			;;
	esac

	podman create ${extra_opt} --pod ${POD_NAME} \
		--network host \
		--env-file ${ENV_FILE} \
		--log-driver="${LOG_DRIVER}" \
		${MOUNT_ARGS} \
		--name ${POD_NAME}-${service} \
		${REGISTRY}/${POD_NAME}-${service}
}

function stop_service()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if check_running_container ${service} ; then
		echo "Stop ${POD_NAME}-${service}"
		podman container stop ${POD_NAME}-${service}
	fi
}

function remove_container()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if check_container ${service} ; then
		echo "Remove container: ${POD_NAME}-${service}"
		podman container rm ${POD_NAME}-${service}
	fi
}

function remove_image()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if check_image ${service} ; then
		echo "Remove image: $REGISTRY/${POD_NAME}-${service}"
		podman image rm $REGISTRY/${POD_NAME}-${service}
	fi
}

function remove_service()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	stop_service ${service}
	remove_container ${service}
	remove_image ${service}
}

function remove_pod()
{
	echo "Remove pod: ${POD_NAME}"
	podman pod rm ${POD_NAME}
}

function create_pod()
{
	echo "Create pod: ${POD_NAME}"
	# podman pod create --name mightyboot --network bridge --replace -p 53:53 -p 67:67 -p 68:68 -p 69:69 -p 80:80 -p 443:443
	podman pod create --name ${POD_NAME} --network host --replace
}

function build_image()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if ! check_image ${service} ; then
		echo "Build ${POD_NAME}-${service}"
		podman build -t ${POD_NAME}-${service} -f ${service}/Dockerfile
	fi
}

function create_container()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if ! check_container ${service} ; then
		echo "Create ${POD_NAME}-${service}"
		create_container_real ${service}
	fi
}

function start_container()
{
	service=$1
	if ! check_service ${service}; then
		echo "unknown service: ${service}"
		exit 1
	fi

	if ! check_running_container $service; then
		echo "Start ${service}"
		podman start ${POD_NAME}-${service}
	else
		echo "${service} already started"
	fi
}

function cmd_rebuild()
{
	# If the service is not specified, rebuild all services.
	if [ -z "$1" ]; then
		REBUILD_SERVICE=${SERVICES}
	else
		REBUILD_SERVICE=$1
	fi

	for service in ${REBUILD_SERVICE}; do
		remove_service ${service}
	done

	# Reset the pod if necessary
	if [ -z "$1" ]; then
		create_pod
	fi

	for service in ${REBUILD_SERVICE}; do
		build_image ${service}
		create_container ${service}
	done
}

function cmd_stop()
{
	# If the service is not specified, stop all services.
	if [ -z "$1" ]; then
		STOP_SERVICE=${SERVICES}
	else
		STOP_SERVICE=$1
	fi

	for service in ${STOP_SERVICE}; do
		stop_service ${service}
	done
}

function cmd_remove()
{
	# If the service is not specified, remove all services.
	if [ -z "$1" ]; then
		RM_SERVICE=${SERVICES}
	else
		RM_SERVICE=$1
	fi

	for service in ${RM_SERVICE}; do
		remove_service ${service}
	done
}

function cmd_start()
{
	# If the service is not specified, start all services.
	if [ -z "$1" ]; then
		START_SERVICE=${SERVICES}
	else
		START_SERVICE=$1
	fi

	if ! check_pod ; then
		create_pod
	fi

	for service in ${START_SERVICE}; do
		build_image ${service}
		create_container ${service}
	done

	for service in ${START_SERVICE}; do
		start_container ${service}
	done
}

function cmd_status()
{
	for service in ${SERVICES}; do
		if check_running_container ${service}; then
			printf "%-8s is running\n" ${service}
		else
			printf "%-8s is down\n" ${service}
		fi
	done
}

# Parse the arguments
case $1 in
	rebuild)
		cmd_rebuild $2
		;;
	stop)
		cmd_stop $2
		;;
	remove)
		cmd_remove $2
		;;
	start)
		cmd_start $2
		;;
	status)
		cmd_status
		;;
	*)
		usage
		exit 1
		;;
esac
