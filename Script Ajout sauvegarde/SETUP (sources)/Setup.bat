@echo off

REM 30/05/2018
REM MLT
REM v5.0
REM Bootstrap pour installer le module de monitoring IT-BS

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SET Install_Dir=C:\ITBS\Monitoring

SETLOCAL enableDelayedExpansion

md "%Install_Dir%"

REM =======================
REM Mise a jour Monitoring
REM =======================

SET filelist="http://monitoring.it-bs.fr/list.txt"

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Install_Dir%" --no-check-certificate

REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Install_Dir%" -i "%Install_Dir%\list.txt"

REM Nettoyage des fichiers temporaires
del "%Install_Dir%\list.txt"


REM ===========================
REM Mise a jour BackupReadonly
REM ===========================

SET filelist="http://monitoring.it-bs.fr/BackupReadonly/list.txt"

if not exist "%Work_Dir%\..\BackupReadonly" md "%Install_Dir%\..\BackupReadonly"

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Install_Dir%\..\BackupReadonly" --no-check-certificate

REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Install_Dir%\..\BackupReadonly" -i "%Install_Dir%\..\BackupReadonly\list.txt"

REM Nettoyage des fichiers temporaires
del "%Install_Dir%\..\BackupReadonly\list.txt"

REM ==========
REM NSClient++
REM ==========

SET filelist="http://monitoring.it-bs.fr/nsclient/list.txt"
if exist "%Install_Dir%\..\nsclient\install.bat" del /q /f "%Install_Dir%\..\nsclient\install.bat"

if not exist "%Install_Dir%\..\nsclient" md "%Install_Dir%\..\nsclient"

REM Recupere la liste des fichiers à télécharger
"%Work_Dir%\wget" -N %filelist% -P "%Install_Dir%\..\nsclient" --no-check-certificate
	
REM Telecharge tous les fichiers de la liste
"%Work_Dir%\wget" -N -P "%Install_Dir%\..\nsclient" -i "%Install_Dir%\..\nsclient\list.txt"

REM Nettoyage des fichiers temporaires
del "%Install_Dir%\..\nsclient\list.txt"

REM =================================================
REM Lancement du script d'installation / mise a jour
REM =================================================
echo Lancement de : "%Install_Dir%\(A executer avec privileges).bat"
cd "%Install_Dir%"
set auto=yes
call "(A executer avec privileges).bat"


