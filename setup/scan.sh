#!/bin/bash
# Variables are identified as $1 for first one, $2 for second so on and so forth
IFS=/
read ip1 ip2 <<< "$3"
IFS=""
#cd /home/jallphin/redbot/redteam-scripts
#echo $ip1 "--" $ip2

display_usage() {
	echo -e "[*] IVRE Recon Scan Usage - redbot recon <name_of_scan> range <start address> <end address> | Example: redteam range 10.1.1.1 10.1.1.15"
	echo -e "[*] IVRE Recon Scan Usage - redbot recon <name_of_scan> network <network with mask> | Example: redteam network 10.1.1.1/32"
	}

# if less than two arguments supplied, display usage
	if [  $# -le 1 ]
	then
		display_usage
		exit 0
	fi

# check whether user had supplied -h or --help. If yes, display usage
	if [[ ($# == "--help") || ($# == "-h" ) || ($# == "help") ]]
	then
		display_usage
		exit 0
	fi

# display usage if the script is not run as root user
#	if [[ $USER != "root" ]]; then
#		echo "RedBot requires root privleges to run scans!\n"
#		exit 0
#	fi
FAIL=0

# check to make sure the supplied netmask is does not contain less than 8 or more than 33 as we don't anticipate scanning any networks larger than this
	if [[ "$ip2" -le 8 || "$ip2" -ge 33 ]]
	then
		echo -e "ip1 was $ip1 and ip2 was $ip2"
		echo -e "[!!!] Scan limits are greater than or equal to /8 and less than or equal to /32. Please adjust scan parameters!\n"
		exit 0
	fi


# Use IVRE to scan the target(s)
docker exec -t -w /red-share/ivre ivreclient ivre runscans --output=XML --categories $1 --$2 ${3} ${4} 1>/dev/null 2>/dev/null &
#echo "docker exec -t ivreclient ivre runscans --categories $1 --$2 $3"
#docker exec -t ivreclient ivre runscans --categories $1 --$2 ${3} ${4}
# Wait for the job to complete and provide status updates
for scan_job in `jobs -p`
do
    echo -e "[*] IVRE scan ${3} ${4} started with PID $! in progress..."
    wait $scan_job || let "FAIL+=1"

done

# Provide status on scan
if [[ "$FAIL" == "0" ]];
then
	echo -e "[**] IVRE scan ${3} ${4} with PID $!:Completed"
else
	echo -e "[!!!] IVRE scan on $3 $4 with PID $!:FAILED with $FAIL"

fi

# Push results of scan to the database
#docker run -t ivreclient ivre scan2db -c $1 -s RedBot -r scans/$1/up >/dev/null 2>/dev/null &
#echo "docker exec -t ivreclient ivre scan2db -c $1 -s RedTeam -r scans/$1/up"
echo -e "[*] Updating database for IVRE scan $3 $4 with PID $!"
docker exec -w /red-share/ivre -t ivreclient ivre scan2db -c $1 -s ACT -r /red-share/ivre/scans/$1/up 1>/dev/null 2>/dev/null &
for push_job in `jobs -p`
do
	wait $push_job || let "FAIL+=1"
done

# Provide status of scan push
if [[ "$FAIL" == "0" ]];
then
	echo -e "[*] Updating the database views....\n"
	docker exec -w /red-share/ivre -t ivreclient ivre db2view 1>/dev/null 2>/dev/null
	echo -e "[**] IVRE database updated sucessfully with IVRE Recon scan on $3 $4 with PID $!"
	echo -e "[**] IVRE Recon scan results at http://ivre.rts.lan/#category:$1"
else
	echo -e "[!!!] Database NOT updated for IVRE scan $3 $4 with PID $!!"
fi

