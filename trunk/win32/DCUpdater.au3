#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=..\..\doublecmd.ico
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Date.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Const $iniFileName = 'dcupdater.ini'
Const $NOT_FOUND = "NotFound"

;Load default settings
Local $update = IniRead($iniFileName, 'General', 'Update', 'yes')
Local $postExec = IniRead($iniFileName, 'General', 'PostExecution', "doublecmd --no-console")

;Just exit if no update is necessary
If $update <> "yes" Then okExit()

Local $architecture = IniRead($iniFileName, 'General', 'Architecture', $NOT_FOUND)
Local $updateOnceADay = IniRead($iniFileName, 'General', 'UpdateOnceADay', 'yes')
Local $lastRevision = IniRead($iniFileName, 'General', 'LastUpdatedRevision', $NOT_FOUND)

Local $errorSupressInetRead = IniRead($iniFileName, 'Error', 'SupressInetRead', "yes")

Local $updateSite = IniRead($iniFileName, 'Internet', 'UpdateSite', 'http://www.firebirdsql.su/dc/')
Local $regexGetRevision = IniRead($iniFileName, 'Internet', 'RegExGetRevision', "(?mis).*?dcrevision\s+(\d+).*")

Local $deleteDownloadedFiles = IniRead($iniFileName, 'Extract', 'DeleteDownloadedFiles', 'yes')
Local $extractBZ2Command = IniRead($iniFileName, 'Extract', 'BZ2', '7z x -y')
Local $extractTARCommand = IniRead($iniFileName, 'Extract', 'TAR', '7z x -y')

;Create ini-file with defaults if first time
If Not FileExists($iniFileName) Then
	IniWrite($iniFileName, 'General', 'Update', $update)
	IniWrite($iniFileName, 'General', 'PostExecution', $postExec)
	IniWrite($iniFileName, 'General', 'Architecture', $architecture)
	IniWrite($iniFileName, 'General', 'UpdateOnceADay', $updateOnceADay)
	IniWrite($iniFileName, 'General', 'LastUpdatedRevision', $lastRevision)

	IniWrite($iniFileName, 'Error', 'SupressInetRead', $errorSupressInetRead)

	IniWrite($iniFileName, 'Internet', 'UpdateSite', $updateSite)
	IniWrite($iniFileName, 'Internet', 'RegExGetRevision', $regexGetRevision)

	IniWrite($iniFileName, 'Extract', 'DeleteDownloadedFiles', $deleteDownloadedFiles)
	IniWrite($iniFileName, 'Extract', 'BZ2', $extractBZ2Command)
	IniWrite($iniFileName, 'Extract', 'TAR', $extractTARCommand)
EndIf

;Return ok if already updated today
If $updateOnceADay == "yes" Then
	Local $lastUpdateDate = IniRead($iniFileName, 'General', 'LastUpdateDate', $NOT_FOUND)
	If _NowCalcDate() == $lastUpdateDate Then
		okExit()
	EndIf
EndIf


;Ask for architecture if not set
If $architecture == $NOT_FOUND Then
	#Region ### START Koda GUI section ### Form=c:\joel\doublecmdupdater\form1.kxf
	$Form1_1 = GUICreate("Select Architecture...", 281, 227, 192, 114)
	$Group1 = GUICtrlCreateGroup("Architecture: ", 8, 8, 265, 177)
	$radioGTKi = GUICtrlCreateRadio("GTK2 [i386]", 24, 32, 113, 17)
	$radioGTKx = GUICtrlCreateRadio("GTK2 [x64]", 24, 56, 113, 17)
	$radioQTi = GUICtrlCreateRadio("QT [i386]", 24, 80, 113, 17)
	$radioQTx = GUICtrlCreateRadio("QT [x64]", 24, 104, 105, 17)
	$radioWINi = GUICtrlCreateRadio("Win [i386]", 24, 128, 105, 17)
	$radioWINx = GUICtrlCreateRadio("Win [x64]", 24, 152, 113, 17)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$okButton = GUICtrlCreateButton("&Ok", 184, 192, 81, 25, $WS_GROUP)
	$cancelButton = GUICtrlCreateButton("&Cancel", 104, 192, 73, 25, $WS_GROUP)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				Exit

			Case $okButton
				If BitAND(GUICtrlRead($radioGTKi), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'gtk2.i386'
				ElseIf BitAND(GUICtrlRead($radioGTKx), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'gtk2.x86_64'
				ElseIf BitAND(GUICtrlRead($radioQTi), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'qt.i386'
				ElseIf BitAND(GUICtrlRead($radioQTx), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'qt.x86_64'
				ElseIf BitAND(GUICtrlRead($radioWINi), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'win32.i386'
				ElseIf BitAND(GUICtrlRead($radioWINx), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'win32.x86_64'
				Else
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=None
					MsgBox(0,"ERROR","Strange error")
					#EndRegion --- CodeWizard generated code End ---
					okExit()
				EndIf

				IniWrite($iniFileName, 'General', 'Architecture', $architecture)
				ExitLoop
			Case $cancelButton
				Exit
		EndSwitch
	WEnd

	GUIDelete($Form1_1)
EndIf

;Read snapshots site (HTML)
Local $siteData = InetRead($updateSite)
If $siteData == "" And @error Then
	If $errorSupressInetRead <> "yes" Then
		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
		MsgBox(16,"ERROR","Could not find update site:" & @CRLF & '"' & $updateSite & '"')
		#EndRegion --- CodeWizard generated code End ---
	EndIf
	okExit()
EndIf

$updateSiteString = BinaryToString($siteData)
ConsoleWrite("Revision: " & $updateSiteString & @CRLF)

$currentRevision = StringRegExpReplace($updateSiteString, $regexGetRevision, "$1")
ConsoleWrite("Revision: " & $currentRevision & @CRLF)

;Check if update is necessary
If $lastRevision <> $NOT_FOUND And IsNumber($currentRevision) And IsNumber($lastRevision) Then
	$cRevision = Number($currentRevision)
	$lRevision = Number($lastRevision)

	If $lastRevision == $cRevision Or $lastRevision > $cRevision Then
		TrayTip("DoubleCmd", "DoubleCmd already up to date (revision: " & $currentRevision & ")", 5, 1)
		okExit()
	EndIf
EndIf

;Construct filenames
$tarFileName = "doublecmd.0.4.6.r" & $currentRevision & "." & $architecture & ".tar"
$remoteFileName = $tarFileName & ".bz2"
$fileToDownload = $updateSite & $remoteFileName
ConsoleWrite("File name: " & $remoteFileName & @CRLF)

; ----------------------------------
;	Download the file
; ----------------------------------
;Get file size
Local $remoteFileSize = InetGetSize($fileToDownload, 1)
If $remoteFileSize == 0 Then
	okExit()
EndIf

#Region ### START Koda GUI section ### Form=C:\Joel\DoubleCmdUpdater\DownloadingForm.kxf
$StatusForm = GUICreate("Status", 368, 97, 192, 114)
$descriptionLabel = GUICtrlCreateLabel("Downloading: ", 8, 8, 72, 17)
$completeLabe = GUICtrlCreateLabel("Complete:", 8, 32, 51, 17)
$cancelButton = GUICtrlCreateButton("&Cancel", 144, 64, 75, 25, $WS_GROUP)
$completeLabel = GUICtrlCreateLabel("0 %", 88, 32, 21, 17)
$fileNameLabel = GUICtrlCreateLabel($remoteFileName, 88, 8, 211, 17)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;Start the download
$hDownload = InetGet($fileToDownload, $remoteFileName, 1, 1)
Do
	Sleep(250)
	Local $downloadedBytes = InetGetInfo($hDownload, 0)
	Local $completed = Round($downloadedBytes / $remoteFileSize * 100)

	GUICtrlSetData($completeLabel, $completed & " %")

	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			InetClose($hDownload)
			cleanUpDownload()
			okExit()

		Case $cancelButton
			InetClose($hDownload)
			cleanUpDownload()
			okExit()
	EndSwitch

Until InetGetInfo($hDownload, 2)

; Check for download errors
Local $downloadError = InetGetInfo($hDownload, 4)
InetClose($hDownload)

If $downloadError <> 0 Then
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16,"ERROR","Could not download snapshot:" & @CRLF & '"' & $fileToDownload & '"')
	#EndRegion --- CodeWizard generated code End ---
	cleanUpDownload()
	okExit()
EndIf

ConsoleWrite("Downloaded to: " & $remoteFileName & @CRLF)

GUICtrlSetData($descriptionLabel, "Extracting")
GUICtrlSetData($completeLabel, "0 %")

Local $extractCommand = $extractBZ2Command & ' ' & $remoteFileName
$bz2Extracted = RunWait($extractCommand, @ScriptDir, @SW_HIDE)
If $bz2Extracted == 0 And @error Then
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16,"ERROR","Could not execute command:" & @CRLF & $extractCommand)
	#EndRegion --- CodeWizard generated code End ---
	cleanUpDownload()
	okExit()
EndIf

GUICtrlSetData($completeLabel, "50 %")

$extractCommand = $extractTARCommand & ' ' & $tarFileName
$tarExtracted = RunWait($extractCommand, @ScriptDir, @SW_HIDE)
If $bz2Extracted == 0 And @error Then
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16,"ERROR","Could not execute command:" & @CRLF & $extractCommand)
	#EndRegion --- CodeWizard generated code End ---
	cleanUpDownload()
	okExit()
EndIf

GUIDelete($StatusForm)

IniWrite($iniFileName, 'General', 'LastUpdateDate', _NowCalcDate())
IniWrite($iniFileName, 'General', 'LastUpdatedRevision', $currentRevision)

cleanUpDownload()
okExit()

Func cleanUpDownload()
	If $deleteDownloadedFiles == "yes" Then
		If FileExists($remoteFileName) Then FileDelete($remoteFileName)
		If FileExists($tarFileName) Then FileDelete($tarFileName)
	EndIf
EndFunc

Func okExit()
	If $postExec <> "" Then Run($postExec)
	Exit
EndFunc

