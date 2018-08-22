@echo off

REM MLT
REM v1.0
REM 12/07/2017

REM Fonction pour initialiser l'ID du disque
REM L'id du disque est retourné dans le 1er parametre

setlocal enableDelayedExpansion


REM Repertoire de travail
SET Work_Dir=%~d0%~p0
SET Work_Dir=%Work_Dir:~0,-1%

SET DiskList_Filename=disks.ini
SET DiskList_Path=%Work_Dir%\%DiskList_Filename%

set DiskID=-1

REM ===================
REM Fonction GetDiskId
REM ===================
if "%1" == "" (
    echo *** ERREUR *** GetDiskId : Usage GetDiskId <return_var>.
    GOTO:EOF
)


REM =============================================
REM Init de la signature du disque de sauvegarde
REM =============================================

set DiskSignatureHex=

if not exist "%DiskList_Path%" (
    REM 1er lancement ?

rem    set /P DiskSignatureHex="Signature du disque de sauvegarde : "
rem    echo disk1=!DiskSignatureHex!> "%DiskList_Path%"
    echo *** ERREUR  *** GetDiskId : Fichier %DiskList_Filename% introuvable.
    GOTO:EOF

) else (
    REM Lecture du fichier de conf

    for /F "tokens=1,2 usebackq delims==" %%v in ("%DiskList_Path%") do (
        if "%%v" == "disk1" (
            REM On a trouve !

            IF "%%w" == "" (
                echo *** ERREUR *** GetDiskId : Dans le fichier %DiskList_Filename%, la variable disk1 n'est pas initialisee.
                GOTO:EOF
            )

            set DiskSignatureHex=%%w
            goto :breakfor1
        ) else (
            echo *** ERREUR *** GetDiskId : Le fichier %DiskList_Filename% ne contient pas la variable disk1.
            GOTO:EOF
        )
    )
)
:breakfor1


REM Signature GPT ?
if "%DiskSignatureHex:~0,1%" == "{" if "%DiskSignatureHex:~-1%" == "}" GOTO :GetDiskIdGPT

:GetDiskIdMBR
REM ==============================================================
REM Recherche du numero du disque correspondant a la signature MBR
REM ==============================================================

REM == Pour wmic, la signature doit être en decimal       ==
REM == conversion à partir de la signature hex non signee ==

FOR /f "tokens=2 usebackq delims== " %%I in (`"%Work_Dir%\hex2dec.exe" 0x%DiskSignatureHex% -nobanner -accepteula`) DO set DiskSignature=%%I

REM == Lancement de la recherche ==

set DiskId=

FOR /f "usebackq skip=1" %%i IN (`wmic diskdrive where "signature=%DiskSignature%" get Index`) DO (
    SET DiskId=%%i
    GOTO :breakfor2
)
:breakfor2
goto :END


:GetDiskIdGPT
REM ==============================================================
REM Recherche du numero du disque correspondant a la signature GPT
REM ==============================================================
FOR /f "usebackq" %%i IN (`powershell -file "%Work_Dir%\GetDiskIdGPT.ps1" %DiskSignatureHex%`) DO (
    SET DiskId=%%i
)



REM =======
REM THE END
REM =======
:END
echo DiskId = %DiskId%
IF "%DiskId%" == "" (
    Echo *** ERREUR *** GetDiskId : Signature disk invalide.
    GOTO:EOF
)


ENDLOCAL & SET "%~1=%diskId%"
GOTO:EOF