@echo off

REM MLT
REM 25/06/2015
REM Permet de créer le fichier list.txt a déposer sur le serveur
REM qui contient la liste des fichiers a telecharger.
REM Tous les fichiers de cette liste doivent etre uploades sur le serveur.

del list.txt

for /f "delims=" %%i in ('dir /b')  do echo http://monitoring.it-bs.fr/%%i >> list.txt
