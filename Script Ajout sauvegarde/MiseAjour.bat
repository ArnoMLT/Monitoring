@echo off

REM 13/05/2018
REM MLT
REM v5.0
REM Module de mise a jour

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SETLOCAL enableDelayedExpansion

REM =======================
REM Mise a jour Monitoring
REM =======================

SET filelist="http://monitoring.it-bs.fr/list.txt"

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Work_Dir%" --no-check-certificate

REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Work_Dir%" -i "%Work_Dir%\list.txt"

REM Nettoyage des fichiers temporaires
del "%Work_Dir%\list.txt"


REM ===========================
REM Mise a jour BackupReadonly
REM ===========================

SET filelist="http://monitoring.it-bs.fr/BackupReadonly/list.txt"

if not exist "%Work_Dir%\..\BackupReadonly" md "%Work_Dir%\..\BackupReadonly"

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Work_Dir%\..\BackupReadonly" --no-check-certificate

REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Work_Dir%\..\BackupReadonly" -i "%Work_Dir%\..\BackupReadonly\list.txt"

REM Nettoyage des fichiers temporaires
del "%Work_Dir%\..\BackupReadonly\list.txt"


REM ==========
REM NSClient++
REM ==========

REM Lecture du contenu de config.ini
for /F "tokens=1,2 usebackq delims==" %%v in ("%Work_Dir%\config.ini") do (
	if "%%v" == "expediteur" (
		REM On a trouve !
		set SrvName=%%w
	)
)

SET filelist="http://monitoring.it-bs.fr/nsclient/list.txt"
if exist "%Work_Dir%\..\nsclient\install.bat" del /q /f "%Work_Dir%\..\nsclient\install.bat"

if not exist "%Work_Dir%\NSClientSrvToInstall.csv" GOTO :SCRIPT_LAUNCH

findstr /B /E /I "%SrvName%" "%Work_Dir%\NSClientSrvToInstall.csv"
if %ERRORLEVEL% == 0 (
	GOTO :NSCLIENT_SETUP
) else (
	REM extraction du nom de domaine
	for /f "tokens=1,2 delims=@" %%i in ("%SrvName%") do set DomainName=@%%j
	findstr /B /E /I "!DomainName!" "%Work_Dir%\NSClientSrvToInstall.csv"
	if !ERRORLEVEL! == 0 GOTO :NSCLIENT_SETUP
)

GOTO :SCRIPT_LAUNCH

:NSCLIENT_SETUP
if not exist "%Work_Dir%\..\nsclient" md "%Work_Dir%\..\nsclient"

REM TEMP 14/09/18
REM update tache restart
schtasks /change /TN "NSClient++ Service restart" /TR "cmd /c 'C:\Program Files\NSClient++\scripts\itbs\refresh_nsclient.bat'" >NUL
REM ---

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Work_Dir%\..\nsclient" --no-check-certificate

REM copie de nscp-x64.msi pour compraison future...
rem copy "%Work_Dir%\..\nsclient\NSCP-x64.msi" "%Work_Dir%\..\nsclient\NSCP-x64.old"
	
REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Work_Dir%\..\nsclient" -i "%Work_Dir%\..\nsclient\list.txt"

REM Nettoyage des fichiers temporaires
del "%Work_Dir%\..\nsclient\list.txt"
	

:SCRIPT_LAUNCH
REM =================================================
REM Lancement du script d'installation / mise a jour
REM =================================================
set auto=yes
call "%Work_Dir%\(A executer avec privileges).bat"
