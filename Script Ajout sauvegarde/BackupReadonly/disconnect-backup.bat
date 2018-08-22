@echo off

REM MLT
REM v1.2
REM 16/08/2017

REM Script pour mettre offline (ou en lecture-seule) le disque de backup


setlocal enableDelayedExpansion

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

REM Recuperation de l'ID du disk
CALL "%Work_Dir%\GetDiskId" DiskId

CALL :OfflineDisk %DiskId%

net stop wbengine

GOTO :END

REM ===========
REM  FONCTIONS
REM ===========

REM :OfflineDisk <DiskId>
REM Mettre offline le disk 

:OfflineDisk
rem if not defined %~1 GOTO:EOF

setlocal
set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%         > "%diskpart_script%"
echo offline disk                >> "%diskpart_script%"

diskpart /s "%diskpart_script%"
del "%diskpart_script%"

REM Creation d'un log dans l'observateur d'evt
set msg=La cible de sauvegarde Windows Backup est d‚connect‚e. Disk nø%DiskID%.

eventcreate /ID 1 /L Application /T Information /SO BackupReadonly /D "%msg%"

Endlocal
GOTO:EOF



REM :ReadonlyDisk <DiskId>
REM Mettre le disk en readonly

:ReadonlyDisk
rem if not defined %~1 GOTO:EOF

setlocal
set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%         > "%diskpart_script%"
echo attribute disk set readonly >> "%diskpart_script%"

diskpart /s "%diskpart_script%"
del "%diskpart_script%"

Endlocal
GOTO:EOF


REM =====
REM  FIN
REM =====

:END
endlocal
