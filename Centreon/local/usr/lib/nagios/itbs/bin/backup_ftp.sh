#!/bin/sh

# Chargement de la config globale
source "/usr/lib/nagios/plugins/itbs/etc/config.cfg"

# Backup
rsync -va $path_to_nsclient_config/ $path_to_nsclient_config/../nsclient_backup
