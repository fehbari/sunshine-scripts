@echo off
:: Check for administrative permissions
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    :: If not run as administrator, relaunch the script with elevated privileges
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~s0' -Verb RunAs"
    EXIT /B
)

:: Set variables
set WIDTH=3440
set HEIGHT=1440
set FPS=175
set /a LIMIT=%FPS%-3
set HDR=false

rem Disable the virtual display
devcon disable "MONITOR\LNX0000"
devcon disable "root\iddsampledriver"

rem Set resolution using QRes
cmd /C "C:\Tools\QRes\QRes.exe /X:%WIDTH% /Y:%HEIGHT% /R:%FPS%"

rem Set HDR using HDRCmd
cmd /C if "%HDR%"=="true" (C:\Tools\HDRTray\HDRCmd on) else (C:\Tools\HDRTray\HDRCmd off)

:: rem Set FPS limit using frl-toggle
:: cmd /C "C:\Tools\frl-toggle\frltoggle.exe %LIMIT%"

rem Set FPS limit using rtss-cli
cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limit:set %FPS%"

rem Disable limiter using rtss-cli
cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limiter:set 0"

rem Turn on G-Sync using gsynctoggle
C:\Tools\gsync-toggle\gsynctoggle 1

:: Add a delay to ensure all commands complete before closing
timeout /t 5 /nobreak >nul
