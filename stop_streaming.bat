:: Reverts changes made by start_streaming.bat and restores the system to its
:: original state for regular desktop use.

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

:: Disable the virtual display
devcon disable "MONITOR\LNX0000"
devcon disable "root\iddsampledriver"

:: Wait for the virtual display to be disabled
timeout /t 3 /nobreak >nul

:: Set resolution using QRes
cmd /C "C:\Tools\QRes\QRes.exe /X:%WIDTH% /Y:%HEIGHT% /R:%FPS%"

:: Set HDR using HDRCmd
cmd /C if "%HDR%"=="true" (C:\Tools\HDRTray\HDRCmd on) else (C:\Tools\HDRTray\HDRCmd off)

:: Turn on G-Sync using gsynctoggle
C:\Tools\gsync-toggle\gsynctoggle 1

:: Set FPS limit using frl-toggle
cmd /C "C:\Tools\frl-toggle\frltoggle.exe %LIMIT%"

:: Set FPS limiter and overlay using rtss-cli
:: cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limit:set %FPS%"
:: cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limiter:set 0"
:: cmd /C "C:\Tools\rtss-cli\rtss-cli.exe overlay:set 0"

:: Add a delay to ensure all commands complete before closing
timeout /t 2 /nobreak >nul
