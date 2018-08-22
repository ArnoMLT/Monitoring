@echo off

REM MLT
REM v1.2
REM 16/08/2017

REM Script pour remettre en lecture-ecriture le disque de backup 


setlocal enableDelayedExpansion

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

REM Recuperation de l'ID du disk
CALL "%Work_Dir%\GetDiskId" DiskId

CALL :OnlineDisk %DiskId%
CALL :ReadwriteDisk %DiskId%

GOTO :END

REM ===========
REM  FONCTIONS
REM ===========

REM :OnlineDisk <DiskId>
REM Mettre online le disk 

:OnlineDisk
rem if not defined %~1 GOTO:EOF

setlocal
set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%        > "%diskpart_script%"
echo online disk                >> "%diskpart_script%"

diskpart /s "%diskpart_script%"
del "%diskpart_script%"

REM Creation d'un log dans l'observateur d'evt
set msg=La cible de sauvegarde Windows Backup est connect‚e. Disk nø%DiskID%.

eventcreate /ID 2 /L Application /T Information /SO BackupReadonly /D "%msg%"

Endlocal
GOTO:EOF



REM :ReadwriteDisk <DiskId>
REM Mettre le disk en read-write

:ReadwriteDisk
rem if not defined %~1 GOTO:EOF

setlocal
set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%          > "%diskpart_script%"
echo attribute disk clear readonly >> "%diskpart_script%"

diskpart /s "%diskpart_script%"
del "%diskpart_script%"

Endlocal
GOTO:EOF


REM =====
REM  FIN
REM =====

:END
endlocal
