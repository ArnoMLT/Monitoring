@echo off

REM MLT
REM 16/07/2019

REM Instale SNMP si besoin avant de lancer centreon_plugins.exe avec tous les parametres
call enable_snmp.bat >nul 2>&1
centreon_plugins.exe %*
