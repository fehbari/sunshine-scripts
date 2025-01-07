# Reverts changes made by start_streaming.ps1 and restores the system to its
# original state for regular desktop use.

# Read parameters passed to the script, or use defaults
param(
    [int] $WIDTH = 1920,
    [int] $HEIGHT = 1080,
    [int] $REFRESH = 60,
    [int] $FPS = 0,
    [string] $HDR = "false",
    [string] $USE_RTSS = "false",
    [string] $DEBUG = "false"
)

# Set FPS limit by default to 3 less than the target refresh rate, as it's the
# recommended value for variable refresh rate displays. This value can be overridden
# by the FPS parameter, to customize a limit independent from the refresh rate.
$LIMIT = if ($FPS -eq 0) { $REFRESH - 3 } else { $FPS }

# Restart script with elevated privileges if not already admin
if (-not ([Security.Principal.WindowsPrincipal]::new(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {

    # Capture the current arguments
    $arguments = @()
    foreach ($key in $PSBoundParameters.Keys) {
        $value = $PSBoundParameters[$key]
        $arguments += "-$key `"$value`""
    }
    $argumentString = $arguments -join ' '

    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" $argumentString"
    exit
}

# Disable the virtual display
Write-Output "Disabling virtual display..."

# Search for the VDD device with one of the known friendly names
$device = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*Virtual Display Driver*" -or
    $_.FriendlyName -like "*IddSampleDriver Device HDR*"
}

# Disable the device if found; otherwise, stop the script
if ($device) {
    Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    Write-Output "Disabled device: $($device.FriendlyName)"
}
else {
    Write-Output "Error: No matching virtual display device found to disable. Exiting script."
    exit
}

# Wait for the virtual display to be disabled
Start-Sleep -Seconds 3

# Set resolution using QRes
$qresCmd = "C:\Tools\QRes\QRes.exe"
$qresArgs = @("/X:$WIDTH", "/Y:$HEIGHT", "/R:$REFRESH")
Write-Output "Setting resolution with QRes: $qresCmd $($qresArgs -join ' ')"
if ($DEBUG -eq "true") { & $qresCmd @qresArgs } else { & $qresCmd @qresArgs > $null }

# Wait for the resolution to be set
Start-Sleep -Seconds 2

# Set HDR using HDRCmd
$hdrCmd = "C:\Tools\HDRTray\HDRCmd"
$hdrArgs = if ($HDR -eq "true") { "on" } else { "off" }
Write-Output "Turning HDR $hdrArgs with HDRCmd: $hdrCmd $hdrArgs"
& $hdrCmd $hdrArgs

# Turn on G-Sync using gsynctoggle
$gsyncCmd = "C:\Tools\gsync-toggle\gsynctoggle"
$gsyncArgs = "1"
Write-Output "Turning on G-Sync: $gsyncCmd $gsyncArgs"
& $gsyncCmd $gsyncArgs

# Set FPS limit using frl-toggle
$frlCmd = "C:\Tools\frl-toggle\frltoggle.exe"
$frlArgs = "$LIMIT"
Write-Output "Setting FPS limit with frl-toggle: $frlCmd $frlArgs"
& $frlCmd $frlArgs

# Set FPS limiter and overlay using rtss-cli if RTSS is enabled
if ($USE_RTSS -eq "true") {
    $rtssLimitCmd = "C:\Tools\rtss-cli\rtss-cli.exe"
    $rtssLimitArgs = "limit:set $LIMIT"
    $rtssLimiterArgs = "limiter:set 0"
    $rtssOverlayArgs = "overlay:set 0"

    Write-Output "Setting RTSS FPS limit: $rtssLimitCmd $rtssLimitArgs"
    & $rtssLimitCmd $rtssLimitArgs

    Write-Output "Disabling RTSS limiter: $rtssLimitCmd $rtssLimiterArgs"
    & $rtssLimitCmd $rtssLimiterArgs

    Write-Output "Disabling RTSS overlay: $rtssLimitCmd $rtssOverlayArgs"
    & $rtssLimitCmd $rtssOverlayArgs
}

# Wait to ensure all commands complete, or wait for user input if in debug mode
if ($DEBUG -eq "true") {
    Read-Host "Debug mode enabled. Press Enter to exit..."
}
else {
    Start-Sleep -Seconds 2
}
