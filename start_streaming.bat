:: Prepares the system for game stream by enabling the virtual display and setting
:: the resolution, refresh rate, HDR, G-Sync, FPS limit, and overlay.
@echo off

:: Set variables from the environment, or use default values.
IF NOT DEFINED SUNSHINE_CLIENT_WIDTH set SUNSHINE_CLIENT_WIDTH=1920
IF NOT DEFINED SUNSHINE_CLIENT_HEIGHT set SUNSHINE_CLIENT_HEIGHT=1080
IF NOT DEFINED SUNSHINE_CLIENT_FPS set SUNSHINE_CLIENT_FPS=60
IF NOT DEFINED SUNSHINE_CLIENT_HDR set SUNSHINE_CLIENT_HDR=false
IF NOT DEFINED USE_RTSS set USE_RTSS=false

:: Check for administrative permissions if necessary. At this point, we only need
:: admin permissions when using RTSS.
IF "%USE_RTSS%"=="true" (
    NET SESSION >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        :: If not runnign as admin, relaunch the script with elevated privileges
        powershell -Command "Start-Process cmd.exe -ArgumentList '/c %~s0' -Verb RunAs"
        EXIT /B
    )
)

:: Enable the virtual display
PNPUTIL /enable-device /deviceid "root\iddsampledriver"
PNPUTIL /enable-device /deviceid "MONITOR\LNX0000"

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
IF %USE_RTSS%==true (
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limit:set %SUNSHINE_CLIENT_FPS%"
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limiter:set 0"
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe overlay:set 1"
)

:: Add a delay to ensure all commands complete before closing
timeout /t 2 /nobreak >nul
