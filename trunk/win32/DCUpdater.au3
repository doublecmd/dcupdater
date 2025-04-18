#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=..\..\doublecmd.ico
#AutoIt3Wrapper_Outfile_x64=DCUpdater.exe
#AutoIt3Wrapper_Res_Comment=Double Commander Snapshot Updater
#AutoIt3Wrapper_Res_Description=Snapshot updater for Double Commander
#AutoIt3Wrapper_Res_Fileversion=1.5.1.0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>
#include <Date.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>

Local $workingDir = @ScriptDir & '/'
Local $iniFile = $workingDir & 'dcupdater.ini'
Const $NOT_FOUND = ""

;Load default settings
Local $logFile = IniRead($iniFile, 'General', 'LogFile', $NOT_FOUND)

LogW('Loading ini file settings: ' & $iniFile)
Local $postExec = IniRead($iniFile, 'General', 'PostExecution', "doublecmd --no-console")

LogW('Checking for doublecmd.exe/doublecmd')
If Not FileExists($workingDir & 'doublecmd.exe') And Not FileExists($workingDir & 'doublecmd') Then
	LogW('Could not find file: doublecmd.exe/doublecmd')
    okExit()
EndIf

Local $fileDoubleCommander = $workingDir & 'doublecmd.exe'
If Not FileExists($fileDoubleCommander) Then $fileDoubleCommander = $workingDir & 'doublecmd'

LogW('Checking write permissions on: ' & $fileDoubleCommander)
Local $fileAttributes = FileGetAttrib($fileDoubleCommander)
If StringInStr($fileAttributes, "R") Then
	LogW('File is read-only, probably already running: ' & $fileDoubleCommander)
	okExit()
EndIf

Local $update = IniRead($iniFile, 'General', 'Update', 'ask')

;Just exit if no update is necessary
If $update <> "yes" And $update <> "ask" Then
	LogW('Update is not "yes" or "ask": ' & $update)
	okExit()
EndIf

Const $currentDate = _NowCalcDate()

Local $architecture = IniRead($iniFile, 'General', 'Architecture', $NOT_FOUND)
Local $updateOnceADay = IniRead($iniFile, 'General', 'UpdateOnceADay', 'yes')
Local $lastRevision = IniRead($iniFile, 'General', 'LastUpdatedRevision', $NOT_FOUND)

Local $translationFile = IniRead($iniFile, 'General', 'TranslationFile', $NOT_FOUND)

Local $errorSupressInetRead = IniRead($iniFile, 'Error', 'SupressInetRead', "yes")

Local $updateSite = IniRead($iniFile, 'Internet', 'UpdateSite', 'https://doublecmd.sourceforge.io/snapshots/')
Local $regexGetRevision = IniRead($iniFile, 'Internet', 'RegExGetRevision', "(?mis)(\d+).*")
Local $doublecmdVersion = IniRead($iniFile, 'Internet', 'DoublecmdVersion', "doublecmd-1.2.0.r")

Local $deleteDownloadedFiles = IniRead($iniFile, 'Extract', 'DeleteDownloadedFiles', 'yes')

;Local $extractBZ2Command = IniRead($iniFile, 'Extract', 'BZ2', '7z x -y')
;Local $extractTARCommand = IniRead($iniFile, 'Extract', 'TAR', '7z x -y')
Local $extract7ZCommand = IniRead($iniFile, 'Extract', '7Z', '7z x -y')

;Create ini-file with defaults if first time
If Not FileExists($iniFile) Then
	promptSettings()

	LogW('Writing defaults to ini file: ' & $iniFile)
    IniWrite($iniFile, 'General', 'LogFile', $logFile)
	IniWrite($iniFile, 'General', 'Update', $update)
	IniWrite($iniFile, 'General', 'PostExecution', $postExec)
	IniWrite($iniFile, 'General', 'Architecture', $architecture)
	IniWrite($iniFile, 'General', 'UpdateOnceADay', $updateOnceADay)
	IniWrite($iniFile, 'General', 'LastUpdatedRevision', $lastRevision)

	IniWrite($iniFile, 'General', 'TranslationFile', $translationFile)

	IniWrite($iniFile, 'Error', 'SupressInetRead', $errorSupressInetRead)

	IniWrite($iniFile, 'Internet', 'UpdateSite', $updateSite)
	IniWrite($iniFile, 'Internet', 'RegExGetRevision', $regexGetRevision)
	IniWrite($iniFile, 'Internet', 'DoublecmdVersion', $doublecmdVersion)

	IniWrite($iniFile, 'Extract', 'DeleteDownloadedFiles', $deleteDownloadedFiles)
;	IniWrite($iniFile, 'Extract', 'BZ2', $extractBZ2Command)
;	IniWrite($iniFile, 'Extract', 'TAR', $extractTARCommand)
	IniWrite($iniFile, 'Extract', '7Z', $extract7ZCommand)
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

	IniWrite($iniFile, 'General', 'TranslationFile', $translationFile)
EndIf


;Return ok if already updated today
If $updateOnceADay == "yes" Then
	LogW('Update once a day')
	Local $lastUpdateDate = IniRead($iniFile, 'General', 'LastUpdateDate', $NOT_FOUND)

	$dateDiff = _DateDiff('d', $lastUpdateDate, $currentDate)
	$diffError = @error
	LogW('Comparing last update date "' & $lastUpdateDate & '" and "' & $currentDate & '" = ' & $dateDiff & ', @error = ' & $diffError)
	If $dateDiff < 1 And $diffError == 0 Then
		okExit()
	EndIf
EndIf

;Ask for architecture if not set
If $architecture == $NOT_FOUND Then
	LogW('Architecture setting not found. Creating architecture settings GUI')
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
	LogW('Show architecture settings GUI')
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
					$architecture = 'i386-win32'
				ElseIf BitAND(GUICtrlRead($radioWINx), $GUI_CHECKED) = $GUI_CHECKED Then
					$architecture = 'x86_64-win64'
				Else
					#Region --- CodeWizard generated code Start ---
					;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=None
					MsgBox(0,"ERROR","Strange error")
					#EndRegion --- CodeWizard generated code End ---
					okExit()
				EndIf

				LogW('Writing new architecture settings to ini file: ' & $architecture)
                IniWrite($iniFile, 'General', 'Architecture', $architecture)
				ExitLoop
			Case $cancelButton
				okExit()
		EndSwitch
	WEnd

	LogW('Deleting architecture settings GUI')
    GUIDelete($Form1_1)
EndIf

;Read snapshots site (HTML)
;$subPath = "arc/"
$subPath = ""
$revisionSite = $updateSite & $subPath & "revision.txt"
LogW('Reading update site: ' & $revisionSite)
Local $siteData = InetRead($revisionSite)
If $siteData == "" And @error Then
	LogW('[ERROR] Cannot read update site: ' & $revisionSite)
	If $errorSupressInetRead <> "yes" Then
		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
		MsgBox(16,"ERROR","Could not find update site:" & @CRLF & '"' & $revisionSite & '"')
		#EndRegion --- CodeWizard generated code End ---
	EndIf
	okExit()
EndIf

LogW('Converting site data to string')
$updateSiteString = BinaryToString($siteData)

LogW('Finding revision string using: ' & $regexGetRevision)
$currentRevision = StringRegExpReplace($updateSiteString, $regexGetRevision, "$1")

If StringIsInt($currentRevision) == 0 Then
	LogW('Found revision string is not a number: "' & $currentRevision & '"')
    okExit()
EndIf

;Check if update is necessary
LogW('Checking latest updated revision (last revision: ' & $lastRevision & ', remote revision: ' & $currentRevision & ')')
If $lastRevision <> $NOT_FOUND And StringIsInt($currentRevision) And StringIsInt($lastRevision) Then
	$cRevision = Number($currentRevision)
	$lRevision = Number($lastRevision)

	If $lastRevision == $cRevision Or $lastRevision > $cRevision Then
		IniWrite($iniFile, 'General', 'LastUpdateDate', $currentDate)
		okExit()
	EndIf
ElseIf $lastRevision <> $NOT_FOUND And $lastRevision <> "" Then
    LogW('[ERROR] Could not compare numbers')
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
;$tarFileName = $doublecmdVersion & $currentRevision & "." & $architecture & ".tar"
$changelogFileName = "changelog.txt"
$remoteFileName = $doublecmdVersion & $currentRevision & "." & $architecture & ".7z"
$changelogDownload = $updateSite & $subPath & $changelogFileName
$fileToDownload = $updateSite & $subPath & $remoteFileName


; ----------------------------------
;	Download change log
; ----------------------------------
LogW('Downloading changelog: ' & $changelogDownload)
Local $changelogText = ""
Local $changelogData = InetRead($changelogDownload, 1)
If @error Then
    LogW('[ERROR] Could not download changelog data')
Else
	$changelogText = BinaryToString($changelogData)
	$changelogText = StringRegExpReplace($changelogText, "\r?\n", @CRLF)
EndIf



; ----------------------------------
;	Download the file
; ----------------------------------
;Get file size
LogW('Checking remote file size (' & $fileToDownload & ')')
Local $remoteFileSize = InetGetSize($fileToDownload, 1)

LogW('Remote file size: ' & $remoteFileSize & ' [@error: ' & @error & ']')
If $remoteFileSize == 0 Then
	okExit()
EndIf

LogW('Creating GUI for status')
$StatusForm = GUICreate($tStatusFormTitle, 370, 385, 192, 114)
$descriptionLabel = GUICtrlCreateLabel($tStatusDownloadLabel & ": ", 8, 8, 72, 17)
$completeLabe = GUICtrlCreateLabel( $tStatusCompleteLabel & ":", 8, 32, 51, 17)
$cancelButton = GUICtrlCreateButton($tCancelButton, 144, 352, 75, 25, $WS_GROUP)
$completeLabel = GUICtrlCreateLabel("0 %", 88, 32, 250, 17)
$fileNameLabel = GUICtrlCreateLabel($remoteFileName, 88, 8, 250, 17)
$changelogLabel = GUICtrlCreateLabel($tChangelogLabel & ": ", 8, 56, 58, 17)
$changelogEdit = GUICtrlCreateEdit($changelogText, 8, 80, 353, 265, BitOR($ES_MULTILINE, $ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$ES_READONLY,$ES_WANTRETURN,$WS_HSCROLL,$WS_VSCROLL))

LogW('Show GUI for status')
GUISetState(@SW_SHOW)

;Start the download
Local $lastComplete = -1
LogW('Starting download: ' & $fileToDownload & ' -> ' & $remoteFileName)
$hDownload = InetGet($fileToDownload, $workingDir & $remoteFileName, 1, 1)
Do
	Local $downloadedBytes = InetGetInfo($hDownload, 0)
	Local $completed = Round($downloadedBytes / $remoteFileSize * 100)

	If $completed <> $lastComplete Then GUICtrlSetData($completeLabel, $completed & " %")
	$lastComplete = $completed

	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
            LogW('Window closed, canceling download.')
			InetClose($hDownload)
			GUIDelete($StatusForm)
			cleanUpDownload()
			okExit()

		Case $cancelButton
            LogW('Cancel pressed, canceling download.')
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
    LogW('[ERROR] Download error: ' & $downloadError)
	#Region --- CodeWizard generated code Start ---
	;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
	MsgBox(16,"ERROR","Could not download snapshot:" & @CRLF & '"' & $fileToDownload & '"')
	#EndRegion --- CodeWizard generated code End ---
	cleanUpDownload()
	okExit()
EndIf

LogW('File downloaded to: ' & $remoteFileName & ' (size: ' & $remoteFileSize & ')')

GUICtrlSetData($descriptionLabel, $tStatusExtractingLabel & ": ")
GUICtrlSetData($completeLabel, "0 %")

If $extract7ZCommand <> "" Then
	$extractCommand = $extract7ZCommand & ' ' & $remoteFileName
    LogW('Extracting 7z: ' & $extractCommand)
	$zExtracted = RunWait($extractCommand, @ScriptDir, @SW_HIDE)
	If $zExtracted == 0 And @error Then
		#Region --- CodeWizard generated code Start ---
		;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
		MsgBox(16,"ERROR","Could not execute command:" & @CRLF & $extractCommand)
		#EndRegion --- CodeWizard generated code End ---
		cleanUpDownload()
		okExit()
	EndIf

	GUICtrlSetData($completeLabel, "100 %")

;	If $extractTARCommand <> "" Then
;		$extractCommand = $extractTARCommand & ' ' & $tarFileName
;		If $logFile <> "" Then _FileWriteLog($workingDir & $logFile, 'Extracting tar: ' & $extractCommand)
;		$tarExtracted = RunWait($extractCommand, @ScriptDir, @SW_HIDE)
;		If $bz2Extracted == 0 And @error Then
;			#Region --- CodeWizard generated code Start ---
;			;MsgBox features: Title=Yes, Text=Yes, Buttons=OK, Icon=Critical
;			MsgBox(16,"ERROR","Could not execute command:" & @CRLF & $extractCommand)
;			#EndRegion --- CodeWizard generated code End ---
;			cleanUpDownload()
;			okExit()
;		EndIf
;	EndIf
EndIf

GUIDelete($StatusForm)

LogW('Writing to ini LastUpdateDate')
IniWrite($iniFile, 'General', 'LastUpdateDate', $currentDate)
IniWrite($iniFile, 'General', 'LastUpdatedRevision', $currentRevision)

cleanUpDownload()
okExit()

Func cleanUpDownload()
	If $deleteDownloadedFiles == "yes" Then
        LogW('Clean up downloaded files')

		If FileExists($workingDir & $remoteFileName) Then
            LogW('Removing file: ' & $remoteFileName)
			FileDelete($workingDir & $remoteFileName)
		EndIf

;		If FileExists($workingDir & $tarFileName) Then
;			If $logFile <> "" Then _FileWriteLog($workingDir & $logFile, 'Removing file: ' & $tarFileName)
;			FileDelete($workingDir & $tarFileName)
;		EndIf
	Else
        LogW('No clean up of downloaded files')
	EndIf
EndFunc

Func okExit()
	If $postExec <> "" Then
        LogW('PostExecuting: ' & $postExec)
		Run($postExec)
	EndIf

    LogW('******** Exiting script ********')
	Exit
EndFunc

Func promptSettings()
	$SettingsForm = GUICreate("DCUpdater Settings...", 458, 378, 192, 114)
	$Label1 = GUICtrlCreateLabel("Post Execution: ", 8, 282, 81, 17)
	$editPostExecution = GUICtrlCreateInput($postExec, 104, 280, 345, 21)
	GUICtrlSetTip(-1, "Command to execute when finishing this script")
	$Label2 = GUICtrlCreateLabel("Log file:", 8, 314, 41, 17)
	$Label3 = GUICtrlCreateLabel("Update:", 8, 10, 42, 17)
	$comboUpdate = GUICtrlCreateCombo("", 104, 8, 345, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
	GUICtrlSetData(-1, "yes|ask|no", $update)
	$Label5 = GUICtrlCreateLabel("Once a day:", 8, 72, 62, 17)
	$checkUpdateOnceADay = GUICtrlCreateCheckbox("Limit check for update to once a day", 104, 72, 345, 17)
	If $updateOnceADay == "yes" Then GuiCtrlSetState(-1, $GUI_CHECKED)
	$Label6 = GUICtrlCreateLabel("Translation:", 8, 100, 59, 17)
	$editTranslation = GUICtrlCreateInput($translationFile, 104, 98, 313, 21)
	$buttonBrowseTranslation = GUICtrlCreateButton("...", 424, 96, 27, 25, $WS_GROUP)
	$Label7 = GUICtrlCreateLabel("Update site:", 8, 130, 61, 17)
	$editUpdateSite = GUICtrlCreateInput($updateSite, 104, 128, 345, 21)
	$Label8 = GUICtrlCreateLabel("Regex revision:", 8, 162, 77, 17)
	$editRegexRevision = GUICtrlCreateInput($regexGetRevision, 104, 160, 345, 21)
	$Label9 = GUICtrlCreateLabel("Clean up:", 8, 192, 49, 17)
	$checkboxDelete = GUICtrlCreateCheckbox("&Delete downloaded files on exit", 104, 192, 345, 17)
	If $deleteDownloadedFiles == "yes" Then GuiCtrlSetState(-1, $GUI_CHECKED)
	$Label10 = GUICtrlCreateLabel("Extract 7Z:", 8, 218, 63, 17)
	$editExtract7z = GUICtrlCreateInput($extract7ZCommand, 104, 216, 345, 21)
	GUICtrlSetTip(-1, "Command for extracting 7Z file. Default value requires 7z in PATH")
;	$Label11 = GUICtrlCreateLabel("Extract TAR:", 8, 250, 65, 17)
;	$editExtractTar = GUICtrlCreateInput($extractTARCommand, 104, 248, 345, 21)
;	GUICtrlSetTip(-1, "Command for extracting TAR file. Default value requires 7z in PATH. Can be empty")
	$editLogFile = GUICtrlCreateInput($logFile, 104, 312, 345, 21)
	$buttonOk = GUICtrlCreateButton("&Ok", 376, 344, 75, 25, $WS_GROUP)
	$buttonCancel = GUICtrlCreateButton("&Cancel", 296, 344, 75, 25, $WS_GROUP)
	GUISetState(@SW_SHOW)
	#EndRegion ### END Koda GUI section ###

	Local $saveSettings = False
	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				okExit()
			Case $buttonBrowseTranslation
				Local $selectedFile = FileOpenDialog("Select translation file...", '', 'Translations (*.po)', 1)
				If Not @error Then GUICtrlSetData($editTranslation, $selectedFile)
			Case $buttonOk
				$saveSettings = True
				ExitLoop
			Case $buttonCancel
				okExit()
		EndSwitch
	WEnd

	If $saveSettings Then
		$postExec = GUICtrlRead($editPostExecution)
		$logFile = GUICtrlRead($editLogFile)
		$update = GUICtrlRead($comboUpdate)

		$tempCheckUpdate = GUICtrlRead($checkUpdateOnceADay)
		If $tempCheckUpdate Then $updateOnceADay = "yes"

		$translationFile = GUICtrlRead($editTranslation)
		$updateSite = GUICtrlRead($editUpdateSite)
		$regexGetRevision = GUICtrlRead($editRegexRevision)

		$tempDelete = GUICtrlRead($deleteDownloadedFiles)
		If $tempDelete Then $deleteDownloadedFiles = "yes"

;		$extractBZ2Command = GUICtrlRead($editExtractBz2)
;		$extractTARCommand = GUICtrlRead($editExtractTar)
		$extract7ZCommand = GUICtrlRead($editExtract7z)
	EndIf

	GUIDelete($SettingsForm)

EndFunc


; Write to log file
Func LogW(ByRef $msg)
    If $logFile <> "" Then _FileWriteLog($logFile, $msg)
EndFunc