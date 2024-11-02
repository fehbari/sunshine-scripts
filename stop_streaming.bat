:: Reverts changes made by start_streaming.bat and restores the system to its
:: original state for regular desktop use.
@echo off

:: Set variables from the environment, or use default values.
:: The FPS limit is set to 3 less than the target refresh rate, as it's the
:: recommended value for variable refresh rate displays.
IF NOT DEFINED WIDTH set WIDTH=1920
IF NOT DEFINED HEIGHT set HEIGHT=1080
IF NOT DEFINED REFRESH set REFRESH=60
set /a LIMIT=%REFRESH%-3
IF NOT DEFINED HDR set HDR=false
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

:: Disable the virtual display
powershell -NoProfile -ExecutionPolicy Bypass -Command "$device = Get-PnpDevice | Where-Object {$_.FriendlyName -eq 'Virtual Display Driver by MTT'}; if ($device) { Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false }"

:: Wait for the virtual display to be disabled
timeout /t 3 /nobreak >nul

:: Set resolution using QRes
cmd /C "C:\Tools\QRes\QRes.exe /X:%WIDTH% /Y:%HEIGHT% /R:%REFRESH%"

:: Set HDR using HDRCmd
cmd /C if "%HDR%"=="true" (C:\Tools\HDRTray\HDRCmd on) else (C:\Tools\HDRTray\HDRCmd off)

:: Turn on G-Sync using gsynctoggle
C:\Tools\gsync-toggle\gsynctoggle 1

:: Set FPS limit using frl-toggle
cmd /C "C:\Tools\frl-toggle\frltoggle.exe %LIMIT%"

:: Set FPS limiter and overlay using rtss-cli
IF %USE_RTSS%==true (
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limit:set %LIMIT%"
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe limiter:set 0"
    cmd /C "C:\Tools\rtss-cli\rtss-cli.exe overlay:set 0"
)

:: Add a delay to ensure all commands complete before closing
timeout /t 2 /nobreak >nul
