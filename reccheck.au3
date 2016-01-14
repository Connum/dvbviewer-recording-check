#include <Array.au3>
#include <File.au3>
#include <Date.au3>
#include <IE.au3>
#include <_XMLDomWrapper.au3>

Dim $arrLogFile[1]

Global $RecordingPath = "C:\recordingpath\"
Global $DVBip = "127.0.0.1"
Global $DVBport = "8089"
Global $DVBVResponseXMLFile, $TimerIDtoRestart
Global $ResponseXMLpath = @ScriptDir & "\DVBVRecordMonitor.xml"
Global $DebugFile = @ScriptDir & "\RecordMonitor.txt"
Global $DVBViewerLogPath = "C:\ProgramData\CMUV\DVBViewer\svcdebug.log"
Dim $arrRecordingIndexes[1], $arrRecordingTimerIDs[1]
Global $FoundRecording = False, $RestartRecording = False, $TimeStampFound = False
Global $DebugMode = False
Global $DebugTimerFileName = "The Hunt - 2 7. In the Grip of the Seasons (Arctic)_BBC Two HD_2015.11.25_01-07-02"

$arrCompleteRecordings = _FileListToArray($RecordingPath, "*.ts")

If $arrCompleteRecordings = 0 Then
	$CompleteRecordingCount = 0
Else
	;_ArrayDisplay($arrCompleteRecordings)
	$CompleteRecordingCount = $arrCompleteRecordings[0]
EndIf
_Log("Monitor started...")
;_ArrayDisplay($arrCompleteRecordings)

;~ _ArrayDelete($arrCompleteRecordings, 11)
;~ $CompleteRecordingCount = $CompleteRecordingCount-1
;~ _ArrayDisplay($arrCompleteRecordings)

While 1

	;_Log("Checking recordings....")

	$arrRecordings = _FileListToArray($RecordingPath, "*.ts")

	;_ArrayDisplay($arrRecordings)

	If $arrRecordings = 0 Then
		$NewRecordingCount = 0
	Else
		$NewRecordingCount = $arrRecordings[0]
	EndIf

;~ 	For $i = 1 to uBound($arrRecordings)-1
;~ 		_Log("Found recording: " & $arrRecordings[$i])
;~ 	Next

	;_Log("New recording count: " & $arrRecordings[0] & " vs old: " & $CompleteRecordingCount)

	If $NewRecordingCount <> $CompleteRecordingCount or $DebugMode Then

		If $DebugMode Then
			_RestartRecording()
			Exit
		EndIf

		_Log("Recording count changed...")

		For $x = 1 to uBound($arrRecordings)-1

			$d = _ArraySearch($arrCompleteRecordings, $arrRecordings[$x])

			If $d = -1 Then

				_Log("Found new recording: " & $arrRecordings[$x])

				$arrNewRecTimeStamp = FileGetTime($RecordingPath & "\" & $arrRecordings[$x])

				If $arrNewRecTimeStamp = 0 Then

					_Log("Failed to get file modified time, retrying...")

					$Timer = 0

					While 1

						If $Timer > 30 then
							ExitLoop
						EndIf

						$arrNewRecTimeStamp = FileGetTime($RecordingPath & "\" & $arrRecordings[$x])

						If $arrNewRecTimeStamp <> 0 then
							$TimeStampFound = True
							ExitLoop
						EndIf

						Sleep(2000)

						$Timer = $Timer + 2

					WEnd

				Else
					$TimeStampFound = True
				EndIf

				If $TimeStampFound Then

					$NewRecTimeStamp = $arrNewRecTimeStamp[0] & "/" & $arrNewRecTimeStamp[1] & "/" & $arrNewRecTimeStamp[2] & " " & $arrNewRecTimeStamp[3] & ":" & $arrNewRecTimeStamp[4] & ":" & $arrNewRecTimeStamp[5]

					$RecordingAge = _DateDiff("s", $NewRecTimeStamp,  _NowCalc())
					_Log("Recording is " & $RecordingAge & " seconds old...")



					If $RecordingAge < 120 then Sleep(60000)

					$LogFileToCheck = $RecordingPath & "\" & StringReplace($arrRecordings[$x], ".ts", ".log")
					_Log("Log file: " & $LogFileToCheck)

					$Timer = 0
					$ErrorCount = 0

					While 1

						If $Timer > 30 then ExitLoop

						$OpenLog = _FileReadToArray($LogFileToCheck,$arrLogFile)

						If $OpenLog = 1 then

							For $y = 1 to uBound($arrLogFile)-1
								If StringInStr($arrLogFile[$y], "Errors") Then
									$ErrorCount = $ErrorCount+1
								EndIf
							Next

							ExitLoop

						Else
							_Log("Couldn't access log retrying...")
							Sleep(3000)
							$Timer = $Timer + 1
						EndIf

					WEnd

					_Log("Detected " & $ErrorCount & " occurances of errors")

					If $ErrorCount > 2 Then
						_RestartRecording()
					Else
						_Log("Less than 2 errors detected, leaving this recording.")
					EndIf

					$TimeStampFound = False

				Else
					_Log("Couldn't get file modified time, skipping this recording...")
				EndIf

				_ArrayAdd($arrCompleteRecordings,$arrRecordings[$x])
				$CompleteRecordingCount = $CompleteRecordingCount+1
				$arrRecordings[0] = $arrRecordings[0]+1

			EndIf
		Next

		;Nmber of recordings has decreased so let check run above in case a recording has started AND files(s) have been deleted then set recording count to new, lower value.
		If $arrRecordings[0] < $CompleteRecordingCount Then
			_Log("Recording count decreased")
			$CompleteRecordingCount = $arrRecordings[0]
		EndIf

	EndIf

	Sleep(60000)

WEnd

Func _RestartRecording()

	_Log("Attempting to restart the recording...")
	ReDim $arrRecordingIndexes[1]
	$FoundRecording = False

	FileDelete($ResponseXMLpath)

	$oResponse = InetGet("http://" & $DVBip & ":" & $DVBport & "/api/timerlist.html",$ResponseXMLpath,1,1)

	Do
		Sleep(250)
	Until InetGetInfo($oResponse, 2) ; Check if the download is complete.


	If FileExists($ResponseXMLpath) and $oResponse <> 0 Then

		$PchResponseXMLFile = _XMLFileOpen($ResponseXMLpath, "", -1, False)

		$TimerRecStatus = _XMLGetValue ( "//Timers/Timer/Recording" )
		$TimerIDs = _XMLGetValue ( "//Timers/Timer/ID" )

;~ 		If IsArray($TimerRecStatus) Then
;~ 			_ArrayDisplay($TimerRecStatus)
;~ 			_ArrayDisplay($TimerIDs)
;~ 		EndIf

		For $g = 1 to uBound($TimerRecStatus)-1
			If $TimerRecStatus[$g] = -1 Then
				$FoundRecording = True
				_Log("Found a live recording in the Timers XML at index " & $g)
				_ArrayAdd($arrRecordingIndexes, $g)
			EndIf

		Next

		;_ArrayDisplay($arrRecordingIndexes, "Array Recording Indexes")

		If $FoundRecording Then
			For $h = 1 to uBound($arrRecordingIndexes)-1
				$TimerFileName = _XMLGetValue ( "//Timers/Timer[" & $arrRecordingIndexes[$h] & "]/RealFilename" )
				_Log("Recording filename: " & $TimerFileName[1])
				;_ArrayDisplay($TimerFileName, "$TimerFileName")

				If $DebugMode Then
					If $TimerFileName[1] = $RecordingPath & "\" & $DebugTimerFileName Then
						_Log("Recording filename matches the one we are debugging...")
						$TimerIDtoRestart = $TimerIDs[$arrRecordingIndexes[$h]]
						ReDim $arrRecordingTimerIDs[$h][2]
						$arrRecordingTimerIDs[$h-1][0] = $TimerIDs[$arrRecordingIndexes[$h]]
						$arrRecordingTimerIDs[$h-1][1] = $TimerFileName[1]
						$RestartRecording = True
					EndIf

				Else

					If $TimerFileName[1] = $RecordingPath & "\" & $arrRecordings[$x] Then
						_Log("Recording filename matches the one reporting errors...")
						$TimerIDtoRestart = $TimerIDs[$arrRecordingIndexes[$h]]
						ReDim $arrRecordingTimerIDs[$h][2]
						$arrRecordingTimerIDs[$h-1][0] = $TimerIDs[$arrRecordingIndexes[$h]]
						$arrRecordingTimerIDs[$h-1][1] = $TimerFileName[1]
						$RestartRecording = True

					Else
						_Log("Recording filename does not match the one reporting errors...")
						_Log("Reported errors: " & $RecordingPath & "\" & $arrRecordings[$x])
						_Log("Recording found in xml: " & $TimerFileName[1])
					EndIf

				EndIf

			Next

			;_ArrayDisplay($arrRecordingTimerIDs, "Final Timer IDs")

			If $RestartRecording Then

				_Log("Restarting the recording...")

				$IEInstance = _IECreate("http://" & $DVBip & ":" & $DVBport & "/api/timeredit.html?id=" & $TimerIDtoRestart & "&enable=0")
				_IEQuit($IEInstance)

				Sleep(20000)

				$IEInstance = _IECreate("http://" & $DVBip & ":" & $DVBport & "/api/timeredit.html?id=" & $TimerIDtoRestart & "&enable=1")
				_IEQuit($IEInstance)

				$RestartRecording = False
				_Log("Restart attempt complete")
				$TimerIDtoRestart = 0

			EndIf

		EndIf

	EndIf

EndFunc

Func _Log($logstring)
	FileWriteLine($DebugFile, "[" & _DateTimeFormat(_NowCalc(), 0) & "] " & $logstring)
	ConsoleWrite("[" & _DateTimeFormat(_NowCalc(), 0) & "] " & $logstring & @CRLF)
EndFunc
