#!/bin/bash

#Color
COLOR_RESET=$'\e[0m'
COLOR_RED=$'\e[0;31m'
COLOR_GREEN=$'\e[0;32m'
COLOR_YELLOW=$'\e[0;33m'

#Static Variable
protocol="http://"
host="127.0.0.1"
port="8080"
txtFilePath="upload2ServerFile.txt"

#Dynamic Variable
shellPath=$(dirname $0)
url="$protocol$host:$port/"
curMonth=`date --date="$(date +%Y-%m-15) -1 month" "+%m"`
filePaths=()
errorCount=0

#Change Directory
cd $shellPath


nc -z ${host} ${port}
if [ ! $? -eq 0 ]; then
	echo -e "$url${COLOR_RED} is not open. EXIT ${COLOR_RESET}"
	exit 1
fi

if [ ! -f $txtFilePath ]; then
	echo -e "$txtFilePath${COLOR_RED} does not exists. EXIT ${COLOR_RESET}"
	exit 1
fi

while IPS= read -r line
do
	filePath=`echo $line | sed -e "s/{MONTH}/${curMonth}/"`
	filePaths+=("$filePath")
	if [ ! -f $filePath ]; then
		errorCount=$((errorCount+1))
		echo -e "UPLOAD FILE NOT FOUND: ${COLOR_RED}$filePath ${COLOR_RESET}"
	fi
done < $txtFilePath

if [ $errorCount -gt 0 ]; then
	echo -e "${COLOR_RED}Some target files do not exists. EXIT${COLOR_RESET}"
	exit 1
fi


for filePath in ${filePaths[@]}; do
	data=`ls -l $filePath`
	echo -e "${COLOR_GREEN}$data${COLOR_RESET}"
done

read -p "${COLOR_YELLOW}Do you want to upload above file(s)? (y)Yes/(n)No: ${COLOR_RESET}" choice

case $choice in
	[yY]* )	;;
	*)	echo -e "${COLOR_RED}Script leave!!${COLOR_RESET}"
		exit 0 ;;
esac


for filePath in ${filePaths[@]}; do
	echo -e "FILE: ${COLOR_GREEN}$filePath ${COLOR_RESET}Uploading..."
	curl -v -F file=@$filePath $url
done

