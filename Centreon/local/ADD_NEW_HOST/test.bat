@echo off

for /f "usebackq" %%i in (`powershell "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter { IPEnabled = TRUE and DNSDomain != NULL } -ComputerName . | Where-Object { $_.DefaultIPGateway.count -ne 0 }).dnsdomain"`) do (
	echo %%i
)
