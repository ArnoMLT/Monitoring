Option Explicit 

Function FindLastFile(Path)
    Dim fName
    Dim fDate
    
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    Dim folder
    Set folder = fso.GetFolder(Path)
    
    Dim Files
    Set Files = folder.Files

    Dim File
    For Each File In Files
        If File.DateCreated > fDate Then
            fDate = File.DateCreated
			'fDate = File.DateLastModified
            fName = File.Name
        End If
        'Debug.Print File.Name, File.DateCreated, "=>", fName, fDate
    Next
    
    Set Files = Nothing
    Set folder = Nothing
    Set fso = Nothing
	
	fName = Path + "\" + fName
	
    FindLastFile = fName

End Function


' Trouve le repertoire Program Files version x86
Function GetProgramFilesx86()
    Dim wshShell, strProgramFiles

    Set wshShell = CreateObject("WScript.Shell")
    strProgramFiles = wshShell.ExpandEnvironmentStrings("%PROGRAMFILES(x86)%")

    if strProgramFiles = "%PROGRAMFILES(x86)%" then
        strProgramFiles = wshShell.ExpandEnvironmentStrings("%PROGRAMFILES%")
    end if

    GetProgramFilesx86 = strProgramFiles
End Function


Const ForReading = 1
Const ForWriting = 2
Const TristateTrue = -1

Const TemporaryFolder = 2

Dim strCobianDir: strCobianDir = GetProgramFilesx86() + "\Cobian Backup 11"
Dim strCobianLogFile: strCobianLogFile = FindLastFile(strCobianDir + "\Logs")

'Dim strTempDir: strTempDir = WScript.CreateObject("Scripting.FileSystemObject").GetSpecialFolder(TemporaryFolder)
Dim strTempDir: strTempDir = "C:\Windows\Temp"
Dim strNsclientFile: strNsclientFile = strTempDir + "\cobian-monitoring.log"

'Dim WshShell: set WshShell = CreateObject("WScript.Shell")
' Leture du fichier de log en utf-16
Dim objFso: Set objFSO = CreateObject("Scripting.FileSystemObject")
Dim objFile: Set objFile = objFSO.OpenTextFile(strCobianLogFile, ForReading, False, TristateTrue)
Dim strContents: strContents = objFile.ReadAll
objFile.Close
set objFile = Nothing

' Ecriture
Dim objStream
Set objStream = CreateObject("ADODB.Stream")
objStream.CharSet = "utf-8"
objStream.Open
objStream.WriteText strContents
objStream.SaveToFile strNsclientFile, 2


' Ecriture du nouveau fichier de log dédié a nsclient
REM set objFile = objFSO.OpenTextFile(strNsclientFile, ForWriting, True, TristateTrue)
REM objFile.Write strContents
REM objFile.Close

set objFile = Nothing
set objFSO = Nothing
'set WshShell = Nothing
