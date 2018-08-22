$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

$date = (Get-Date).AddDays(-1)

try
{
    $CritEvents = Get-WinEvent -ProviderName microsoft-windows-backup -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated -ge $date -and ($_.Level -eq 1 -or $_.Level -eq 2)}
    $CritNbEv = $CritEvents.Count
}
catch
{
}

try
{
    $WarnEvents = Get-WinEvent -ProviderName microsoft-windows-backup -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated -ge $date -and $_.Level -eq 3}
    $WarnNbEv = $WarnEvents.Count
}
catch
{
}

try
{
    $OkEvents = Get-WinEvent -ProviderName microsoft-windows-backup -ErrorAction SilentlyContinue | Where-Object {$_.TimeCreated -ge $date -and ($_.Level -eq 1 -or $_.Id -eq 4)}
    $OkNbEv = $OkEvents.Count
}
catch
{
	write-host $_.Exception.Message
	exit 2
}




if (($CritNbEv -eq $Null -and $CritEvents -eq $Null) -or $CritNbEv -eq 0)
{
$CritNbEv = 0
}
else
{
$CritNbEv = 1
}


if (($WarnNbEv -eq $Null -and $WarnEvents -eq $Null) -or $WarnNbEv -eq 0 )
{
    $WarnNbEv = 0
}
else
{
    $WarnNbEv = 1
}

if ($OkNbEv -eq $Null -and $OkEvents -eq $Null )
{
    $OkNbEv = 0
}
else
{
    $OkNbEv = 1
}



if ($CritNbEv -ne 0 ) {
    $message = "CRITICAL - Found {0} errors in Microsoft-Windows-Backup event log" -f $CritNbEv
    Write-Host $message
    exit $returnStateCritical
}

if ($WarnNbEv -ne 0) {
    $message = "WARNING - Found {0} warning in Microsoft-Windows-Backup event log" -f $WarnNbEv
    Write-Host $message
    exit $returnStateWarning
}

if ($OkNbEv -ne 0 ) {
    $message = "OK - No errors in Microsoft-Windows-Backup log "
    Write-Host $message
    exit $returnStateOK
}



Write-Host "UNKNOW - Not found backups events"
exit $returnStateUnknown
