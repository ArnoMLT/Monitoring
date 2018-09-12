#!/bin/sh

# MLT
# 08/05/2018

# Lance les actions de nettoyage suite a la reception du ack
# Pour le nouveau host cree automatiquement dans Centreon


# $1 HOST_ID

# Chargement de la config globale
source "/usr/lib/nagios/plugins/itbs/etc/config.cfg"



now=`date +%s`
logfile="/tmp/${now}_ack.log"


# chemins sur le FTP
# ftp_temp_config_dir='nsclient/config-temp'
relative_temp_config_dir='config-temp'


##	 			##
#     MAIN	  	 #
##				##


if [ $# -lt 1 ] ; then
	echo "Usage : $0 <HOST_ID> " >&2 >> $logfile
	echo "        HOST_ID : Id Centreon du host qui emet le ack" >&2 >> $logfile
    exit 1
fi

re='^[1-9][0-9]*$'
if ! [[ $1 =~ $re ]] ; then
   echo "Erreur :  Le HOST_ID doit etre un nombre entier et ne commence pas par 0. Exit" >&2 >> $logfile
   exit 1
fi

host_id=$1
echo $host_id >> $logfile

###
 # Supprime les fichiers inutiles sur le FTP
###
clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a SHOW | grep "^$host_id;"'

if [ $(eval $clapi_cmd \| wc -l) -gt 1 ] ; then
	echo "Erreur CLAPI : Le HOST_ID retourne trop de resultats. Exit" >&2 >> $logfile
	exit 2
fi

centreon_host_info="$(eval $clapi_cmd)"

host_name=`echo $centreon_host_info | sed -n "s/^.*;\(.*\);.*;\(.*\);.*$/\1/p"`
host_ip_address=`echo $centreon_host_info | sed -n "s/^.*;\(.*\);.*;\(.*\);.*$/\2/p"`

echo $path_to_nsclient_config/$relative_temp_config_dir/$host_name-$host_ip_address.ini >> $logfile

rm -f $path_to_nsclient_config/$relative_temp_config_dir/$host_name-$host_ip_address.ini
# ftp $ftp_site_addr <<EOF
# cd "$ftp_temp_config_dir"
# delete $host_name-$host_ip_address.ini
# quit
# EOF


echo "Sync avec FTP externe" >&2 >> $logfile
$sync_ftp_cmd | tee -a $logfile

###
 # Change le template pour le host
###
host_template="Modele_NSCA"         # Host templates; for multiple definitions, use delimiter |

clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a settemplate -v "$host_name;$host_template"'
error_message=$(eval $clapi_cmd)

if [ ! $? ] ; then
	echo "Erreur CLAPI : impossible de definir le template" >&2
	exit 3
fi

clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o SERVICE -a del -v "$host_name;new_host_ack"'
error_message=$(eval $clapi_cmd)

if [ ! $? ] ; then
	echo "Erreur CLAPI : impossible de supprimer le service new_host_ack" >&2
	exit 3
fi

clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a applytpl -v "$host_name"'
error_message=$(eval $clapi_cmd)

if [ ! $? ] ; then
	echo "Erreur CLAPI : impossible de creer les modeles de services pour le host" >&2
	exit 3
fi

# Rechargement de la config Centreon
# Generation de la config centreon 'Central'
#
#
echo "Application de la config dans centreon..." >> $logfile

echo "Generer les fichiers de configuration" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERGENERATE -v 1)
if [ $? -eq 1 ] ; then
	# echo centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERGENERATE -v 1 | tee -a $logfile
    echo $error_message | tee -a $logfile
	echo "CLAPI : erreur generation => EXIT" | tee -a $logfile
	# printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 4
fi

echo "Lancer le debogage du moteur de supervision (-v)" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERTEST -v 1)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur test config => EXIT" | tee -a $logfile
	# printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 4
fi

echo "Deplacer les fichiers generes" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a CFGMOVE -v 1)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur deplacement des fichiers => EXIT" | tee -a $logfile
	# printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 4
fi

echo "Redemarrer l'ordonnanceur" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERRELOAD -v 1)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur reload => EXIT" | tee -a $logfile
	# printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 4
fi

echo "OK !" >> $logfile
