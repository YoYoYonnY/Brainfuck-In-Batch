@ECHO OFF
FOR /F "TOKENS=*" %%A IN ('FINDSTR /n $') DO (
	SETLOCAL DISABLEDELAYEDEXPANSION
	SET "LINE=%%A"
    SETLOCAL ENABLEDELAYEDEXPANSION
	SET "LINE=!LINE:*:=!"
	CALL SET "STDIN=%%STDIN%%!LINE!"
)

CALL :FINDCODELEN STDIN

SET "CODE=!STDIN:~0,%CODELEN%!"
SET /A "CODELEN=CODELEN+1"
SET "INPUT=!STDIN:~%CODELEN%!"

SET ASCII="#$%%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
SET CODEPTR=0

SET STACK=

SET MEMPTR=0
SET MEMSIZE=30000

FOR /F %%A IN ('"PROMPT $H &ECHO ON &FOR %%B IN (1) DO REM"') DO SET BS=%%A
:LOOP
SET INSTR=!CODE:~%CODEPTR%,1!
IF [!INSTR!] == [] GOTO EXIT
IF NOT DEFINED MEM[!MEMPTR!] SET MEM[!MEMPTR!]=0
IF !INSTR!==+ (
	IF !MEM[%MEMPTR%]! GEQ 255 (
		SET MEM[!MEMPTR!]=0
	) ELSE (
		SET /A MEM[!MEMPTR!]=MEM[!MEMPTR!]+1
	)
	GOTO :NEXT
)
IF !INSTR!==- (
	IF !MEM[%MEMPTR%]! LEQ 0 (
		SET MEM[!MEMPTR!]=255
	) ELSE (
		SET /A MEM[!MEMPTR!]=MEM[!MEMPTR!]-1
	)
	GOTO :NEXT
)
IF !INSTR!==^> (
	IF !MEMPTR! GEQ %MEMSIZE% (
		SET MEMPTR=0
	) ELSE (
		SET /A MEMPTR=!MEMPTR!+1
	)
	GOTO :NEXT
)
IF !INSTR!==^< (
	IF !MEMPTR! LEQ 0 (
		SET MEMPTR=%MEMSIZE%
	) ELSE (
		SET /A MEMPTR=!MEMPTR!-1
	)
	GOTO :NEXT
)
IF !INSTR!==^, (
	CALL :GETCHAR
	GOTO :NEXT
)
IF !INSTR!==. (
	CALL :PUTCHAR
	GOTO :NEXT
)
IF !INSTR!==[ (
	IF !MEM[%MEMPTR%]!==0 (
		:WHILESTARTLOOP
		SET INSTR=!CODE:~%CODEPTR%,1!
		IF !INSTR!==[ SET /A NESTLED=!NESTLED!+1
		IF !INSTR!==] SET /A NESTLED=!NESTLED!-1
		SET /A CODEPTR=!CODEPTR!+1
		IF [!INSTR!] == [] GOTO ERROR
		IF NOT !NESTLED!==0 GOTO WHILESTARTLOOP
	) ELSE (
		SET "STACK=%CODEPTR% %STACK%"
	)
	GOTO :NEXT
)
IF !INSTR!==] (
	IF NOT !MEM[%MEMPTR%]!==0 (
		FOR /F "TOKENS=1" %%A IN ("!STACK!") DO SET "TOP=%%A"
		FOR /F "TOKENS=1*" %%A IN ("!STACK!") DO SET "STACK=%%B"
		SET CODEPTR=!TOP!
		GOTO :NEXT
	)
)
:NEXT
SET /A CODEPTR=!CODEPTR!+1
GOTO LOOP
:PUTCHAR
IF EXIST ascii\ascii!MEM[%MEMPTR%]!.txt (
	TYPE ascii\ascii!MEM[%MEMPTR%]!.txt
) ELSE (
	IF !MEM[%MEMPTR%]! GEQ 34 (
		SET /A CHAR=!MEM[%MEMPTR%]!-34
		<NUL SET /P=!ASCII:~%CHAR%,1!
	) ELSE (
		IF !MEM[%MEMPTR%]!==32 (
			<NUL SET /P=.%BS% 
			:: WARNING: Above line must contain a space before the newline
			GOTO :EOF
		)
		IF !MEM[%MEMPTR%]!==33 (
			<NUL SET /P=^^!
			GOTO :EOF
		)
		IF !MEM[%MEMPTR%]!==10 (
			ECHO.
			GOTO :EOF
		)
		<NUL SET /P=?
	)
)
GOTO :EOF
:GETCHAR
SET RESULT=0
FOR /L %%I IN (0,1,92) DO (
	SET INDEX=%%I
	CALL :TESTCHAR
	IF NOT "!RESULT!"=="0" GOTO :GETCHAR_END
)
:GETCHAR_END
GOTO :EOF
:DONE
SET /A MEM[!MEMPTR!]=!RESULT!+34
SET "INPUT=!INPUT:~1!"
GOTO :EOF
:TESTCHAR
SET CHAR1=!ASCII:~%INDEX%,1!
SET CHAR2=!INPUT:~0,1!
IF [!CHAR1!]==[!CHAR2!] (
	SET RESULT=%INDEX%
	GOTO :DONE
)
GOTO :EOF

:FINDCODELEN <CODE>
SET CODELEN=0
:FINDCODELEN_LOOP
SET "INSTR=!%1:~%CODELEN%,1!"
IF "%INSTR%"=="^!" GOTO :FINDCODELEN_LOOP_END
IF "%INSTR%"=="" GOTO :FINDCODELEN_LOOP_END
SET /A "CODELEN=CODELEN+1"
GOTO :FINDCODELEN_LOOP
:FINDCODELEN_LOOP_END
GOTO :EOF

:ERROR
ECHO ERROR: UNBALANCED BRACKETS
:EXIT