# ###############################################################################################
# Date : 02/07/2015
# Pgm  : MLT
# 
# Script powershell pour envoyer un mail.
# Les adresses mail de destination ne sont pas paramétrables : compte ovh par défaut
# -- V4 --
# */ Ajout d'un parametre pour gérer l'urgence du mail
# */ Cryptage du mot de passe dans un fichier annexe
#
# =================
# Usage : sendmail.ps1 <Expéditeur> <Objet du mail> [<Corps du mail> [Normal|High|Low]]
# =================
#
# Pour générer un nouveau fichier mot de passe : 
# $cred = Get-Credential
# $cred.Password | ConvertFrom-SecureString -key (3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5,35,43) | Set-Content .\encrypted_pass.txt
#
# ###############################################################################################

$Usage = "Usage : SendMail.ps1 <Expéditeur> <Objet du mail> [<Corps du mail> [Normal|High|Low]]"
# Vérification des parametres du script
if ( $args.count -le 1 ){
    $Usage
    exit 1
}




# init des variables
$expediteur = $args[0]
$SMTPAuthLogin = "monitoring.serveur%it-bs.fr"
$destinataire = "monitoring@it-bs.fr"
$serveur = "ssl0.ovh.net"
$priority = "normal"
#$fichier = "c:\temp\monfichier.txt"
$objet = "[" + $env:COMPUTERNAME + "] " + $args[1]

# modif encr pass
$encrypted = Get-Content .\encrypted_pass.txt | ConvertTo-SecureString -key (3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5,35,43)
$credential = New-Object System.Management.Automation.PsCredential($SMTPAuthLogin, $encrypted)
#

# traitement du parametre facultatif pour le script
if ( $args.Count -ge 3 ){
    $texte = $args[2]

    if ($args.Count -ge 4 ){
        if ( ($args[3] -match "^low$") -or ($args[3] -match "^normal$") -or ($args[3] -match "^high$") ){
            $priority = $args[3]
        } else {
            $Usage
            exit 1
        }
    }
} else {
    $texte = [System.DateTime]::Now
}

# Envoi du mail
$message = new-object System.Net.Mail.MailMessage $expediteur, $destinataire, $objet, $texte
$message.Priority = $priority

# Pour rajouter une piece jointe, décommenter les lignes suivantes
#$attachment = new-object System.Net.Mail.Attachment $fichier
#$message.Attachments.Add($attachment)

$SMTPclient = new-object System.Net.Mail.SmtpClient $serveur

$SMTPClient.Credentials = $credential
$SMTPClient.port = 587
$SMTPClient.EnableSsl = 1

$SMTPclient.Send($message)