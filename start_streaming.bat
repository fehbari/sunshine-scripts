@echo off
:: Wrapper script to run the start_streaming.ps1 script from cmd with the necessary parameters.

set "PS_COMMAND=powershell.exe -ExecutionPolicy Bypass -File "%~dp0start_streaming.ps1""
set "PS_COMMAND=%PS_COMMAND% -SUNSHINE_CLIENT_WIDTH %SUNSHINE_CLIENT_WIDTH%"
set "PS_COMMAND=%PS_COMMAND% -SUNSHINE_CLIENT_HEIGHT %SUNSHINE_CLIENT_HEIGHT%"
set "PS_COMMAND=%PS_COMMAND% -SUNSHINE_CLIENT_FPS %SUNSHINE_CLIENT_FPS%"
set "PS_COMMAND=%PS_COMMAND% -SUNSHINE_CLIENT_HDR %SUNSHINE_CLIENT_HDR%"
set "PS_COMMAND=%PS_COMMAND% -USE_RTSS %USE_RTSS%"

%PS_COMMAND%
