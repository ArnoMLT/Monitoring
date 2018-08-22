@echo off

REM MLT
REM 22/05/2018

REM fonction pour logger


SETLOCAL EnableDelayedExpansion

REM Parse arguments
REM %1 = chemin du fichier de log
REM %2 = message

set nb_params=0
for %%a in (%*) do set /a nb_params+=1

rem echo -%*-
rem echo -%nb_params%- parametres

if %nb_params% LEQ 1 (
	echo Usage incorrect.
	pause
	exit /b 1
)

REM %1 : file exists ?
if NOT EXIST "%1" (
rem	echo Le fichier -%1- n'exite pas.
	echo -= DEBUT DU FICHIER DE LOG =- > "%1"
rem	echo Creation de -%1-
	type "%1"
	if NOT %ERRORLEVEL% == 0 (
		echo Impossible de creer le fichier -%1-
		pause
		exit /b 1
	)
rem	echo OK
)

REM log du message
REM echo recuperation date derniere modification (avant ecriture)
REM set date_modif1=
REM for /f "usebackq skip=4 tokens=1,2" %%i in (`dir /tw "%1"`) DO (
	REM set date_modif1=%%i %%j
	REM GOTO :SUITE1
REM )

REM :SUITE1
REM echo -%date_modif1%- (avant ecriture)


REM message a logger
for /f "tokens=1,* delims= " %%a in ("%*") do set ALL_BUT_FIRST=%%b

rem echo Ecriture dans -%1- : %ALL_BUT_FIRST%
echo %time% - %ALL_BUT_FIRST%
echo %time% - %ALL_BUT_FIRST% >> "%1"


REM echo recuperation date derniere modification (apres ecriture)
REM set date_modif2=
REM for /f "usebackq skip=4 tokens=1,2" %%i in (`dir /tw "%1"`) DO (
	REM set date_modif2=%%i %%j
	REM GOTO :SUITE2
REM )

REM :SUITE2
REM echo -%date_modif1%- (avant ecriture)

REM if "%date_modif1%" == "%date_modif2%" (
	REM echo Ecriture impossible dans -%1-
	REM exit /B 1
REM )

rem echo OK
