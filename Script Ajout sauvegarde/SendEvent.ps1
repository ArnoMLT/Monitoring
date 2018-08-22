# ###############################################################################################
# Date : 02/08/2016
# Pgm  : MLT
# Version : 4.1.9
#
# Script powershell qui genere un appel a sendmail.ps1.
# Le corps du message sera le Message d'erreur de l'observateur d'evenement
# 
# =================
# Usage : sendevent.ps1 <Expéditeur> <Objet du mail> <LogEvent> <RecordID>
# =================
# ###############################################################################################

$Usage = "sendevent.ps1 <Expéditeur> <Objet du mail> <LogEvent> <RecordID>"
# Vérification des parametres du script
if ( $args.count -le 3 ){
    $Usage
    exit 1
}

# init des variables
$LogEvent = $args[2]
$RecordID = $args[3]
$message = ""

# debug
$message += "ProviderName : $LogEvent`r"
$message += "RecordID : $RecordID`r`r"

# Recuperation du message dans l'observateur d'evenement
$message += (Get-WinEvent -ProviderName $LogEvent | where-Object {$_.recordID -eq $RecordID}).Message.trim()

# Envoi du mail
sendmail.ps1 $args[0] $args[1] $message "High"