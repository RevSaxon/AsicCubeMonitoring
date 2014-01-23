#!/bin/bash

mailMessage="/tmp/cube_mail_message"

if [ ! -d /opt/saxon/etc ] ; then
	echo "Configuration directory missing or unreadable. Please correct and try again"
	exit 1
fi

if [ ! -f /opt/saxon/etc/find_cubes.conf ] ; then
	echo "Configuration file is missing or unreadable.  Please correct and try again"
	exit 1
fi

source /opt/saxon/etc/find_cubes.conf

if [ -f ${tmpConfig} ] ; then
	rm ${tmpConfig}
fi

if [[ ! -f ${currentConfig} ]] ; then
	firstRun=1
fi

bigList=`sudo /usr/bin/arp-scan --interface=wlan0 --localnet`
if [[ $? -ne 0 ]] ; then
	echo "Error scanning network" | mail -r $mailFrom -s "Find Node Script @`hostname`" $mailTo
fi

while read -r line ; do
	if [[ `echo ${line} | grep -c "Microchip Technology, Inc"` -eq 1 ]] ; then
		cubeIP=`echo ${line} | cut -d " " -f1`
		echo ${cubeIP} >> ${tmpConfig}
		echo "Found Miner at $cubeIP"
		
	fi
done <<< "${bigList}"

if [ ! -f ${tmpConfig} ] ; then
	echo "No cubes found"
	exit 1
fi

if [[ ${firstRun} -eq 1 ]] ; then
	cp ${tmpConfig} ${currentConfig}
fi

#and now for the pfm
diff ${tmpConfig} ${currentConfig} > /dev/null
differentList=$?
if [[ ${differentList} -eq 1 ]] ; then
	uniqNodes=`cat ${tmpConfig} ${currentConfig} | sort | uniq`
	while read -r node ; do
		echo ${node}
		if [[ `grep -c ${node} ${tmpConfig}` -eq 1 ]] ; then
			echo "${node}" >> ${currentConfig}
			echo "Added ${node} to cube monitoring" >> ${mailMessage}
		else
			if [[ $autoClean -eq 1 ]] ; then
				sed -i "/${node}/d" ${currentConfig}
				echo "Removed ${node} from cube monitoring" >> ${mailMessage}
			fi
		fi

	done <<< "${uniqNodes}"
fi

if [ ! -s ${currentConfig} ] ; then
	rm ${currentConfig}
	echo "No nodes currently running on network!" |  mail -r $mailFrom -s "Find Node Script @`hostname`" $mailTo
	exit 1
fi
	

if [ -f ${mailMessage} ] ; then
	cat $mailMessage | sort | mail -r $mailFrom -s "Find Node Script @`hostname`" $mailTo
	rm ${mailMessage}
fi
