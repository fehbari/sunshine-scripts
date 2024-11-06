@echo off
:: Wrapper script to run stop_streaming.ps1 from cmd with the necessary parameters.

set "PS_COMMAND=powershell.exe -ExecutionPolicy Bypass -File "%~dp0\src\stop_streaming.ps1" %*"

:: Run the PowerShell command with all parameters forwarded.
%PS_COMMAND%
