#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=..\..\doublecmd.ico
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Double Commander Snapshot Updater
#AutoIt3Wrapper_Res_Description=Snapshot updater for Double Commander
#AutoIt3Wrapper_Res_Fileversion=1.2
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <Date.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

Const $iniFileName = 'dcupdater.ini'
Const $NOT_FOUND = "NotFound"

;Load default settings
Local $logFile = IniRead($iniFileName, 'General', 'LogFile', '')

If $logFile <> "" Then _FileWriteLog($logFile, 'Loading ini file settings: ' & $iniFileName)
Local $fileDoubleCommander = IniRead($iniFileName, 'General', 'DoubleCommanderFile', "doublecmd.exe")
Local $postExec = IniRead($iniFileName, 'General', 'PostExecution', "doublecmd --no-console")

If $logFile <> "" Then _FileWriteLog($logFile, 'Checking write permissions on: ' & $fileDoubleCommander)
If Not FileExists($fileDoubleCommander) Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Could not find file: ' & $fileDoubleCommander)
	okExit()
EndIf

Local $fileAttributes = FileGetAttrib($fileDoubleCommander)
If StringInStr($fileAttributes, "R") Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'File is read-only, probably already running: ' & $fileDoubleCommander)
	okExit()
EndIf

Local $update = IniRead($iniFileName, 'General', 'Update', 'ask')

;Just exit if no update is necessary
If $update <> "yes" And $update <> "ask" Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Update is not "yes" or "ask": ' & $update)
	okExit()
EndIf

Const $currentDate = _NowCalcDate()

Local $architecture = IniRead($iniFileName, 'General', 'Architecture', $NOT_FOUND)
Local $updateOnceADay = IniRead($iniFileName, 'General', 'UpdateOnceADay', 'yes')
Local $lastRevision = IniRead($iniFileName, 'General', 'LastUpdatedRevision', $NOT_FOUND)

Local $translationFile = IniRead($iniFileName, 'General', 'TranslationFile', $NOT_FOUND)

Local $errorSupressInetRead = IniRead($iniFileName, 'Error', 'SupressInetRead', "yes")

Local $updateSite = IniRead($iniFileName, 'Internet', 'UpdateSite', 'http://www.firebirdsql.su/dc/')
Local $regexGetRevision = IniRead($iniFileName, 'Internet', 'RegExGetRevision', "(?mis).*?dcrevision\s+(\d+).*")

Local $deleteDownloadedFiles = IniRead($iniFileName, 'Extract', 'DeleteDownloadedFiles', 'yes')
Local $extractBZ2Command = IniRead($iniFileName, 'Extract', 'BZ2', '7z x -y')
Local $extractTARCommand = IniRead($iniFileName, 'Extract', 'TAR', '7z x -y')

;Create ini-file with defaults if first time
If Not FileExists($iniFileName) Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Writing defaults to ini file: ' & $iniFileName)
	IniWrite($iniFileName, 'General', 'LogFile', $logFile)
	IniWrite($iniFileName, 'General', 'Update', $update)
	IniWrite($iniFileName, 'General', 'DoubleCommanderFile', $fileDoubleCommander)
	IniWrite($iniFileName, 'General', 'PostExecution', $postExec)
	IniWrite($iniFileName, 'General', 'Architecture', $architecture)
	IniWrite($iniFileName, 'General', 'UpdateOnceADay', $updateOnceADay)
	IniWrite($iniFileName, 'General', 'LastUpdatedRevision', $lastRevision)

	IniWrite($iniFileName, 'General', 'TranslationFile', $translationFile)

	IniWrite($iniFileName, 'Error', 'SupressInetRead', $errorSupressInetRead)

	IniWrite($iniFileName, 'Internet', 'UpdateSite', $updateSite)
	IniWrite($iniFileName, 'Internet', 'RegExGetRevision', $regexGetRevision)

	IniWrite($iniFileName, 'Extract', 'DeleteDownloadedFiles', $deleteDownloadedFiles)
	IniWrite($iniFileName, 'Extract', 'BZ2', $extractBZ2Command)
	IniWrite($iniFileName, 'Extract', 'TAR', $extractTARCommand)
EndIf

;Load translations
Local $tOKButton = IniRead($translationFile, 'Translations', 'OkButton', "&Ok")
Local $tCancelButton = IniRead($translationFile, 'Translations', 'CancelButton', "&Cancel")

Local $tArchitectureFormTitle = IniRead($translationFile, 'Translations', 'ArchitectureFormTitle', "Select Architecture...")
Local $tArchitectureGroupTitle = IniRead($translationFile, 'Translations', 'ArchitectureGroupTitle', "Architecture")

Local $tStatusFormTitle = IniRead($translationFile, 'Translations', 'StatusFormTitle', "Status...")
Local $tStatusCompleteLabel = IniRead($translationFile, 'Translations', 'StatusCompleteLabel', "Complete")
Local $tStatusDownloadLabel = IniRead($translationFile, 'Translations', 'StatusDownloadLabel', "Downloading")
Local $tStatusExtractingLabel = IniRead($translationFile, 'Translations', 'StatusExtractLabel', "Extracting")
Local $tChangelogLabel = IniRead($translationFile, 'Translations', 'StatusChangelogLabel', "Changelog")

;If first time, store default translations
If $translationFile == $NOT_FOUND Then
	$translationFile = 'dcupdater.po'

	IniWrite($translationFile, 'Translations', 'OkButton', 					$tOKButton)
	IniWrite($translationFile, 'Translations', 'CancelButton', 				$tCancelButton)

	IniWrite($translationFile, 'Translations', 'ArchitectureFormTitle', 	$tArchitectureFormTitle)
	IniWrite($translationFile, 'Translations', 'ArchitectureGroupTitle', 	$tArchitectureGroupTitle)

	IniWrite($translationFile, 'Translations', 'StatusFormTitle', 			$tStatusFormTitle)
	IniWrite($translationFile, 'Translations', 'StatusCompleteLabel', 		$tStatusCompleteLabel)
	IniWrite($translationFile, 'Translations', 'StatusDownloadLabel', 		$tStatusDownloadLabel)
	IniWrite($translationFile, 'Translations', 'StatusExtractLabel', 		$tStatusExtractingLabel)

	IniWrite($iniFileName, 'General', 'TranslationFile', $translationFile)
EndIf


;Return ok if already updated today
If $updateOnceADay == "yes" Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Update once a day')
	Local $lastUpdateDate = IniRead($iniFileName, 'General', 'LastUpdateDate', $NOT_FOUND)

	$dateDiff = _DateDiff('d', $lastUpdateDate, $currentDate)
	$diffError = @error
	$logMessage = 'Comparing last update date "' & $lastUpdateDate & '" and "' & $currentDate & '" = ' & $dateDiff & ', @error = ' & $diffError
	If $logFile <> "" Then _FileWriteLog($logFile, $logMessage)
	If $dateDiff < 1 And $diffError == 0 Then
		okExit()
	EndIf
EndIf

;Ask for architecture if not set
If $architecture == $NOT_FOUND Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Architecture setting not found')
	If $logFile <> "" Then _FileWriteLog($logFile, 'Creating architecture settings GUI')
	$Form1_1 = GUICreate($tArchitectureFormTitle, 281, 227, 192, 114)
	$Group1 = GUICtrlCreateGroup($tArchitectureGroupTitle & ": ", 8, 8, 265, 177)
	$radioGTKi = GUICtrlCreateRadio("GTK2 [i386]", 24, 32, 113, 17)
	$radioGTKx = GUICtrlCreateRadio("GTK2 [x64]", 24, 56, 113, 17)
	$radioQTi = GUICtrlCreateRadio("QT [i386]", 24, 80, 113, 17)
	$radioQTx = GUICtrlCreateRadio("QT [x64]", 24, 104, 105, 17)
	$radioWINi = GUICtrlCreateRadio("Win [i386]", 24, 128, 105, 17)
	$radioWINx = GUICtrlCreateRadio("Win [x64]", 24, 152, 113, 17)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$okButton = GUICtrlCreateButton($tOKButton, 184, 192, 81, 25, $WS_GROUP)
	$cancelButton = GUICtrlCreateButton($tCancelButton, 104, 192, 73, 25, $WS_GROUP)
	If $logFile <> "" Then _FileWriteLog($logFile, 'Show architecture settings GUI')
	GUISetState(@SW_SHOW)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				okExit()

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

				If $logFile <> "" Then _FileWriteLog($logFile, 'Writing new architecture settings to ini file: ' & $architecture)
				IniWrite($iniFileName, 'General', 'Architecture', $architecture)
				ExitLoop
			Case $cancelButton
				okExit()
		EndSwitch
	WEnd

	If $logFile <> "" Then _FileWriteLog($logFile, 'Deleting architecture settings GUI')
	GUIDelete($Form1_1)
EndIf

;Read snapshots site (HTML)
If $logFile <> "" Then _FileWriteLog($logFile, 'Reading update site: ' & $updateSite)
Local $siteData = InetRead($updateSite)
If $siteData == "" And @error Then
	If $logFile <> "" Then _FileWriteLog($logFile, '[ERROR] Can not read update site: ' & $updateSite)
	If $errorSupressInetRead <> "yes" Then
		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
		MsgBox(16,"ERROR","Could not find update site:" & @CRLF & '"' & $updateSite & '"')
		#EndRegion --- CodeWizard generated code End ---
	EndIf
	okExit()
EndIf

If $logFile <> "" Then _FileWriteLog($logFile, 'Converting site data to string')
$updateSiteString = BinaryToString($siteData)

If $logFile <> "" Then _FileWriteLog($logFile, 'Finding revision string using: ' & $regexGetRevision)
$currentRevision = StringRegExpReplace($updateSiteString, $regexGetRevision, "$1")

If StringIsInt($currentRevision) == 0 Then
	If $logFile <> "" Then _FileWriteLog($logFile, 'Found revision string is not a number: "' & $currentRevision & '"')
	okExit()
EndIf

;Check if update is necessary
$logMessage = 'Checking latest updated revision (last revision: ' & $lastRevision & ', remote revision: ' & $currentRevision & ')'
If $logFile <> "" Then _FileWriteLog($logFile, $logMessage)
If $lastRevision <> $NOT_FOUND And StringIsInt($currentRevision) And StringIsInt($lastRevision) Then
	$cRevision = Number($currentRevision)
	$lRevision = Number($lastRevision)

	If $lastRevision == $cRevision Or $lastRevision > $cRevision Then
		IniWrite($iniFileName, 'General', 'LastUpdateDate', $currentDate)
		okExit()
	EndIf
ElseIf $lastRevision <> $NOT_FOUND And $lastRevision <> "" Then
	If $logFile <> "" Then _FileWriteLog($logFile, "[ERROR] Could not compare numbers")
	okExit()
EndIf

If $update == "ask" Then
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=Question, Timeout=10 ss
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(36,"DCUpdater","New snapshot (" & $currentRevision & ") is available!" & @CRLF & @CRLF & "Do you want to update?",10)
	Select
		Case $iMsgBoxAnswer = 6 ;Yes
			;Do nothing... continue with update
		Case $iMsgBoxAnswer = -1 ;Timeout
			;Do nothing... continue with update
		Case $iMsgBoxAnswer = 7 ;No
			okExit()
	EndSelect
	#EndRegion --- CodeWizard generated code End ---
EndIf


;Construct filenames
$tarFileName = "doublecmd.0.4.6.r" & $currentRevision & "." & $architecture & ".tar"
$changelogFileName = "doublecmd.0.4.6.r" & $currentRevision & ".last.change.txt"
$remoteFileName = $tarFileName & ".bz2"
$changelogDownload = $updateSite & $changelogFileName
$fileToDownload = $updateSite & $remoteFileName


; ----------------------------------
;	Download change log
; ----------------------------------
If $logFile <> "" Then _FileWriteLog($logFile, 'Downloading changelog: ' & $changelogDownload)
Local $changelogText = ""
Local $changelogData = InetRead($changelogDownload, 1)
If @error Then
	If $logFile <> "" Then _FileWriteLog($logFile, '[ERROR] Could not download changelog data')
Else
	$changelogText = BinaryToString($changelogData)
	$changelogText = StringRegExpReplace($changelogText, "\r?\n", @CRLF)
EndIf



; ----------------------------------
;	Download the file
; ----------------------------------
;Get file size
If $logFile <> "" Then _FileWriteLog($logFile, 'Checking remote file size (' & $fileToDownload & ')')
Local $remoteFileSize = InetGetSize($fileToDownload, 1)

If $logFile <> "" Then _FileWriteLog($logFile, 'Remote file size: ' & $remoteFileSize & ' [@error: ' & @error & ']')
If $remoteFileSize == 0 Then
	okExit()
EndIf

If $logFile <> "" Then _FileWriteLog($logFile, 'Creating GUI for status')
$StatusForm = GUICreate($tStatusFormTitle, 370, 385, 192, 114)
$descriptionLabel = GUICtrlCreateLabel($tStatusDownloadLabel & ": ", 8, 8, 72, 17)
$completeLabe = GUICtrlCreateLabel( $tStatusCompleteLabel & ":", 8, 32, 51, 17)
$cancelButton = GUICtrlCreateButton($tCancelButton, 144, 352, 75, 25, $WS_GROUP)
$completeLabel = GUICtrlCreateLabel("0 %", 88, 32, 250, 17)
$fileNameLabel = GUICtrlCreateLabel($remoteFileName, 88, 8, 250, 17)
$changelogLabel = GUICtrlCreateLabel($tChangelogLabel & ": ", 8, 56, 58, 17)
$changelogEdit = GUICtrlCreateEdit($changelogText, 8, 80, 353, 265, BitOR($ES_MULTILINE, $ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_READONLY,$ES_WANTRETURN,$WS_HSCROLL,$WS_VSCROLL))

If $logFile <> "" Then _FileWriteLog($logFile, 'Show GUI for status')
GUISetState(@SW_SHOW)

;Start the download
Local $lastComplete = -1
If $logFile <> "" Then _FileWriteLog($logFile, 'Starting download: ' & $fileToDownload & ' -> ' & $remoteFileName)
$hDownload = InetGet($fileToDownload, $remoteFileName, 1, 1)
Do
	Local $downloadedBytes = InetGetInfo($hDownload, 0)
	Local $completed = Round($downloadedBytes / $remoteFileSize * 100)

	If $completed <> $lastComplete Then GUICtrlSetData($completeLabel, $completed & " %")
	$lastComplete = $completed

	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			If $logFile <> "" Then _FileWriteLog($logFile, 'Window closed, canceling download.')
			InetClose($hDownload)
			GUIDelete($StatusForm)
			cleanUpDownload()
			okExit()

		Case $cancelButton
			If $logFile <> "" Then _FileWriteLog($logFile, 'Cancel pressed, canceling download.')
			InetClose($hDownload)
			GUIDelete($StatusForm)
			cleanUpDownload()
			okExit()
	EndSwitch

Until InetGetInfo($hDownload, 2)

; Check for download errors
Local $downloadError = InetGetInfo($hDownload, 4)
InetClose($hDownload)

If $downloadError <> 0 Then
	If $logFile <> "" Then _FileWriteLog($logFile, '[ERROR] Download error: ' & $downloadError)
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16,"ERROR","Could not download snapshot:" & @CRLF & '"' & $fileToDownload & '"')
	#EndRegion --- CodeWizard generated code End ---
	cleanUpDownload()
	okExit()
EndIf

If $logFile <> "" Then _FileWriteLog($logFile, 'File downloaded to: ' & $remoteFileName & ' (size: ' & $remoteFileSize & ')')

GUICtrlSetData($descriptionLabel, $tStatusExtractingLabel & ": ")
GUICtrlSetData($completeLabel, "0 %")

If $extractBZ2Command <> "" Then
	$extractCommand = $extractBZ2Command & ' ' & $remoteFileName
	If $logFile <> "" Then _FileWriteLog($logFile, 'Extracting bz2: ' & $extractCommand)
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

	If $extractTARCommand <> "" Then
		$extractCommand = $extractTARCommand & ' ' & $tarFileName
		If $logFile <> "" Then _FileWriteLog($logFile, 'Extracting tar: ' & $extractCommand)
		$tarExtracted = RunWait($extractCommand, @ScriptDir, @SW_HIDE)
		If $bz2Extracted == 0 And @error Then
			#Region --- CodeWizard generated code Start ---
			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
			MsgBox(16,"ERROR","Could not execute command:" & @CRLF & $extractCommand)
			#EndRegion --- CodeWizard generated code End ---
			cleanUpDownload()
			okExit()
		EndIf
	EndIf
EndIf

GUIDelete($StatusForm)

If $logFile <> "" Then _FileWriteLog($logFile, 'Writing to ini LastUpdateDate')
IniWrite($iniFileName, 'General', 'LastUpdateDate', $currentDate)
IniWrite($iniFileName, 'General', 'LastUpdatedRevision', $currentRevision)

cleanUpDownload()
okExit()

Func cleanUpDownload()
	If $deleteDownloadedFiles == "yes" Then
		If $logFile <> "" Then _FileWriteLog($logFile, 'Clean up downloaded files')

		If FileExists($remoteFileName) Then
			If $logFile <> "" Then _FileWriteLog($logFile, 'Removing file: ' & $remoteFileName)
			FileDelete($remoteFileName)
		EndIf

		If FileExists($tarFileName) Then
			If $logFile <> "" Then _FileWriteLog($logFile, 'Removing file: ' & $tarFileName)
			FileDelete($tarFileName)
		EndIf
	Else
		If $logFile <> "" Then _FileWriteLog($logFile, 'No clean up of downloaded files')
	EndIf
EndFunc

Func okExit()
	If $postExec <> "" Then
		If $logFile <> "" Then _FileWriteLog($logFile, 'PostExecuting: ' & $postExec)
		Run($postExec)
	EndIf

	If $logFile <> "" Then _FileWriteLog($logFile, 'Exiting script')
	Exit
EndFunc

