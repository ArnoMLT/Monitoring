#!/bin/sh

# Chargement de la config globale
source "/usr/lib/nagios/plugins/itbs/etc/config.cfg"

lftp -u $ftp_site_login,$ftp_site_password $ftp_site_addr -e "mirror --parallel=50 -e -R $path_to_nsclient_config/ nsclient/ ; quit"
