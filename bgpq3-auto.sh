#!/bin/bash

source .env

LOG_FILE="$(pwd)/checks.log"

add_log()
{
	LOG_DT=$(date +"%Y-%m-%d %H:%M:%S")
	echo "${LOG_DT} [${2}] ${1}" >> $LOG_FILE
}

send_email()
{
	ENCODED=${2//$'\n'/<br/>} # Replace \n with <br/> for email formatting
	ENCODED=$(echo ${ENCODED} | sed -e 's/ /\&nbsp;/g') # Replace spaces with &nbsp for email formatting
	 
	# Use SendGrid for emailing updates
	curl --request POST --url "https://api.sendgrid.com/v3/mail/send" --header "Authorization: Bearer ${SENDGRID_API_KEY}" --header 'Content-Type: application/json' --data '{"personalizations": [{"to": [{"email": "'${EMAIL_TO}'"}]}],"from": {"email": "'${EMAIL_FROM}'"},"subject":"[bgpq3] Peer Update","content": [{"type": "text/html","value": "'${1}' has an updated prefix list.<p>'${ENCODED}'</p>"}]}'
}

if [ -z $1 ]
then
	add_log "No peers given"
	exit
fi

for peer in "$@"
do
	add_log "Processing" ${peer}
	# Get current Unix time, also set UC and LC variables to use during script
	TIME=$(date +%s)
	PEER_UC=$(echo $peer | tr '[:lower:]' '[:upper:]')
	PEER_LC=$(echo $peer | tr '[:upper:]' '[:lower:]')
	AS_SET="AS-${PEER_UC}"

	# Create a directory for the peer if they don't exist
	mkdir -p "${PEER_LC}"
	
	# Delete any previous .tmp files that haven't been cleaned up
	cd ${PEER_LC}

	find ./ -maxdepth 1 -type f -name "*.tmp" -delete 

	# Run the BGP query and save to a .tmp file
	add_log "Querying" ${peer}
	bgpq3 -S ARIN,ALTDB,RADB,LEVEL3,NTTCOM,RIPE -AXR 24 -m 24 -l $PEER_UC-IN-IPV4 $AS_SET >> "${TIME}.tmp"
	
	# For Dev Purposes, add timestamp to end of file so there's a difference
	 echo ${TIME} >> "${TIME}.tmp"

	# Get a list of .cur files
	CUR_ARR=(`find ./ -maxdepth 1 -name "*.cur"`)
	if [ ${#CUR_ARR[@]} -gt 0 ];
	then
		# If a .cur file exists,compare it to the .tmp file we just got
		add_log "Comparing new results" ${peer}
		if cmp -s ${CUR_ARR[0]} "${TIME}.tmp";
		then
			# If no change detected, just remove the .tmp
			rm ${TIME}.tmp
			add_log "No change detected. Removing tmp file." ${peer}
		else 
			# If there's a change detected, remove existing .last, move existing .cur to .last and .tmp to .cur
			add_log "Change detected. Moving files." ${peer}
			FILE=$(basename ${CUR_ARR[0]})
			FILENAME=${FILE::-4}
			find ./ -maxdepth 1 -type f -name "*.last" -delete
			mv $FILE "${FILENAME}.last"
			mv "${TIME}.tmp" "${TIME}.cur"

			add_log "Files moved" ${peer}
			send_email "${peer}" "`cat ${TIME}.cur`"
		fi
	else
		mv "${TIME}.tmp" "${TIME}.cur"
		add_log "Initial query completed" ${peer}
		send_email "${peer}" "`cat ${TIME}.cur`"
	fi
	cd ..
	add_log "Query completed" ${peer}
done
