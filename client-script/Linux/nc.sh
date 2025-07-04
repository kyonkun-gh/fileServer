#!/bin/bash

netcat() {
	local host=$1
	local port=$2
	#timeout 3 bash -c "echo >/dev/tcp/${host}/${port}" && echo "Port is open" || echo "Port is closed"
	timeout 3 bash -c "echo >/dev/tcp/${host}/${port}" && return 0 || return 1
}

case "$1" in
	-z)
		if [ $# -lt 3 ]; then
			echo "Usage: $0 -z <host> <port>"
			exit 1
		fi
		netcat $2 $3
		exit $?
		;;
	*)
		echo "Usage: $0 -z <host> <port>"
		exit 1
		;;
esac

