@echo off

REM MLT
REM 01/05/2018

REM Script qui place la configuration definitive pour nsclient++
REM en fonction des parametres recus


REM Usage : new_host_ack.bat <HTTP_FULL_PATH>
REM %1 : HTTP Full path to config file

SETLOCAL EnableDelayedExpansion


echo %date%-%time% > %temp%\new_host_ack.log
echo Lancement de new_host_ack... >> "%temp%\new_host_ack.log"
echo %* >> "%temp%\new_host_ack.log"

REM comptage parametres
set nb_params=0
for %%a in (%*) do set /a nb_params+=1

echo %nb_params% >> %temp%\new_host_ack.log
if not "%nb_params%" == "1" (
	echo Usage %0 ^<http_full_path^>
	echo Usage %0 ^<http_full_path^> >> "%temp%\new_host_ack.log"
	"%ProgramFiles%\NSClient++\nscp" nsca "result=1" "message=Erreur - Echec enregistrement : %date% %time%"
	exit 1
)

REM Remplacement du fichier boot.ini
echo [settings] > "%ProgramFiles%\NSClient++\boot.ini"
echo 1 = %1 >> "%ProgramFiles%\NSClient++\boot.ini"

echo OK - Mise a jour : done
echo OK - Mise a jour : done >> "%temp%\new_host_ack.log"


REM =========================================
REM Nettoyage des fichiers crees precedemment
REM =========================================
echo Nettoyage...  >> "%temp%\new_host_ack.log"

REM Nettoyage !
echo del /q /f "%ProgramFiles%\NSClient++\cache\*" > "%temp%\clean.bat"
echo del /q /f "%ProgramFiles%\NSClient++\scripts\custom\new_host_hello.bat*" >> "%temp%\clean.bat"
echo del /q /f "%ProgramFiles%\NSClient++\scripts\custom\logging.bat*" >> "%temp%\clean.bat"
echo del /q /f "%ProgramFiles%\NSClient++\scripts\itbs\new_host_ack.bat*" >> "%temp%\clean.bat"
echo del /q /f "%ProgramFiles%\NSClient++\boot.1st" >> "%temp%\clean.bat"
echo "%ProgramFiles%\NSClient++\nscp" nsca "result=0" "message=OK - Enregistrement reussi : %date% %time%" >> "%temp%\clean.bat"
echo exit /b 0 >> "%temp%\clean.bat"

:CALCUL_DATE
if /I %time:~3,2% LEQ 9 (set /a min=%time:~4,1%+20) else set /a min=%time:~3,2%+20
if /I %time:~0,2% LEQ 9 (set hour=%time:~1,1%) else set hour=%time:~0,2%
if /I %min% GEQ 60 set /a min-=60 && set /a hour+=1
if /I %hour% GEQ 24 timeout 60 && GOTO :CALCUL_DATE
if /I %min% LEQ 9 set min=0%min%
if /I %hour% LEQ 9 set hour=0%hour%
set end_time=%hour%:%min%


if exist "%ProgramFiles%\NSClient++\boot.1st" ( 
	call "%temp%\clean.bat"
	
	schtasks /query /TN "NSClient++ Service restart"
	if NOT %ERRORLEVEL% == 0 (
		schtasks /create /RU "NT AUTHORITY\SYSTEM" /TN "NSClient++ Service restart" /SC ONCE /RI 5 /ST %time:~0,5% /ET %end_time% /TR "cmd /c 'c:\program files\NSClient++\nscp.exe' service --restart" 2>&1
	) else (
		schtasks /change /TN "NSClient++ Service restart" /SD %date% /ED %date% /ST %time:~0,5% /ET %end_time% /RI 5 2>&1
	)
	if NOT %ERRORLEVEL% == 0 exit 1
)

exit 2