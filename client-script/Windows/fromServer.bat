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
IF %errorCount% GTR 0 (
	ECHO 設定有些錯誤，請檢查！
	PAUSE
	EXIT /B 1
)


SET fileNames[0]=null
SET fileSizes[0]=null
SET fileTimes[0]=null
SET downloadUris[0]=null
SET isSelected[0]=null
SET arrSize=-1

curl -s %url%/list-csv > %shellPath%list.txt

FOR /F "tokens=1,2,3,4 delims=," %%A IN ( %shellPath%list.txt ) DO (
	SET /A arrSize=!arrSize!+1
	SET fileNames[!arrSize!]=%%A
	SET fileSizes[!arrSize!]=%%B
	SET fileTimes[!arrSize!]=%%C
	SET downloadUris[!arrSize!]=%%D
	SET isSelected[!arrSize!]=0
)

DEL %shellPath%list.txt

::FOR /L %%i IN (0,1,!arrSize!) DO (
::	ECHO %%i. !fileNames[%%i]! !fileSizes[%%i]! !fileTimes[%%i]! !isSelected[%%i]!
::)

IF %arrSize% EQU -1 (
	ECHO 沒有檔案可以下載！
	PAUSE
	EXIT /B 1
)

CALL :ADD_SPACES 50 paddingFileName
CALL :ADD_SPACES 12 paddingFileSzie
SET title[0]=-編號.
SET title[1]=檔案名稱%paddingFileName%
SET title[2]=檔案大小%paddingFileSzie%
SET title[3]=修改時間
GOTO MENU

:: Function to add spaces
:ADD_SPACES
SETLOCAL
SET "spaces="
FOR /L %%i IN (1,1,%1) DO SET "spaces=!spaces! "
( ENDLOCAL & SET %2=%spaces% )
EXIT /B

:MENU
CLS
ECHO.
ECHO 遠端檔案列表
ECHO.
ECHO !title[0]!	!title[1]:~0,46! !title[2]:~0,8! !title[3]!
FOR /L %%i IN (0,1,!arrSize!) DO (
	SET name=!fileNames[%%i]!%paddingFileName%
	SET size=!fileSizes[%%i]!%paddingFileSzie%
	SET time=!fileTimes[%%i]!
	IF !isSelected[%%i]! EQU 1 (
		ECHO [*] %%i.	!name:~0,50! !size:~0,12! !time!
	) ELSE (
		ECHO [ ] %%i.	!name:~0,50! !size:~0,12! !time!
	)
)
ECHO.
ECHO 請選擇要下載的檔案編號 (用空白分隔多個選擇)，或輸入 A[全選], D[下載], Q[離開]
SET /P choice="請選擇: "
ECHO.

IF /I "%choice%"=="Q" (
	EXIT /B 0
) ELSE IF /I "%choice%"=="D" (
	GOTO DOWNLOAD
) ELSE IF /I "%choice%"=="A" (
	FOR /L %%i IN (0,1,!arrSize!) DO (
		SET isSelected[%%i]=1
	)
	GOTO MENU
) ELSE (
	FOR %%i IN (%choice%) DO (
		ECHO %%i | FINDSTR /R "^[0-9][0-9]*$" >NUL
		IF ERRORLEVEL 0 (
			IF %%i LEQ !arrSize! (
				SET /A isSelected[%%i]=isSelected[%%i] ^^ 1
			)
		)
	)
	GOTO MENU
)


:DOWNLOAD
FOR /L %%i IN (0,1,!arrSize!) DO (
	IF !isSelected[%%i]! EQU 1 (
		ECHO 檔案: !fileNames[%%i]! 下載中...
		curl -o !fileNames[%%i]! !downloadUris[%%i]!
	)
)

PAUSE