#!/bin/bash

#Dynamic Variable
realPath=$(realpath "$0")
shellPath=$(dirname "${realPath}")

#Load conf data
source ${shellPath}/my.conf
url="${PROTOCOL}${REMOTE_HOST}:${PORT}/"
path=$1

errorCount=0
if [ -z ${PROTOCOL} ]; then
	echo -e "${COLOR_ERROR}PROTOCOL not set, please check!${COLOR_RESET}"
	errorCount=$((errorCount+1))
fi
if [ -z ${REMOTE_HOST} ]; then
	echo -e "${COLOR_ERROR}REMOTE_HOST not set, please check!${COLOR_RESET}"
	errorCount=$((errorCount+1))
fi
if [ -z ${PORT} ]; then
	echo -e "${COLOR_ERROR}PORT not set, please check!${COLOR_RESET}"
	errorCount=$((errorCount+1))
fi
if [ -z ${DEFAULT_UPLOAD_PATH} ]; then
	echo -e "${COLOR_ERROR}DEFAULT_UPLOAD_PATH not set, please check!${COLOR_RESET}"
	errorCount=$((errorCount+1))
elif [ ! -d ${DEFAULT_UPLOAD_PATH} ]; then
	echo -e "${COLOR_ERROR}${DEFAULT_UPLOAD_PATH} is not a directory, please check!${COLOR_RESET}"
	errorCount=$((errorCount+1))
fi
if [ ${errorCount} -gt 0 ]; then
	echo -e "${COLOR_ERROR}Configure has some error, please check!${COLOR_RESET}"
	exit 1
fi


if [ -z "${path}" ]; then
	echo -e "Use Default Directory: ${COLOR_INFO}${DEFAULT_UPLOAD_PATH}${COLOR_RESET}"
	path=${DEFAULT_UPLOAD_PATH}
elif [ ! -d ${path} ]; then
	echo -e "${COLOR_ERROR}${path}${COLOR_RESET} is not a directory. Use Default Directory: ${COLOR_INFO}${DEFAULT_UPLOAD_PATH}${COLOR_RESET}"
	path=${DEFAULT_UPLOAD_PATH}
else
	path=`realpath ${path}`
fi


nc -z ${REMOTE_HOST} ${PORT}
if [ ! $? -eq 0 ]; then
	echo -e "${COLOR_ERROR}${url}${COLOR_RESET} is not open, please check!"
	exit 1
fi


for filePath in ${path}/*; do
	if [ -f ${filePath} ]; then
		echo -e "FILE: ${COLOR_INFO}${filePath}${COLOR_RESET} Uploading..."
		curl -v -F file=@${filePath} ${url}
	fi
done

