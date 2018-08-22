rem @echo off

REM MLT
REM 03/05/2018

REM Envoi la commande de decouverte au centreon
REM et modifie le fichier boot.ini pour aller chercher le fichier de conf intermediaire

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

set log_file="%temp%\%date:~-4%%date:~3,-5%%date:~0,2%-%time:~0,2%%time:~3,2%%time:~6,2%-new_host_hello.log"
set log_file=%log_file: =0%

GOTO :MAIN

:LOG_FUNC
call "%Work_Dir%\logging.bat" %log_file% %*
GOTO :EOF


:MAIN
REM Affichage des accents dans les logs
rem chcp 28591 > nul # PROVOQUE UN BUG POWERSHELL

SET http_temp_config_dir=http://monitoring.it-bs.fr/nsclient/config-temp

SETLOCAL EnableDelayedExpansion

REM Determine le nom dns complet et l'adresse IP
call :LOG_FUNC +++ Initialisation du nom dns complet et l adresse IP +++

for /f "usebackq tokens=6,7 delims= " %%i in (`ping -4 -n 1 %computername% ^| findstr /I %computername%`) do (
	set local_computername=%%i
	set "local_ip=%%j" && set local_ip=!local_ip:~1,-1!
)
for /f "tokens=1,* delims=." %%i in ("%local_computername%") do set local_dns=%%j

call :LOG_FUNC local_ip ^= -%local_ip%-
call :LOG_FUNC local_computername ^= -%local_computername%-
call :LOG_FUNC local_dns ^= -%local_dns%-

if "%local_ip%" == "" GOTO :IP_ERROR
if "%local_computername%" == "" GOTO :IP_ERROR
GOTO :IP_FOUND

:IP_ERROR
call :LOG_FUNC local_ip == '' ou local_computername == '' - Impossible de determiner l adresse IP ou le fqdn dans le ping - EXIT
"%ProgramFiles%\NSClient++\nscp" nsca "result=1" "alias=new_host_hello" "message=Erreur - Computername=%local_computername% IP=%local_ip%" >> "%log_file%" 2>&1
exit 1

:IP_FOUND
IF NOT "%local_dns%" == "" GOTO :DNS_FOUND
REM Cherche domaine pour l'IP trouvee avec ping
call :LOG_FUNC local_dns = '' - Le ping n a pas permis de determiner le suffixe dns
call :LOG_FUNC Tentative en powershell de determiner le suffixe DNS de l adresse IP trouvee avec ping
for /f "usebackq" %%i in (`powershell -noprofile -NonInteractive -ExecutionPolicy Bypass "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName . | Where-Object { $_.ipaddress -contains $env:local_ip }).dnsdomain"`) do (
	set local_dns=%%i
)
call :LOG_FUNC Powershell termine


IF NOT "%local_dns%" == "" GOTO :DNS_FOUND
REM Cherche domaine pour la 1ere adresse IP dont le domaine est non nul avec Gateway
call :LOG_FUNC local_dns = '' - L adresse renvoyee par ping n a pas de suffixe dns
call :LOG_FUNC Tentative en powershell de determiner le 1er suffixe DNS pour une carte avec une gateway
powershell "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter { IPEnabled = TRUE and DNSDomain ^!= NULL } -ComputerName . | Where-Object { $_.DefaultIPGateway.count -ne 0 }).dnsdomain" >> "%log_file%" 2>&1
for /f "usebackq" %%i in (`powershell -noprofile -NonInteractive -ExecutionPolicy Bypass "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter { IPEnabled = TRUE and DNSDomain ^!= NULL } -ComputerName . | Where-Object { $_.DefaultIPGateway.count -ne 0 }).dnsdomain"`) do (
	call :LOG_FUNC %%i
	if "%local_dns%" == "" (
		set local_dns=%%i
		call :LOG_FUNC Trouve
	)
)
call :LOG_FUNC Powershell termine

	
IF NOT "%local_dns%" == "" GOTO :DNS_FOUND
REM Cherche domaine pour la 1ere adresse IP dont le domaine est non nul sans Gateway
call :LOG_FUNC local_dns = '' - Pas de suffixe dns sur une carte avec une gateway. Recherche sur une carte sans gateway
call :LOG_FUNC Tentative en powershell de determiner le 1er suffixe DNS pour une carte sans une gateway
powershell "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter { IPEnabled = TRUE and DNSDomain ^!= NULL } -ComputerName .).dnsdomain" >> "%log_file%" 2>&1
for /f "usebackq" %%i in (`powershell -noprofile -NonInteractive -ExecutionPolicy Bypass "(Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter { IPEnabled = TRUE and DNSDomain ^!= NULL } -ComputerName .).dnsdomain"`) do (
	call :LOG_FUNC %%i
	if "%local_dns%" == "" (
		set local_dns=%%i
		call :LOG_FUNC Trouve
	)
)
call :LOG_FUNC Powershell termine
	

:DNS_FOUND
REM nom du PC fqdn
set local_computername=
call :LOG_FUNC local_dns trouve : -!local_dns!-
if "%local_dns%" == "" (
	set local_computername=%computername%
) else (
	set local_computername=%computername%.%local_dns%
)
call :LOG_FUNC Ajustement de local_computername en -%local_computername%-

:INIT_OK
REM debug
REM if not "%1" == "" set local_computername=%1
REM

call :LOG_FUNC +++ Initialisation terminee +++

call :LOG_FUNC +++ Test si boot.1st existe +++

if not exist '%ProgramFiles%\NSClient++\boot.ini' (
	call :LOG_FUNC Existe pas - 1er lancement
	REM Envoi du resultat
	"%ProgramFiles%\NSClient++\nscp" nsca "result=2" "message=%local_computername% %local_ip%" >> "%log_file%" 2>&1

	call :LOG_FUNC Creation du dossier scripts ITBS
	md "%ProgramFiles%\NSClient++\scripts\itbs" >> "%log_file%" 2>&1
		
	REM Modifie le boot.ini pour pointer vers le nsclient temporaire
	REM et test le resultat en meme temps
	REM Si 3 erreur, le fichier demande n'est pas disponible sur le site http alors on revient a la config initiale

	call :LOG_FUNC Rename du fichier boot.ini
	copy "%ProgramFiles%\NSClient++\boot.ini" "%ProgramFiles%\NSClient++\boot.1st" >> "%log_file%" 2>&1

	call :LOG_FUNC timeout 5
	timeout 5 >> "%log_file%" 2>&1
	
	call :LOG_FUNC Test si le nouveau fichier nsclient.ini est accessible : -%http_temp_config_dir%/%local_computername%-%local_ip%.ini-
	"%ProgramFiles%\NSClient++\nscp" settings --switch %http_temp_config_dir%/%local_computername%-%local_ip%.ini > "%temp%\nscp.log"

	call :LOG_FUNC Lecture du log -%temp%\nscp.log- a la recherche d erreurs
	set error=0
	FOR /F "usebackq" %%i in (`type "%temp%\nscp.log" ^| findstr "%local_computername%-%local_ip%.ini"`) DO (
		if "%%i" == "E" set /a error+=1 && call :LOG_FUNC error+=1
	)

	del /f "%temp%\nscp.log" >> "%log_file%" 2>&1

	call :LOG_FUNC Nombre d erreurs trouvee : -%error%-
	if /I %error% GEQ 1 (
		call :LOG_FUNC Il y a eu des erreurs, on revient en arriere en lisant le fichier initial
		for /F "usebackq tokens=1,* delims== " %%i in ("%ProgramFiles%\NSClient++\boot.1st") do (
			if "%%i" == "1" (
				set old_nsclient_ini=%%j
				call :LOG_FUNC Ancienne adresse de config trouvee dans boot.1st, on l applique en 1er choix: -!old_nsclient_ini!-
				rem goto :OLD_NSCLIENT_FOUND
			)
		)
	
		rem :OLD_NSCLIENT_FOUND
		if not "!old_nsclient_ini!" == "" (
			del /F "%ProgramFiles%\NSClient++\boot.ini" >> "%log_file%" 2>&1
			rename "%ProgramFiles%\NSClient++\boot.1st" boot.ini >> "%log_file%" 2>&1
			"%ProgramFiles%\NSClient++\nscp" settings --switch %old_nsclient_ini% >> "%log_file%" 2>&1
		) else (
			call :LOG_FUNC Pas trouve l ancienne adresse dans boot.1st a remettre en choix 1 - BUG
		)
	) else (
		call :LOG_FUNC Il n y a pas eu d erreur
	)
)

call :LOG_FUNC +++ Sortie de la config du boot.ini +++

rem "%ProgramFiles%\NSClient++\nscp" service --restart
rem schtasks /create /F /RU "NT AUTHORITY\SYSTEM" /SC MINUTE /MO 2 /DU 0:5 /TN "NSClient Service restart" /TR "cmd /c timeout 15 && 'c:\program files\NSClient++\nscp.exe' service --restart && schtasks /F /delete /TN 'NSClient++ Service restart'"
call :LOG_FUNC +++ Mise en place de la tache planifiee de reboot +++
:CALCUL_DATE
call :LOG_FUNC Calcul date. Les heures et minutes sont sans 0 devant
if /I %time:~3,2% LEQ 9 (set /a min=%time:~4,1%+3) else set /a min=%time:~3,2%+3
if /I %time:~0,2% LEQ 9 (set hour=%time:~1,1%) else set hour=%time:~0,2%
if /I %min% GEQ 60 set /a min-=60 && set /a hour+=1
call :LOG_FUNC calcul en cours ^: -%hour%:%min%- Si l heure sup a 24 on recommence dans 1 min
if /I %hour% GEQ 24 timeout 60 && GOTO :CALCUL_DATE
call :LOG_FUNC On remet un 0 devant une heure ou minute sur 1 chiffre
if /I %min% LEQ 9 set min=0%min%
if /I %hour% LEQ 9 set hour=0%hour%
set end_time=%hour%:%min%
call :LOG_FUNC end_time ^= -%end_time%-

set start_time=%time:~0,5%
set start_time=%start_time: =0%
call :LOG_FUNC start_time ^= -%start_time%-

call :LOG_FUNC Test si tache planifiee existe deja
schtasks /query /TN "NSClient++ Service restart" >> "%log_file%" 2>&1


if NOT %ERRORLEVEL% == 0 (
	call :LOG_FUNC Non - creation
	schtasks /create /RU "NT AUTHORITY\SYSTEM" /TN "NSClient++ Service restart" /SC ONCE /RI 1 /ST %start_time% /ET %end_time% /TR "cmd /c 'c:\program files\NSClient++\nscp.exe' service --restart" >> "%log_file%" 2>&1
) else (
	call :LOG_FUNC Oui - modification des heures de debut et fin
	schtasks /change /TN "NSClient++ Service restart" /SD %date% /ED %date% /ST %start_time% /ET %end_time% /RI 1 >> "%log_file%" 2>&1
)

rem call :LOG_FUNC +++ Tache planifiee parametree +++
if NOT %ERRORLEVEL% == 0 exit /b 1
