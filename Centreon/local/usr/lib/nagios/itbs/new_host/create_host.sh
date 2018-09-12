#!/bin/sh

# MLT
# 30/04/2018

# $1 = repertoire du script et ressources
# $2 = HOST
# $3 = Status submited
# $4 = nsca output

# 
#
# PHASE 2 :
# Creation du fichier nsclient.ini propre au PC
#	Soit a la racine de ftp_config_dir dans un dossier du nom du host_id centreon (si pas de domaine trouve dans le nom de machine)
#	Soit dans ftp_config_dir/domaine.local dans un dossier du nom nom du host_id centreon
#

# Chargement de la config globale
source "/usr/lib/nagios/plugins/itbs/etc/config.cfg"





now=`date +%s`

# chemins locaux
get_instance="$1/get_instance.sh"
ressource_nsclient_1="$1/ressources/nsclient.ini-phase1"		# fichier nsclient.ini modele utilise pendant la phase de decouverte
ressource_nsclient_2="$1/ressources/nsclient.ini-phase2"		# fichier nsclient.ini modele definitif a trouver chez les clients
ressource_clientini_2="$1/ressources/client.ini-phase2"		# fichier client.ini modele definitif a trouver chez les clients
local_nsclient_temp="/tmp/nsclient.ini-$now" 				# fichier de construction du nsclient.ini avant de l'envoyer sur le ftp

# chemins sur le FTP
# ftp_temp_config_dir='nsclient/config-temp'
relative_temp_config_dir='config-temp'
# ftp_config_dir='nsclient/config/clients'
relative_config_dir='config/clients'

# variables nsclient.ini
http_script_dir='http://monitoring.it-bs.fr/nsclient/scripts/itbs/new_host'
#http_temp_config_dir='http://monitoring.it-bs.fr/nsclient/config-temp'   # sera modifie plus loin
#http_config_file="http://monitoring.it-bs.fr/$ftp_config_dir"    # sera modifie plus loin
http_baseline_dir='http://monitoring.it-bs.fr/nsclient/config/baseline'
#http_client_dir=  # voir plus loin
centreon_distant_address='178.23.36.169'

# annulation des caracteres '/' pour les regex dans la suite du code
http_script_dir=$(echo $http_script_dir | sed -e 's/\//\\\//g')
http_temp_config_dir=$(echo $http_temp_config_dir | sed -e 's/\//\\\//g')
http_baseline_dir=$(echo $http_baseline_dir | sed -e 's/\//\\\//g')

logfile="/tmp/$now.log"



##	 			##
#   FONCTIONS  	 #
##				##

# Equivalent de mkdir -p sous linux
ftp_mkdir() {
	local chemin
	local rep
	chemin="$@"
	while [[ "$chemin" != "$rep" ]] ; do
        rep=${chemin%%/*}
        echo "mkdir $rep"
        echo "cd $rep"
        chemin=${chemin#*/}
    done
}



##	 			##
#     MAIN	  	 #
##				##

echo $* | tee -a $logfile

echo "Nb args : $#" >> $logfile
echo "arg1 : $1" >> $logfile
echo "arg2 : $2" >> $logfile
echo "arg3 : $3" >> $logfile
echo "arg4 : $4" >> $logfile


if [ $# -lt 4 ] ; then
	echo "Usage : $0 <SCRIPT_DIR> <HOST> <STATUS_PROCESSED> <NSCA_OUTPUT>" >&2 >>$logfile 2>&1
	echo "        SCRIPT_DIR : Chemin des fichiers du script" >&2 >>$logfile 2>&1
	echo "        HOST : Nom du host centreon qui recoit le message" >&2 >>$logfile 2>&1
	echo "        STATUS_PROCESSED : Statuts courant du host" >&2 >>$logfile 2>&1
	echo "        NSCA_OUTPUT : Contenu brut du message NSCA recu" >&2 >>$logfile 2>&1
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;Usage : $0 <HOST> <STATUS_PROCESSED> <NSCA_OUTPUT>" $now > $commandfile
    exit 1
fi

# Pas de notif sur reset status
case "$3" in
	"0")  # ok
		echo "STATUS_PROCESSED=0 (OK) => EXIT" >> $logfile
		rm -f $logfile
		exit 0
		;;
		
	"1")  # Pb a reporter
		echo "STATUS_PROCESSED=1 (NOK) => EXIT" >> $logfile
		exit 0
		;;
esac


# Split de NSCA_OUT	PUT
read -a nsca_output <<<$4

# Defintion du host
host_name=${nsca_output[0]}       		# Host name
host_alias=$host_name               	# Host alias
host_ip_address=${nsca_output[1]}   	# Host IP address
host_template="NEW_HOST_IMPORT_AUTO"    # Host templates; for multiple definitions, use delimiter |
instance_name="Central"             	# Instance name (poller)
host_group=""                       	# Hostgroup; for multiple definitions, use delimiter |

echo "host_name : $host_name" >> $logfile
echo "host_ip_address : $host_ip_address" >> $logfile

# Serveur central par defaut
poller_id=1

# Creation du nouveau host avec clapi
clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a ADD -v "$host_name;$host_alias;$host_ip_address;$host_template;$instance_name;$host_group"'
echo "Creation du host avec CLAPI..." >>$logfile 2>&1

#eval centreon_admin_password='xxxxxxxx' echo $clapi_cmd >>$logfile 2>&1
error_message=$(eval $clapi_cmd)

if [ $? -eq 1 ] ; then
	case "$error_message" in
	"Object already exists"*)
		echo "CLAPI : $error_message => Mise a jour du host" >> $logfile
		# renomme le host en suivant la casse (NSCA)
		clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a setparam -v "$host_name;name;$host_name"'
		echo "Renommage du host avec CLAPI..." >>$logfile 2>&1		
		error_message=$(eval $clapi_cmd)
		if [ $? -eq 1 ] ; then
			echo "CLAPI : erreur a la mise a jour => EXIT" >> $logfile
			printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
			exit 1
		fi
		
		
		# si on ajoute un template a la liste, il est en dernier
		# Mais NSCA doit etre en 1er sinon le host n'accepte pas les controles passifs
		echo "Mise a jour du host avec CLAPI..." >>$logfile 2>&1
		
		old_template=$(centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a gettemplate -v "$host_name" | tail -n +2 | cut -d ";" -f 2)
		
		clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a settemplate -v "$host_name;$host_template"'
		echo "Mise a jour du host avec CLAPI..." >>$logfile 2>&1
		error_message=$(eval $clapi_cmd)
		
		if [ $? -eq 1 ] ; then
			echo "CLAPI : erreur a la mise a jour => EXIT" >> $logfile
			printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
			exit 1
		fi
		
		for i in $old_template ; do
			clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a addtemplate -v "$host_name;$i"'
			echo "Ajout du template $i avec CLAPI..." >>$logfile 2>&1
			error_message=$(eval $clapi_cmd)
		
			if [ $? -eq 1 ] ; then
				echo "CLAPI : erreur a la mise a jour => EXIT" >> $logfile
				printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
				exit 1
			fi
		done

		clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a addtemplate -v "$host_name;$host_template"'
		echo "Mise a jour du host avec CLAPI..." >>$logfile 2>&1
		error_message=$(eval $clapi_cmd)
		
		if [ $? -eq 1 ] ; then
			echo "CLAPI : erreur a la mise a jour => EXIT" >> $logfile
			printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
			exit 1
		fi
		
		# Get poller ID
		poller_id=$($get_instance -u admin -p $centreon_admin_password -o "$host_name")
		
		host_update=true
	;;
	*)
		echo "CLAPI : erreur a l'import => EXIT" >> $logfile
		printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
		exit 1
	esac
fi

# Mise a jour des services du template
clapi_cmd='centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a applytpl -v "$host_name"'
echo "Mise a jour des services avec CLAPI..." >>$logfile 2>&1

error_message=$(eval $clapi_cmd)

if [ $? -eq 1 ] ; then
	echo "CLAPI : erreur a l'import des services => EXIT" >> $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 1
fi
	
# Get Centreon _HOST_ID
host_id=$(centreon -u $centreon_admin_user -p $centreon_admin_password -o HOST -a SHOW | sed -rn "s/^([0-9]+);$host_name;.*/\1/pI")
IFS=";" read -a host_id <<<$host_id
echo "HOST_ID = $host_id" >>$logfile


# Generation de la config centreon 'Central'
#
#
#echo "tempo 5 secondes..." >> $logfile

echo "Application de la config dans centreon..." >> $logfile

echo "Generer les fichiers de configuration" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERGENERATE -v $poller_id)
if [ $? -eq 1 ] ; then
	echo centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERGENERATE -v $poller_id | tee -a $logfile
    echo $error_message | tee -a $logfile
	echo "CLAPI : erreur generation => EXIT" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 3
else
	echo centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERGENERATE -v $poller_id | tee -a $logfile
    echo $error_message | tee -a $logfile
fi

echo "Lancer le debogage du moteur de supervision (-v)" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERTEST -v $poller_id)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur test config => EXIT" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 3
else
    echo $error_message | tee -a $logfile
fi

echo "Deplacer les fichiers generes" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a CFGMOVE -v $poller_id)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur deplacement des fichiers => EXIT" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 3
else
    echo $error_message | tee -a $logfile
fi

echo "Redemarrer l'ordonnanceur" >> $logfile
error_message=$(sudo -u apache centreon -u $centreon_admin_user -p $centreon_admin_password -a POLLERRELOAD -v $poller_id)
if [ $? -eq 1 ] ; then
	echo $error_message | tee -a $logfile
	echo "CLAPI : erreur reload => EXIT" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 3
else
    echo $error_message | tee -a $logfile
fi

echo "OK !" >> $logfile


# Generation des 2 fichiers nsclient.ini
#
# PHASE 1 : temp

# Definition des repertoires ftp du client
#host_court=${host_name%%.*}
host_domaine=${host_name#*.}

#ftp_temp_config_dir="$ftp_temp_config_dir/$host_name-$host_ip_address"
http_temp_config_dir="http://monitoring.it-bs.fr/nsclient/$relative_temp_config_dir"
http_temp_config_dir=$(echo $http_temp_config_dir | sed -e 's/\//\\\//g')

ftp_client_dir="nsclient/$relative_config_dir/$host_domaine"
http_client_dir="http://monitoring.it-bs.fr/$ftp_client_dir"
http_config_file="$http_client_dir/$host_id/nsclient.ini"
http_config_file=$(echo $http_config_file | sed -e 's/\//\\\//g')
http_client_dir2=$(echo $http_client_dir | sed -e 's/\//\\\//g')



echo "Phase 1 : Generation nsclient.ini"  | tee -a $logfile
echo "http_config_file = $http_config_file" >>$logfile

if [ ! -e $ressource_nsclient_1 ] ; then
	error_message="Le fichier $ressource_nsclient_1 n'existe pas"
	echo "$error_message" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 2
fi

# remplacements dans les templates
sed "s/@@HOSTNAME@@/$host_name/g" $ressource_nsclient_1 > $local_nsclient_temp
sed -i "s/@@HTTP_SCRIPTDIR@@/$http_script_dir/g" $local_nsclient_temp
sed -i "s/@@HTTP_CONFIGFILE@@/$http_config_file/g" $local_nsclient_temp

# copier le fichier vers le ftp (dossier temporaire)
echo "depose de nsclient.ini sur le FTP ($path_to_nsclient_config/$relative_temp_config_dir)" | tee -a $logfile

mkdir -p $path_to_nsclient_config/$relative_temp_config_dir
cp $local_nsclient_temp $path_to_nsclient_config/$relative_temp_config_dir/$host_name-$host_ip_address.ini
# ftp $ftp_site_addr <<EOF
# $(ftp_mkdir "nsclient/$relative_temp_config_dir")
# binary
# put $local_nsclient_temp $host_name-$host_ip_address.ini
# quit
# EOF

#rm -f $local_nsclient_temp
tempdir="/tmp"
mkdir -p $tempdir/nsclient/$relative_temp_config_dir
mv -f $local_nsclient_temp $tempdir/nsclient/$relative_temp_config_dir/$host_name-$host_ip_address.ini

#
#
# PHASE 2 : fichiers definitifs

if [ ! -e $ressource_clientini_2 ] ; then
	error_message="Le fichier $ressource_clientini_2 n'existe pas"
	echo "$error_message" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 2
fi

echo "Phase 2 : Generation client.ini" | tee -a $logfile


echo "http_client_dir = $http_client_dir" >>$logfile

# remplacements client.ini
if ! curl -sfI "$http_client_dir/client.ini" > /dev/null ; then
	echo "Le fichier $http_client_dir/client.ini n'existe pas : generation et copie FTP" | tee -a $logfile
	
	echo "Remplacements client.ini" | tee -a $logfile
	echo "host_name = $host_name" >>$logfile
	sed "s/@@HOSTNAME@@/$host_name/g" $ressource_clientini_2 > $local_nsclient_temp
	echo "http_script_dir = $http_script_dir" >>$logfile
	sed -i "s/@@HTTP_SCRIPTDIR@@/$http_script_dir/g" $local_nsclient_temp
	echo "http_config_file = $http_config_file" >>$logfile
	sed -i "s/@@HTTP_CONFIGFILE@@/$http_config_file/g" $local_nsclient_temp
	echo "http_baseline_dir = $http_baseline_dir" >>$logfile
	sed -i "s/@@HTTP_BASELINEDIR@@/$http_baseline_dir/g" $local_nsclient_temp
	echo "http_client_dir2 = $http_client_dir2" >>$logfile
	sed -i "s/@@HTTP_CLIENTDIR@@/$http_client_dir2/g" $local_nsclient_temp
	echo "centreon_distant_address = $centreon_distant_address" >>$logfile
	sed -i "s/@@CENTREON_DISTANT@@/$centreon_distant_address/g" $local_nsclient_temp

	# copier le fichier vers le ftp
	echo "depose de client.ini sur ($path_to_nsclient_config/$relative_config_dir/$host_domaine)" | tee -a $logfile
	
mkdir -p $path_to_nsclient_config/$relative_config_dir/$host_domaine
cp $local_nsclient_temp $path_to_nsclient_config/$relative_config_dir/$host_domaine/client.ini
	# ftp $ftp_site_addr <<EOF | tee -a $logfile 2>&1
# $(ftp_mkdir "$ftp_client_dir")
# binary
# put $local_nsclient_temp client.ini
# quit
# EOF

#	rm -f $local_nsclient_temp
mkdir -p $tempdir/$ftp_client_dir
mv -f $local_nsclient_temp $tempdir/$ftp_client_dir/client.ini



else
	echo "Le fichier $http_client_dir/client.ini existe : rien a faire" | tee -a $logfile
fi

# remplacements nsclient.ini
if [ ! -e $ressource_nsclient_2 ] ; then
	error_message="Le fichier $ressource_nsclient_2 n'existe pas"
	echo "$error_message" | tee -a $logfile
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;1;$error_message" $now > $commandfile
	exit 2
fi

echo "Remplacements nsclient.ini" | tee -a $logfile

sed "s/@@HOSTNAME@@/$host_name/g" $ressource_nsclient_2 > $local_nsclient_temp
sed -i "s/@@HTTP_SCRIPTDIR@@/$http_script_dir/g" $local_nsclient_temp
sed -i "s/@@HTTP_CONFIGFILE@@/$http_config_file/g" $local_nsclient_temp
sed -i "s/@@HTTP_BASELINEDIR@@/$http_baseline_dir/g" $local_nsclient_temp
sed -i "s/@@HTTP_CLIENTDIR@@/$http_client_dir2/g" $local_nsclient_temp
sed -i "s/@@CENTREON_DISTANT@@/$centreon_distant_address/g" $local_nsclient_temp

# copier le fichier vers le ftp
echo "depose de nsclient.ini sur le FTP ($path_to_nsclient_config/$relative_config_dir/$host_domaine/$host_id)" >>$logfile

mkdir -p $path_to_nsclient_config/$relative_config_dir/$host_domaine/$host_id
mv $path_to_nsclient_config/$relative_config_dir/$host_domaine/$host_id/nsclient.ini $path_to_nsclient_config/$relative_config_dir/$host_domaine/$host_id/nsclient.old
cp $local_nsclient_temp $path_to_nsclient_config/$relative_config_dir/$host_domaine/$host_id/nsclient.ini
# ftp $ftp_site_addr <<EOF
# $(ftp_mkdir "$ftp_client_dir/$host_id")
# binary
# rename nsclient.ini nsclient.old
# put $local_nsclient_temp nsclient.ini
# quit
# EOF

#rm -f $local_nsclient_temp
mkdir -p $tempdir/$ftp_client_dir/$host_id
mv -f $local_nsclient_temp $tempdir/$ftp_client_dir/$host_id/nsclient.ini


echo "Sync avec FTP externe" >&2 >> $logfile
$sync_ftp_cmd | tee -a $logfile

# Reset host status a ok
if [ "$host_update" == "true" ] ; then
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;0;Waiting... Derniere mise a jour : $host_name - `date +%c`" $now > $commandfile
else
	printf "[%lu] PROCESS_HOST_CHECK_RESULT;$2;0;Waiting... Dernier import : $host_name - `date +%c`" $now > $commandfile
fi
#rm -f $logfile