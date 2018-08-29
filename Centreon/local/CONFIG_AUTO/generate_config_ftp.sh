#!/bin/sh


now=`date +%s`
logfile="/tmp/generate_config_ftp-$now.log"

centreon_admin_password='P@ssword!itbs'




host_name="HP-MLT.ITBS.net"

templates=$(centreon -u admin -p $centreon_admin_password -o HOST -a gettemplate -v "$host_name" | tail -n +2 | cut -d ";" -f 2)

for i in $templates ; do
	
done

