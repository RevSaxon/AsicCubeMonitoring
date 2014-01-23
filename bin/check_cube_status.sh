#!/bin/bash 

emailOnly=0
missingCube=0

if [ ! -d /opt/saxon/etc ] ; then
        echo "Configuration directory missing or unreadable. Please correct and try again"
        exit 1
fi

if [ ! -f /opt/saxon/etc/find_cubes.conf ] ; then
        echo "Configuration file is missing or unreadable.  Please correct and try again"
        exit 1
fi

source /opt/saxon/etc/find_cubes.conf


if [[ $# -eq 1 ]] ;  then
	#running in cron mode
	emailOnly=1
fi

if [ ! -f ${currentConfig} ] ; then
	/opt/saxon/bin/find_cubes.sh
	if [ $? -eq 1 ] ; then
		if [[ ${emailOnly} == "1" ]] ; then
			echo "No cubes on current network" >> /tmp/cubize_out
			missingCube=$((missingCube + 1))
		else
			exit 1
		fi
	fi
fi

cat $currentConfig | while read -r cube ; do
	ping -c 1 ${cube} > /dev/null
	rc=$?
	if [[ ${rc} -eq 0 ]] ; then
		cubeString=`wget -q -O- ${cube}:8000 | cut -d"<" -f 36 | cut -d ">" -f2`
		if [[ -z "${cubeString}" ]] ; then
			cubeString="Cube online but not responding"
			missingCube=$((missingCube + 1))
		fi
	else
		missingCube=$((missingCube + 1))
		cubeString="Cube is not online"
	fi
	if [[ ${emailOnly} == "1" ]] ; then
		echo "${cube}: ${cubeString}" >> /tmp/cubize_out
	else
		echo "${cube}: ${cubeString}"
	fi
done

if [[ "${emailOnly}" == "1" ]] ; then
	if [[ ${missingCube} -ge 1 ]] ; then
		mail -r ${mailFrom} -s "Cube Report: ${missingCube} failures" ${mailTo} < /tmp/cubize_out
	fi
	rm /tmp/cubize_out
fi
