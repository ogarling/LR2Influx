#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Okke Garling

	Script Function:
	Launcher for LoadRunner automation
	Integration for Perfana & Influx

#ce ----------------------------------------------------------------------------

#AutoIt3Wrapper_Icon=perfana.ico
#AutoIt3Wrapper_Change2CUI=y
#include <Date.au3>
#include <Array.au3>
#include <String.au3>
#include <WinHttp.au3>

Global $aIEproxy = _WinHttpGetIEProxyConfigForCurrentUser()
Global $sProxy = $aIEproxy[2]
	If Not AssertionRequest("Afterburner-k8s", "Afterburner-k8s-1.0-nightlyLoadTest-nightly-2018-12-18T03:00:05Z") Then
;~ 	If Not AssertionRequest("LRLAUNCHER_DEMO", "LOADRUNNER-12-19-2018-13882") Then
		ConsoleWriteError("Failed on assertions." & @CRLF)
		Exit 3 ; errorlevel 3 = assertions
	Else
		Exit 0 ; return success
	EndIf

Func AssertionRequest($sApplication, $sTestrunId)
	; Initialize and get session handle
;~ 	If $nUseProxy = 1 Then
;~ 		$hOpen = _WinHttpOpen("Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0", $WINHTTP_ACCESS_TYPE_NAMED_PROXY, $sProxy)
;~ 	Else
		$hOpen = _WinHttpOpen("Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0")
;~ 	EndIf

	; Get connection handle
	$hConnect = _WinHttpConnect($hOpen, "perfana-ae.klm.com", "443")

;~ 	If $nUseSSL = 1 Then
		$sReceived = _WinHttpSimpleSSLRequest($hConnect, "GET", "/get-benchmark-results/" & $sApplication & "/" & $sTestrunId, Default, Default , "Content-Type: application/json" & @CR & "Cache-Control: no-cache" & @CR & "Connection: close")
;~ 	Else
;~ 		$sReceived = _WinHttpSimpleRequest($hConnect, "GET", "/get-benchmark-results/" & $sApplication & "/" & $sTestrunId, Default, Default , "Content-Type: application/json" & @CR & "Cache-Control: no-cache" & @CR & "Connection: close")
;~ 	EndIf

	If @error Then
		_WinHttpCloseHandle($hConnect)
		_WinHttpCloseHandle($hOpen)
 		ConsoleWriteError("Assertions request went wrong with error code: " & @error & @CRLF)
		SetError(1, 0, "Assertion request failed.")
	EndIf

	; Close handles
	_WinHttpCloseHandle($hConnect)
	_WinHttpCloseHandle($hOpen)

	If $sReceived = "No benchmark results found" Then
		ConsoleWrite("No benchmark results found." & @CRLF)
		Exit 0
	EndIf

	ConsoleWrite($sReceived)

	$aRequirements = _StringBetween($sReceived, '"requirements":{"result":', ',')
	; TODO: add deeplink
	$aBenchmarkPreviousTestRun = _StringBetween($sReceived, '"benchmarkPreviousTestRun":{"result":', ',')
	; TODO: add fixed baseline
	;$aBenchmarkResultFixedOK = _StringBetween($sReceived, '"benchmarkResultFixedOK":', ',')



;~ 	If $aBenchmarkPreviousTestRun[0] = "false" Or $aBenchmarkResultFixedOK[0] = "false" Or $aRequirements[0] = "false" Then
	If $aBenchmarkPreviousTestRun[0] = "false" Or $aRequirements[0] = "false" Then
		If $aRequirements[0] = "false" Then $sReturn = "Requirements not met: " & @CRLF ;$sProtocol & $sHost & ":" & $nPort & "/#!/requirements/" & StringUpper($sProductName) & "/" & StringUpper($sApplication) & "/" & StringUpper($sTestrunId) & "/failed/" & @CRLF
		If $aBenchmarkPreviousTestRun[0] = "false" Then $sReturn += "Benchmark with previous test result failed: " & @CRLF ;$sProtocol & $sHost & ":" & $nPort & "/#!/benchmark-previous-build/" & StringUpper($sProductName) & "/" & StringUpper($sApplication) & "/" & StringUpper($sTestrunId) & "/failed/" & @CRLF
;~ 		If $aBenchmarkResultFixedOK[0] = "false" Then $sReturn += "Benchmark with fixed baseline failed: " & $sProtocol & $sHost & ":" & $nPort & "/#!/benchmark-fixed-baseline/" & StringUpper($sProductName) & "/" & StringUpper($sApplication) & "/" & StringUpper($sTestrunId) & "/failed/" & @CRLF
		ConsoleWrite($sReturn)
		Return False
	Else
		ConsoleWrite("Assertions passed." & @CRLF)
		Return True
	EndIf
EndFunc   ;==>AssertionRequest