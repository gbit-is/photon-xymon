#!/bin/bash

#################################################
#												#
#              Set Variables					#
#												#
#################################################

# All tests begin as green.
diskColor="green"
inodeColor="green"
memColor="green"
cpuColor="green"

# Limits ( threshholds) for each test
diskLimit=95
inodeLimit=90
memLimit=95
cpuLimit=95


# Temp file to stora data
tmpfile="/tmp/xymontmp$$.temp"

# Connection Info to the Xymon server
xymonServer="Insert IP"
xymonPort="Insert Port"


#################################################
#												#
#		Define function							#
#												#
#################################################


# Function to send data to xymon without a client, netcat, telnet, etc
# Usage: sendToXymon TestName TestColor
sendToXymon() {

	HOST=$xymonServer
	PORT=$xymonPort
	testName=$1
	testColor=$2

	MSG="status $(hostname).$testName $testColor $(cat $tmpfile)" # Collects body from the tempfile


	exec 3<>/dev/tcp/$HOST/$PORT || exit 1 
	echo "$MSG" >&3

}


#################################################
#												#
#				   Disk Test					#
#												#
#################################################




IFS=$'\n' # Make newline the seperator in for for loops

dfData=$(df -m) 

echo "Disk status (Mb)" > $tmpfile # Clear and set first line for test body

for i in $(echo "$dfData" | tail -n+2);do

	percentage=$(echo "$i" | awk '{print $5}' | tr -dc '0-9')

	if [ $percentage -lt $diskLimit ];then #Each line is parsed and given a color in the body

		echo "&green $i" >> $tmpfile  # &green will be represented as a green icon in Xymon
	else
		echo "&red $i" >> $tmpfile
		diskColor="red" # Test set as red


	fi

done



sendToXymon "disk" $diskColor   # Data is sent to Xymon

#################################################
#												#
#					Inode Test					#
#												#
#################################################

echo "Inode status (%)" > $tmpfile # Clear and set first line for test body

inodeData=$(df -i) # Get Inode data

for i in $(echo "$inodeData" | tail -n+2);do # Parse each line

        percentage=$(echo "$i" | awk '{print $5}' | tr -dc '0-9')

        if [ $percentage -lt $inodeLimit ];then

                echo "&green $i" >> $tmpfile
        else
                echo "&red $i" >> $tmpfile
                inodeColor="red"


        fi

done



sendToXymon "Inodes" $inodeColor # Data is sent to xymon


#################################################
#												#
#	 				Mem Test					#
#												#
#################################################


echo "Memory status (Mb)" > $tmpfile # Clear and set first line for test body

memInfo=$(free -m)


memTotal=$(echo "$memInfo" | head -2 | tail -1 | awk '{print $2}') # Get total memory
memFree=$(echo "$memInfo" | head -2 | tail -1 | awk '{print $3}') # Get free memory
swapTotal=$(echo "$memInfo" | tail -1 | awk '{print $2}') # Get total swap memory
swapFree=$(echo "$memInfo" |tail -1 | awk '{print $3}') # Get free swap memory

totalFree=$((memFree + swapTotal)) # GGet total free memory, normal free + swap free
memoryUsage=$(echo "scale=5;$totalFree / $memTotal" | bc) # Divide total free with total memory 
memoryUsage=$(echo "$memoryUsage * 100" | bc) # Multiply by 100 to make it a percentage
memoryUsage=$(echo "scale=0; $memoryUsage / 1" | bc) # Drop extra characters, turn it into an Int

if [ $memoryUsage -gt $memLimit ];then
	memColor="red"
fi


for line in $(echo "$memInfo");do # Print out data to tempfiile
	echo "$line" >> $tmpfile

done



sendToXymon "memory" $memColor # Data is sent to Xymon


#################################################
#												#
#					CPU Test					#
#												#
#################################################


echo "CPU Info:" > $tmpfile # Clear and set first line for test body

cpuPrint=$(top -bn1 | head -6) # Get data to display in body
cpuInfo=$(uptime | rev | awk '{print $2}'| rev | sed 's/,//') # Get data to parse


cpuLoad=$(echo "$cpuInfo * 100" | bc) # Turn fraction into percentage
cpuLoad=$(echo "scale=0;$cpuLoad / 1 " | bc) # Remove extra letters, turn into an Int

if [ $cpuLoad -gt $cpuLimit ];then
	cpuColor="red"
fi

echo "Average Load (5m): $cpuLoad%" >> $tmpfile # Print AVG load to file

echo "" >> $tmpfile # empty line for better look

for line in $(echo "$cpuPrint");do # Print data to temp file
	echo "$line" >> $tmpfile
done

sendToXymon "cpu" $cpuColor # Data is sent to Xymon


rm $tmpfile # No need to keep this file anymore

exit
