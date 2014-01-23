#!/bin/bash

mailMessage="/tmp/asic_mail_message"

if [ ! -d /opt/saxon/etc ] ; then
        echo "Configuration directory missing or unreadable. Please correct and try again"
        exit 1
fi

if [ ! -f /opt/saxon/etc/find_cubes.conf ] ; then
        echo "Configuration file is missing or unreadable.  Please correct and try again"
        exit 1
fi


source /opt/saxon/etc/find_cubes.conf

if [ ! -f ${knownBadAsic} ] ; then
	touch ${knownBadAsic}
fi


cat $currentConfig | while read -r cube ; do
	ping -c 1 ${cube} > /dev/null
	rc=$?
	if [[ ${rc} -eq 0 ]] ; then
		wget -q -O- ${cube}:8000 |  awk -F "<br>" '{print $2, $3, $4, $5, $6, $7}' | cut -d "<" -f1 | tr A '\n' | tail -n 6 > /tmp/cube_${cube}_asic

		cat /tmp/cube_${cube}_asic | while read -r asicLine ; do
		asicStart=`echo ${asicLine} | cut -d _ -f2 | cut -d - -f1`
		#echo $asicStart
		if [[ `echo ${asicLine} | grep -c -i "x"` -ge 1 ]] ; then
			badBlade=`echo $asicLine | grep -i -b -o x | cut -d: -f1`
			for badAsicSub in ${badBlade} ; do
				badAsic=$((asicStart+((badAsicSub-11)/2)))
				if [[ `grep -c ${cube}:${badAsic} ${knownBadAsic}` -eq 0 ]] ; then
					echo  ${cube}:${badAsic} >> ${knownBadAsic}
					echo "${cube}:${badAsic} is bad" >> ${mailMessage}
				else
					if [[ ${alertKnownBad} -eq 1 ]] ; then
						echo "${cube}:${badAsic} is bad" >> ${mailMessage}
					fi
				fi
					
				
			done 
		fi
		done 
	fi

done

if [ -f ${mailMessage} ] ; then
        cat $mailMessage | sort | mail -r $mailFrom -s "Check ASIC Script @`hostname`" $mailTo
        rm ${mailMessage}
fi

rm /tmp/cube_*_asic
