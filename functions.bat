@echo off 
setlocal EnableDelayedExpansion

:readconfig
setlocal
set file=%~1
set area=%~2

if [%~3] neq [] set area=%~2 "%~3"

set currarea=

for /f "usebackq delims=" %%a in ("!file!") do (
	set ln=%%a
	if "!ln:~0,1!"=="[" (
		set currarea=!ln!
	) else (
		for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
			
			set key=%%b
			set val=%%c
			
			if "[!area!]"=="!currarea!" (
				echo !key!=!val!
			)
		)
	)
)
endlocal