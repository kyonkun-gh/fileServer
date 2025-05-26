#!/bin/bash

#Color
COLOR_RESET=$'\e[0m'
COLOR_RED=$'\e[0;31m'
COLOR_GREEN=$'\e[0;32m'

#Static Variable
protocol="http://"
host="127.0.0.1"
port="8080"

#Dynamic Variable
shellPath=$(dirname $0)
url="$protocol$host:$port/"
defaultPath="/root/Downloads"
path=$1


if [ "X${path}" == "X" ]; then
	echo -e "${COLOR_GREEN}Use Default Directory ${defaultPath}${COLOR_RESET}"
	path=${defaultPath}
elif [ ! -d ${path} ]; then
	echo -e "${COLOR_RED}Not Directory, Use Default Directory ${defaultPath}${COLOR_RESET}"
	path=${defaultPath}
else
	path=`realpath ${path}`
fi

nc -z ${host} ${port}
if [ ! $? -eq 0 ]; then
	echo -e "${url}${COLOR_RED} is not open. EXIT ${COLOR_RESET}"
	exit 1
fi

for filePath in ${path}/*; do
	if [ -f $filePath ]; then
		echo -e "FILE: ${COLOR_GREEN}$filePath ${COLOR_RESET}Uploading..."
		curl -v -F file=@$filePath $url
	fi
done

