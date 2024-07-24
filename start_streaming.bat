:: Prepares the system for game stream by enabling the virtual display and setting
:: the resolution, refresh rate, HDR, G-Sync, FPS limit, and overlay.

@echo off
:: Check for administrative permissions
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    :: If not run as administrator, relaunch the script with elevated privileges
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~s0' -Verb RunAs"
    EXIT /B
)

:: Set variables
IF NOT DEFINED SUNSHINE_CLIENT_WIDTH set SUNSHINE_CLIENT_WIDTH=1920
IF NOT DEFINED SUNSHINE_CLIENT_HEIGHT set SUNSHINE_CLIENT_HEIGHT=1080
IF NOT DEFINED SUNSHINE_CLIENT_FPS set SUNSHINE_CLIENT_FPS=120
IF NOT DEFINED SUNSHINE_CLIENT_HDR set SUNSHINE_CLIENT_HDR=true

:: Enable the virtual display
devcon enable "root\iddsampledriver"
devcon enable "MONITOR\LNX0000"

:: Wait for the virtual display to be ready
timeout /t 3 /nobreak >nul

:: Set resolution using QRes
cmd /C "C:\Tools\QRes\QRes.exe /X:%SUNSHINE_CLIENT_WIDTH% /Y:%SUNSHINE_CLIENT_HEIGHT% /R:%SUNSHINE_CLIENT_FPS%"

:: Set HDR using HDRCmd
cmd /C if "%SUNSHINE_CLIENT_HDR%"=="true" (C:\Tools\HDRTray\HDRCmd on) else (C:\Tools\HDRTray\HDRCmd off)

:: Turn off G-Sync using gsynctoggle
C:\Tools\gsync-toggle\gsynctoggle 0

:: Set FPS limit using frl-toggle
cmd /C "C:\Tools\frl-toggle\frltoggle.exe %SUNSHINE_CLIENT_FPS%"

:: Set FPS limiter and overlay using rtss-cli
cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limit:set %SUNSHINE_CLIENT_FPS%"
cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limiter:set 1"
cmd /C "C:\Tools\rtss-cli\rtss-cli.exe overlay:set 0"

:: Add a delay to ensure all commands complete before closing
timeout /t 2 /nobreak >nul
