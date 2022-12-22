#!/bin/sh

REVERSE=0
LASTVOL=0
TARGETVOL=7

volMin(){

	while [ $(cat /pps/foryou/eq/status | grep fyvolume |  sed 's/.*"current":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')  -gt $TARGETVOL ]
	do
		echo 'fyvolume::-2' >> /pps/foryou/eq/control 
	done

}

volReturn(){

	while [ $(cat /pps/foryou/eq/status | grep fyvolume |  sed 's/.*"current":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')  -lt $LASTVOL ]
	do
		echo 'fyvolume::2' >> /pps/foryou/eq/control 
	done

}

while :
do
	if [ $REVERSE -eq 0 ]; then
		if [ $(cat /pps/foryou/system/src_status | grep front_src |  sed 's/.*"src":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/') == "camera" ]; then
			LASTVOL=$(cat /pps/foryou/eq/status | grep fyvolume |  sed 's/.*"current":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')
			REVERSE=1
			volMin
		fi
	else
		if [ $(cat /pps/foryou/system/src_status | grep front_src |  sed 's/.*"src":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/') != "camera" ]; then
			REVERSE=0
			volReturn
		fi
	fi

sleep 1
done
