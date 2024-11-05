@echo off
:: Wrapper script to run the stop_streaming.ps1 script from cmd with the necessary parameters.

set "PS_COMMAND=powershell.exe -ExecutionPolicy Bypass -File "%~dp0stop_streaming.ps1""
set "PS_COMMAND=%PS_COMMAND% -WIDTH %WIDTH%"
set "PS_COMMAND=%PS_COMMAND% -HEIGHT %HEIGHT%"
set "PS_COMMAND=%PS_COMMAND% -REFRESH %REFRESH%"
set "PS_COMMAND=%PS_COMMAND% -HDR %HDR%"
set "PS_COMMAND=%PS_COMMAND% -USE_RTSS %USE_RTSS%"

%PS_COMMAND%
