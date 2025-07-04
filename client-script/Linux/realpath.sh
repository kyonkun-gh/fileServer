#!/bin/bash
# Generate from Copilot and fix by myself

resolve_symlink() {
	local path="$1"
	
	cd "$(dirname ${path})"
	path="$(pwd)/$(basename ${path})"
	while [ -L "${path}" ]; do
		#echo "while loop start:$path"
		path=$(ls -ld "${path}" | awk '{print $NF}')
		#echo "link:$path"
		if [ -d "${path}" ]; then
			cd "${path}"
			path=$(pwd)
		else
			cd "$(dirname ${path})"
			path="$(pwd)/$(basename ${path})"
		fi
		#echo "end:$path"
	done
	echo "${path}"
}

realpath() {
	local path="$1"
	path=$(resolve_symlink "${path}")
	echo "${path}"
}

if [ $# -eq 0 ]; then
	echo "Usage: $0 <path>"
	exit 1
fi

realpath $1

