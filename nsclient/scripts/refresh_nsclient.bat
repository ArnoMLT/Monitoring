@echo off

REM MLT
REM 25/06/2018

REM Cree ou met a jour une tache planifiee pour redemarrer le service nscp

setlocal enableDelayedExpansion

REM path pour le repertoire NSClient
set exe-bin=nscp.exe
set exe-path=%ProgramFiles%\NSClient++
set script-path=%exe-path%\scripts\itbs


REM 
REM Lecture des parametres
REM
set install=
for %%i in (%*) do (
	if /I "%%i" == "/install" set install=true
)

REM
REM Traitement des params
REM
if /I "%install%" == "true" GOTO :INSTALL
GOTO LAUNCH



REM ==========
REM FONCTIONS
REM ==========
:CALCUL_DATE
REM Calcul date. Les heures et minutes sont sans 0 devant
if /I %time:~3,2% LEQ 9 (set /a min=%time:~4,1%+%~1) else set /a min=%time:~3,2%+%~1
if /I %time:~0,2% LEQ 9 (set hour=%time:~1,1%) else set hour=%time:~0,2%
if /I %min% GEQ 60 set /a min-=60 && set /a hour+=1
REM Si l heure sup a 24 on recommence dans 1 min
if /I %hour% GEQ 24 timeout 60 && GOTO :CALCUL_DATE
REM On remet un 0 devant une heure ou minute sur 1 chiffre
if /I %min% LEQ 9 set min=0%min%
if /I %hour% LEQ 9 set hour=0%hour%
set start_time=%hour%:%min%

GOTO :EOF




REM =========
REM /install
REM =========
:INSTALL

REM initialise l'heure de début de la tache
call :CALCUL_DATE 1

schtasks /create /F /RU "NT AUTHORITY\SYSTEM" /TN "NSClient++ Service restart" /SC DAILY /MO 1 /ST %start_time% /TR "cmd /c '%~fnx0'" >NUL
set err_code=%ERRORLEVEL%

if %err_code% == 0 (
	rem echo OK: Restart planned (%time:~0,5%^)
	echo OK: Restart planned (%start_time%^)

) else (
	echo ERROR: Restart failed (%start_time%^)
)

if not %err_code% == 0 exit /b 2
exit /b 0



REM =======
REM launch
REM =======
:LAUNCH
start cmd /c "net stop nscp"
timeout 10


set "cmd=tasklist /NH /FI "imagename eq %exe-bin%" | find "%exe-bin%" /c"
for /f %%i in ('!cmd!') do set nb_nscp=%%i

rem if NOT "%ERRORLEVEL%" == "0" (
if %nb_nscp% GEQ 1 (
	taskkill /f /im %exe-bin%
	timeout 5
)

net start nscp
