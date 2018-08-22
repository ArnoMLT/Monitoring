Param(
[Parameter(Mandatory=$True)][string]$DiskSignatureGPT
)


(get-disk | where-object {$_.guid -eq "$DiskSignatureGPT"}).number
