#!/bin/bash

mailMessage="/tmp/speed_mail_message"
printOnly=0

if [ ! -d /opt/saxon/etc ] ; then
        echo "Configuration directory missing or unreadable. Please correct and try again"
        exit 1
fi

if [ ! -f /opt/saxon/etc/find_cubes.conf ] ; then
        echo "Configuration file is missing or unreadable.  Please correct and try again"
        exit 1
fi


source /opt/saxon/etc/find_cubes.conf

if [ "$#" -eq 0 ] ; then
	printOnly=1
else
	desiredSpeed=$1
fi





currentSpeed () {
	clockSpeed=`wget -q -O- ${cube}:8000 |  awk -F "<br>" '{print $19}'| cut -d: -f2`
	echo ${clockSpeed}
}
	
flipSpeed () {
	wget -q -O- ${cube}:8000/Sw_Clock > /dev/null
}



cat $currentConfig | while read -r cube ; do
	ping -c 1 ${cube} > /dev/null
        rc=$?
        if [[ ${rc} -eq 0 ]] ; then
		runSpeed=`currentSpeed ${cube}`
		if [ ${printOnly} -eq 1 ] ; then
			echo ${cube}: ${runSpeed}
		else
			if [ "`currentSpeed ${cube}`" != "${desiredSpeed}" ] ; then
				flipSpeed ${cube}
			fi
		fi
	fi
done
		
