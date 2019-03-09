@echo off

REM 24/09/2018
REM Last update 09/03/2019
REM MLT
REM v5.1
REM Bootstrap pour installer le module de monitoring IT-BS


REM ==================
REM = MODE ELEVATION =
REM ==================

REM Verification des permissions
NET FILE >nul 2>&1

REM Erreur vous ne possedez pas les droits admin
if "%errorlevel%" NEQ "0" (
	echo Verification des privileges administrateur
	goto :UACPrompt
) else (
	goto :Admin
)

:UACPrompt
SET setup_dir=%CD%
cd /D %~dp0
echo Set UAC = CreateObject^("Shell.Application"^) >"%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~n0%~x0", "%~dp0", "", "runas", 1 >>"%temp%\getadmin.vbs"
call cscript "%temp%\getadmin.vbs"
pause
exit /B 0

:Admin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"
REM ================
REM = ELEVATION OK =
REM ================

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SET Install_Dir=C:\ITBS\Monitoring

SETLOCAL enableDelayedExpansion

md "%Install_Dir%"
copy "%Work_Dir%\config.ini" "%Install_Dir%\config.ini"

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

REM Telecharge la bonne version de NSCP (32 ou 64)
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
if %OS%==32BIT "%Work_Dir%\wget" -N "http://monitoring.it-bs.fr/nsclient/bin/NSCP-Win32.msi" -P "%Work_Dir%\..\nsclient" --no-check-certificate
if %OS%==64BIT "%Work_Dir%\wget" -N "http://monitoring.it-bs.fr/nsclient/bin/NSCP-x64.msi" -P "%Work_Dir%\..\nsclient" --no-check-certificate

REM Nettoyage des fichiers temporaires
del "%Install_Dir%\..\nsclient\list.txt"

REM =================================================
REM Lancement du script d'installation / mise a jour
REM =================================================
echo Lancement de : "%Install_Dir%\(A executer avec privileges).bat"
cd "%Install_Dir%"
set auto=yes
call "(A executer avec privileges).bat"


