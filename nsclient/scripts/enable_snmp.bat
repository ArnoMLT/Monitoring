@echo off

REM MLT
REM 16/07/2019

REM Installe, verifie et autorise snmp pour la communaute public

REM Test existance de la cle
REG QUERY HKLM\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities /v public

IF ERRORLEVEL 1 (
	REM Il manque la cle

	SC QUERY snmp	
	IF ERRORLEVEL 1 (
		REM snmp n'existe pas non plus
		dism /online /enable-feature /featurename:SNMP
		
		IF "%ERRORLEVEL%" == "0" (
			REM La fonctionnalite s'est correctement installee
			CALL :SNMP_PARAMS
		)
	) else (
		REM il manquait seulement la cle
		CALL :SNMP_PARAMS
	)
)

exit /B 0

:SNMP_PARAMS
reg add HKLM\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities /v public /t REG_DWORD /d 00000004
net stop snmp /yes & net start snmp & net start CqMgHost & net start CpqNicMgmt & net start CqMgServ & net start CqMgStor
