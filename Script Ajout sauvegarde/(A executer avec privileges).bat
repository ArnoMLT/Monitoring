@echo off

REM MLT
REM V5.0
REM 13/05/2018

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SETLOCAL enableDelayedExpansion


REM ===================================
REM Installation des taches planifiees
REM ===================================

set SrvName=
set WinBackup=


if not exist "%Work_Dir%\config.ini" (
    set /P SrvName="Entrez nom du serveur [serveur@domaine] : "

    REM Ecriture du fichier config.ini
    echo expediteur=!SrvName!> "%Work_Dir%\config.ini"

) else (
    REM Lecture du contenu de config.ini
    for /F "tokens=1,2 usebackq delims==" %%v in ("%Work_Dir%\config.ini") do (
        if "%%v" == "expediteur" (
            REM On a trouve !
            set SrvName=%%w
        )
        if "%%v" == "backup-readonly" (
            set WinBackup=%%w
            call :toLower WinBackup
        )
    )
)

REM Pas Trouvé la variable expediteur dans le fichier ?
if not defined SrvName goto :NO_EXP



REM Sendmail sur backup en echec
REM ----------------------------
set defautObjetEchec=Echec de la sauvegarde.

type "%Work_Dir%\Echec_head.xml" > "%Work_Dir%\Echec.xml"
echo "%SrvName%" \"%defautObjetEchec%\" \"$(ProviderName)\" \"$(EventRecordID)\" >> "%Work_Dir%\Echec.xml"
type "%Work_Dir%\Echec_tail.xml" >> "%Work_Dir%\Echec.xml"

schtasks /delete /F /TN "Sendmail sur backup en ‚chec" > nul 2>&1
schtasks /create /xml "%Work_Dir%\Echec.xml" /TN "Sendmail sur backup en ‚chec"
del "%Work_Dir%\Echec.xml"


REM Sendmail sur évènements importants
REM ----------------------------------
set defautObjetEchec=Alerte dans l'observateur d'évènements.

type "%Work_Dir%\Important_head.xml" > "%Work_Dir%\Important.xml"
echo "%SrvName%" \"%defautObjetEchec%\" \"$(ProviderName)\" \"$(EventRecordID)\" >> "%Work_Dir%\Important.xml"
type "%Work_Dir%\Important_tail.xml" >> "%Work_Dir%\Important.xml"

schtasks /delete /F /TN "Sendmail sur ‚vŠnements importants" > nul 2>&1
schtasks /create /xml "%Work_Dir%\Important.xml" /TN "Sendmail sur ‚vŠnements importants"
del "%Work_Dir%\Important.xml"


REM Sendmail sur évènements d'audit
REM -------------------------------
set defautObjetEchec=Alerte de sécurité.

type "%Work_Dir%\Audit_head.xml" > "%Work_Dir%\Audit.xml"
echo "%SrvName%" \"%defautObjetEchec%\" \"$(ProviderName)\" \"$(EventRecordID)\" >> "%Work_Dir%\Audit.xml"
type "%Work_Dir%\Audit_tail.xml" >> "%Work_Dir%\Audit.xml"

schtasks /delete /F /TN "Sendmail sur ‚vŠnements audit" > nul 2>&1
rem schtasks /create /xml "%Work_Dir%\Audit.xml" /TN "Sendmail sur ‚vŠnements audit"
del "%Work_Dir%\Audit.xml"


REM Tache planifiee de mise a jour auto
REM -----------------------------------
schtasks /delete /F /TN "Mise a jour monitoring iT-Bs" > nul 2>&1
schtasks /create /xml "%Work_Dir%\MiseAjour.xml" /TN "Mise a jour monitoring iT-Bs"


REM Compteur de performances
REM ------------------------
logman stop "Espace Disque (C)" > nul 2>&1
logman delete "Espace Disque (C)" > nul 2>&1

:: test si serveur exchange ou pas
if exist "C:\Program Files\Microsoft\Exchange Server" (
    logman import "Espace Disque (C)" -xml "%Work_Dir%\Space_Disk_C.xml"
    logman start "Espace Disque (C)"
)


REM Copie des fichiers Sendmail.ps1 et SendEvent.ps1
REM ------------------------------------------------
copy "%Work_Dir%\Sendmail.ps1" c:\windows
copy "%Work_Dir%\SendEvent.ps1" c:\windows
del "c:\windows\encrypted_pass.txt"


REM Copie des fichiers Monitoring dans c:\ITBS\monitoring lors de la 1ere installation
REM ----------------------------------------------------------------------------------
if NOT "%Work_Dir%" == "C:\ITBS\Monitoring" (
    xcopy /E /Y "%Work_Dir%\*" C:\ITBS\Monitoring\
    del "%Work_Dir%\config.ini"
)


REM Activation de l'execution des scripts powershell
REM ------------------------------------------------
powershell Set-ExecutionPolicy RemoteSigned


:BackupReadonly

REM Activation du module de deconnexion pour windows backup
REM -------------------------------------------------------
if "%WinBackup%" == "yes" (
    call "%Work_Dir%\..\BackupReadonly\(install avec privileges).bat"
)

:NSClient

REM Lancement du pgm d'installation de NSClient++
REM ---------------------------------------------
if exist "%Work_Dir%\..\nsclient\install.bat" (
	REM recupere la verion installee de nscp
	set vbs="%temp%\filever.vbs"
	set file="%ProgramFiles%\NSClient++\nscp.exe"
	echo Set oFSO ^= CreateObject("Scripting.FileSystemObject"^) > !vbs!
	echo WScript.Echo oFSO.GetFileVersion(WScript.Arguments.Item(0^)^) >> !vbs!
	for /f "tokens=*" %%a in ('cscript.exe //Nologo !vbs! !file!') do set filever=%%a
	del !vbs!
	
	REM recupere la version telechargee de nscp
	for /f %%i in (%Work_Dir%\..\nsclient\version.txt) do set installver=%%i
	
	REM install
	if not "!filever!" == "!installver!" call "%Work_Dir%\..\nsclient\install.bat"	
	
	rem del /s /q "%Work_Dir%\..\nsclient\NSCP-x64.old"
)

GOTO :END




REM =====================
REM     FONCTIONS
REM =====================

:toLower str -- converts uppercase character to lowercase
::           -- str [in,out] - valref of string variable to be converted
:$created 20060101 :$changed 20080219 :$categories StringManipulation
:$source http://www.dostips.com
if not defined %~1 EXIT /b
for %%a in ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i"
            "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r"
            "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z" "Ä=ä"
            "Ö=ö" "Ü=ü") do (
    call set %~1=%%%~1:%%~a%%
)
EXIT /b





REM ======
REM  FIN
REM ======


:NO_EXP
echo ERREUR : Le fichier config.ini ne contient pas la variable expediteur.

:END
if not defined auto pause