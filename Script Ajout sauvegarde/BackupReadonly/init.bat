@echo off

REM MLT
REM v1.2
REM 16/08/2017

REM Script pour initialiser le fichier disks.ini
REM qui contient la signature hexa du disque sur lequel agir
REM et installer les taches planifiees


setlocal EnableDelayedExpansion

REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SET DiskList_Filename=disks.ini
SET DiskList_Path=%Work_Dir%\%DiskList_Filename%

SET ConfigFile_Path=%Work_Dir%\..\Monitoring\config.ini


:ListDisks
REM ============================================
REM Affichage de la liste des disques connectes
REM ============================================

CLS
REM SET "TAB=	"
SET /a NbDisk=-1
FOR /F "usebackq skip=2 tokens=2-4 delims=," %%i IN (`wmic diskdrive get index^,model^,size /format:csv`) DO (
REM    echo %%i%TAB%%%j%TAB%%%k
    SET /a NbDisk=!NbDisk! + 1

)
SET ListChoix=
FOR /L %%I IN (0,1,%NbDisk%) DO SET "ListChoix=!ListChoix!%%I"
REM SET ListChoix=%ListChoix:~1%

echo. list disk | diskpart

CHOICE /C "%ListChoix%" /M "Index du disque de sauvegarde"
IF "%ERRORLEVEL%" == "0"   GOTO :END
IF "%ERRORLEVEL%" == "255" GOTO :END

SET /A DiskID=%ERRORLEVEL%-1
rem SET /P "DiskID=Index du disque de sauvegarde (max %NbDisk%) : "


REM ==========================================
REM Affichage du detail du disque selectionne
REM ==========================================

set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%           > "%diskpart_script%"
echo detail disk                   >> "%diskpart_script%"

cls
diskpart /s "%diskpart_script%"
DEL "%diskpart_script%"

echo.
echo.
CHOICE /M "=====> OK "
IF "%ERRORLEVEL%" == "0"   GOTO :END
IF "%ERRORLEVEL%" == "255" GOTO :END
IF "%ERRORLEVEL%" == "2" GOTO :ListDisks


REM ===========================================================================
REM Creation script diskpart pour obtenir la signature hexa
REM car la signature extraite de wmic est convertie en decimal a l'aide
REM d'une fonction integree windows qui considere l'hexa signé codé sur 8 bits
REM ============================================================================

set diskpart_script=%Work_Dir%\%RANDOM%.tmp

echo select disk %DiskId%           > "%diskpart_script%"
echo uniqueid disk                 >> "%diskpart_script%"

FOR /F "usebackq skip=5 tokens=2 delims=:" %%I IN (`diskpart /s "%diskpart_script%"`) DO (
    set DiskSignature=%%I
    set DiskSignature=!DiskSignature:~1!
    echo DiskSignature [hex]=0x!DiskSignature!
rem     set /a DiskSignature=0x!DiskSignature!
rem     echo DiskSignature [dec]=!DiskSignature!
)
DEL "%diskpart_script%"


REM ======================================================
REM Sauvegarde de la signature dans le fichiers disks.ini
REM et prise en charge du module
REM ======================================================

echo disk1=%DiskSignature%> "%DiskList_Path%"
rem echo. >> "%ConfigFile_Path%"
echo backup-readonly=yes>> "%ConfigFile_Path%"

net stop wbengine

:End