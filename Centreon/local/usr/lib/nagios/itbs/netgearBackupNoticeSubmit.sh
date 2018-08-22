#!/bin/sh
# This is a sample shell script showing how you can submit the PROCESS_SERVICE_CHECK_RESULT command
# to Nagios.  Adjust variables to fit your environment as necessary.
#
# Script a placer dans /usr/lib/nagios/plugins/itbs
# et executer : chmod 755
#
# Args
# $1 : host
# $2 : service
# $3 : trap

now=`date +%s`
commandfile='/var/lib/centreon-engine/rw/centengine.cmd'

#
# Match
# Successfully completed backup job Synchro W Secretariat.
# Error backup job Backup vers NAS: Source cannot be mounted on the system.
# 
# Edit 22/08/2018
# Case insensitive + modif du motif pour Raidiator 4.x
# match avec Backup job 002 completed. (nas-TTI) : Backup finished. Wed Aug 22 15:54:24 CEST 2018
servicename_in_trap=`echo "$3" | sed -rn 's/^.*backup job ([0-9]+|[^.:]+)( completed)?[.:].*/\1/Ip'`

#debug
echo $1
echo $2
echo $3
echo $servicename_in_trap

# ce trap ne concerne pas ce service
test ! "$servicename_in_trap" == "$2" && exit 0

# Status par defaut : 0-OK, 1-WARNING, 2-CRTICAL, 3-UNKNOWN
status=1

# Definition du status du service
if   [ "$(echo $3 | grep -i '^.*\(Successfully\|finished\).*')" ] ; then
	status=0

elif [ "$(echo $3 | grep -i '^.*Failure during copy.*')" ] ; then
	status=1
	
elif [ "$(echo $3 | grep -i '^.*Error.*')" ] ; then
	status=2
fi

#Submit result
printf "[%lu] PROCESS_SERVICE_CHECK_RESULT;$1;$2;$status;$3" $now > $commandfile