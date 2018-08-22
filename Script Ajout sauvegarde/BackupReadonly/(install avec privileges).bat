@echo off

REM MLT
REM v1.2
REM 16/08/2017

REM Script d'installation / Mise a jour du module


setlocal EnableDelayedExpansion

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SET DiskList_Filename=disks.ini
SET DiskList_Path=%Work_Dir%\%DiskList_Filename%


REM On verifie si le fichier de conf existe
if not exist "%Work_Dir%\disks.ini" call "%Work_Dir%\init.bat"


REM ===================================
REM Installation des taches planifiees
REM ===================================

schtasks /delete /F /TN "Connect Backup" > nul 2>&1
schtasks /create /xml "%Work_Dir%\Connect-Backup.xml" /TN "Connect Backup"

schtasks /delete /F /TN "Disconnect Backup" > nul 2>&1
schtasks /create /xml "%Work_Dir%\Disconnect-Backup.xml" /TN "Disconnect Backup"

REM TEMP
call "%Work_Dir%\Connect-Backup.bat"

:End