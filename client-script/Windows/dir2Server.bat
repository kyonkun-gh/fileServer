@ECHO OFF
COLOR 0F

chcp 65001
setlocal enabledelayedexpansion

::Dynamic Variable
SET shellPath=%~dp0

::Load conf data
FOR /f "tokens=1,2 delims==" %%A IN ( %shellPath%my.conf ) DO (
	SET %%A=%%B
)
SET url=%PROTOCOL%%REMOTE_HOST%:%PORT%
SET myPath=%1%

SET errorCount=0
IF "%PROTOCOL%"=="" (
	ECHO PROTOCOL 沒有設定，請檢查！
	SET /a errorCount+=1
)
IF "%REMOTE_HOST%"=="" (
	ECHO REMOTE_HOST 沒有設定，請檢查！
	SET /a errorCount+=1
)
IF "%PORT%"=="" (
	ECHO PORT 沒有設定，請檢查！
	SET /a errorCount+=1
)
IF "%DEFAULT_UPLOAD_PATH%"=="" (
	ECHO DEFAULT_UPLOAD_PATH 沒有設定，請檢查！
	SET /a errorCount+=1
) ELSE IF NOT EXIST "%DEFAULT_UPLOAD_PATH%" (
	ECHO DEFAULT_UPLOAD_PATH 不是目錄，請檢查！
	SET /a errorCount+=1
)
IF %errorCount% GTR 0 (
	ECHO 設定有些錯誤，請檢查！
	PAUSE
	EXIT /B 1
)


IF "%myPath%"=="" (
	ECHO 使用預設目錄: %DEFAULT_UPLOAD_PATH%
	SET myPath=%DEFAULT_UPLOAD_PATH%
) ELSE IF NOT EXIST "%myPath%" (
	ECHO %myPath% 不是目錄. 使用預設目錄: %DEFAULT_UPLOAD_PATH%
	SET myPath=%DEFAULT_UPLOAD_PATH%
)

ECHO.
::telnet
ECHO %url% 沒有檢查是否可以連線，請自行確認！

ECHO.
FOR %%j IN (%myPath%\*) DO (
	ECHO 檔案: %%j 上傳中...
	curl -v -F file=@%%j %url%
)

PAUSE