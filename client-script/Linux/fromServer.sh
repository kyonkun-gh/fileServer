#!/bin/bash

#Dynamic Variable
shellPath=$(dirname $0)

#Load conf data
source "${shellPath}/my.conf"
url="${PROTOCOL}${REMOTE_HOST}:${PORT}/"

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


nc -z ${REMOTE_HOST} ${PORT}
if [ ! $? -eq 0 ]; then
	echo -e "${COLOR_ERROR}${url}${COLOR_RESET} is not open, please check!"
	exit 1
fi


declare -a fileNames
declare -a fileSizes
declare -a fileTimes
declare -a downloadUris
declare -a isSelected

while IFS=',' read -r fileName fileSize fileTime downloadUri; do
    fileNames+=("$fileName")
    fileSizes+=("$fileSize")
    fileTimes+=("$fileTime")
    downloadUris+=("$downloadUri")
    isSelected+=(0)
done < <(curl -s "${url}list-csv")

#echo ${fileNames[@]}
#echo ${downloadUris[@]}
#echo ${isSelected[@]}

length=${#fileNames[@]}
if [ ${length} -eq 0 ]; then
	echo -e "${COLOR_MSG}No file can be downloaded.${COLOR_RESET}"
	exit 0
fi

while true; do
	clear
	printf "%-1s %-5s %-50s %-12s %-20s\n" " " "Num" "File Name" "File Size" "Last Modified Time"
	for ((i=0; i<${length}; i++)); do
		if [ ${isSelected[i]} -eq "0" ]; then
			printf "%-1s %-5s %-50s %-12s %-20s\n" " " "${i}." "${fileNames[i]}" "${fileSizes[i]}" "${fileTimes[i]}"
		else
			printf "%-1s %-5s %-50s %-12s %-20s\n" "*" "${i}." "${fileNames[i]}" "${fileSizes[i]}" "${fileTimes[i]}"
		fi
	done

	read -p "${COLOR_MSG}Please select a number to download, [A]ll, [D]ownload or [Q]uit. ${COLOR_RESET}: " choice

	if [[ "${choice}" =~ ^[Qq]$ ]]; then
		exit 0
	elif [[ "${choice}" =~ ^[Dd]$ ]]; then
		break
	elif [[ "${choice}" =~ ^[Aa]$ ]]; then
		for ((i=0; i<${length}; i++)); do
			isSelected[i]=1
		done
	elif [[ "${choice}" =~ ^([0-9]+( [0-9]+)*)$ ]]; then
		IFS=' '
		for num in ${choice}; do
			if [ "${num}" -lt ${length} ]; then
				isSelected[${num}]=$((isSelected[${num}] ^ 1))
			fi
		done
		unset IFS
	else
		echo -e "${COLOR_ERROR}Not a valid input. ${COLOR_RESET}"
	fi
done

for ((i=0; i<${length}; i++)); do
	if [ ${isSelected[i]} -eq "0" ]; then
		continue
	fi
	echo "FILE: ${COLOR_INFO}${fileNames[i]} ${COLOR_RESET} Downloading..."
	curl -o ${fileNames[i]} ${downloadUris[i]}
done

