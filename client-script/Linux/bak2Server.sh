#!/bin/bash

#Static Variable
txtFilePath="upload2ServerFile.txt"

#Dynamic Variable
shellPath=$(dirname $0)

#Load conf data
source ${shellPath}/my.conf
url="${PROTOCOL}${REMOTE_HOST}:${PORT}/"
lastMonth=`date --date="$(date +%Y-%m-15) -1 month" "+%m"`
filePaths=()

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
if [ ${errorCount} -gt 0 ]; then
	echo -e "${COLOR_ERROR}Configure has some error, please check!${COLOR_RESET}"
	exit 1
fi

#Change Directory
cd $shellPath


nc -z ${REMOTE_HOST} ${PORT}
if [ ! $? -eq 0 ]; then
	echo -e "${COLOR_ERROR}${url}${COLOR_RESET} is not open, please check!"
	exit 1
fi

if [ ! -f ${txtFilePath} ]; then
	echo -e "${COLOR_ERROR}${txtFilePath}${COLOR_RESET} does not exists, please check!"
	exit 1
fi

while IPS= read -r line
do
	filePath=`echo $line | sed -e "s/{MONTH}/${lastMonth}/"`
	filePaths+=("$filePath")
	if [ ! -f ${filePath} ]; then
		errorCount=$((errorCount+1))
		echo -e "UPLOAD FILE NOT FOUND: ${COLOR_ERROR}${filePath}${COLOR_RESET}"
	fi
done < ${txtFilePath}

if [ ${errorCount} -gt 0 ]; then
	echo -e "${COLOR_ERROR}Some target files do not exists, please check!${COLOR_RESET}"
	exit 1
fi


for filePath in ${filePaths[@]}; do
	data=`ls -l ${filePath}`
	echo -e "${COLOR_INFO}${data}${COLOR_RESET}"
done

read -p "${COLOR_MSG}Do you want to upload above file(s)? (y)Yes/(n)No: ${COLOR_RESET}" choice

case ${choice} in
	[yY]* )	;;
	*)	echo -e "${COLOR_ERROR}Script leave!!${COLOR_RESET}"
		exit 0 ;;
esac


for filePath in ${filePaths[@]}; do
	echo -e "FILE: ${COLOR_INFO}${filePath}${COLOR_RESET} Uploading..."
	curl -v -F file=@${filePath} ${url}
done

