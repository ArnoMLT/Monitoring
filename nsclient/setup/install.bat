@echo off

REM MLT
REM 15/06/2018
REM Last Update : 09/03/2019

REM Setup pour nscp avec parametrage sur http


REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SETLOCAL enableDelayedExpansion

REM Check si OS 32bits ou 64bits
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT

if %OS%==32BIT set NSCP_MSI=nscp-Win32.msi
if %OS%==64BIT set NSCP_MSI=nscp-x64.msi


REM MISE A JOUR
if exist "%ProgramFiles%\NSClient++\nscp.exe" (
	REM Sauvegarde des parametres
	if exist "%temp%\nscp" rd /s /q "%temp%\nscp"
	md "%temp%\nscp"
	xcopy /E /I "%ProgramFiles%\NSClient++\security" "%temp%\nscp\security"
	
	REM cherche si installation pilotee ou locale
	findstr /C:"1 = ini://${shared-path}/nsclient.ini" "%ProgramFiles%\NSClient++\boot.ini"
	if not !ERRORLEVEL! == 0 copy "%ProgramFiles%\NSClient++\boot.ini" "%temp%\nscp"
	
	REM Uninstall / Install
	"%ProgramFiles%\NSClient++\nscp.exe" service --stop
	for /F "usebackq skip=1" %%i IN (`wmic product where "name like '%%NSClient%%'" get IdentifyingNumber`) DO (
        if not "%%i"=="" (
            msiexec /x %%i /qb- /norestart REBOOT=ReallySuppress
        )
    )
	msiexec /i "%Work_Dir%\%NSCP_MSI%" /qb- /norestart REBOOT=ReallySuppress
	
	REM Mise en place des parametres sauvegardes
	del /f /q "%ProgramFiles%\NSClient++\boot.ini"
	del /F /Q "%ProgramFiles%\NSClient++\nsclient.ini"
	xcopy /E /I /C /R /Y "%temp%\nscp" "%ProgramFiles%\NSClient++"
	rd /S /Q "%temp%\nscp"
	

) else (
	REM NOUVELLE INSTALLATION

	msiexec /i "%Work_Dir%\%NSCP_MSI%" /qb- /norestart REBOOT=ReallySuppress

	del /f /q "%ProgramFiles%\NSClient++\boot.ini"
	del /f /q "%ProgramFiles%\NSClient++\nsclient.ini"
)

if not exist "%ProgramFiles%\NSClient++\boot.ini" (
	echo [Settings] > "%ProgramFiles%\NSClient++\boot.ini"
	echo 1 = http://monitoring.it-bs.fr/nsclient/config/nsclient.ini >> "%ProgramFiles%\NSClient++\boot.ini"
)

REM Application des parametres
"%ProgramFiles%\NSClient++\nscp.exe" service --restart