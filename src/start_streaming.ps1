# Prepares the system for game stream by enabling the virtual display and setting
# the resolution, refresh rate, HDR, G-Sync, FPS limit, and overlay.

# Set variables from the environment or use default values
$SUNSHINE_CLIENT_WIDTH = if ($Env:SUNSHINE_CLIENT_WIDTH -ne $null) { $Env:SUNSHINE_CLIENT_WIDTH } else { 1920 }
$SUNSHINE_CLIENT_HEIGHT = if ($Env:SUNSHINE_CLIENT_HEIGHT -ne $null) { $Env:SUNSHINE_CLIENT_HEIGHT } else { 1080 }
$SUNSHINE_CLIENT_FPS = if ($Env:SUNSHINE_CLIENT_FPS -ne $null) { $Env:SUNSHINE_CLIENT_FPS } else { 60 }
$SUNSHINE_CLIENT_HDR = if ($Env:SUNSHINE_CLIENT_HDR -ne $null) { $Env:SUNSHINE_CLIENT_HDR } else { "false" }
$USE_RTSS = if ($Env:USE_RTSS -ne $null) { $Env:USE_RTSS } else { "false" }

# Restart script with elevated privileges if not already admin
if (-not ([Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
{
    Start-Process PowerShell `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Enable the virtual display
Write-Output "Enabling virtual display..."

# Search for the VDD device with either of the known friendly names
$device = Get-PnpDevice | Where-Object {
    $_.FriendlyName -eq "Virtual Display Driver by MTT" -or $_.FriendlyName -eq "IddSampleDriver Device HDR"
}

# Enable the device if found; otherwise, stop the script
if ($device) {
    Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    Write-Output "Enabled device: $($device.FriendlyName)"
} else {
    Write-Output "Error: No matching virtual display device found. Exiting script."
    exit
}

# Wait for the virtual display to be ready
Start-Sleep -Seconds 3

# Set resolution using QRes
$qresCmd = "C:\Tools\QRes\QRes.exe"
$qresArgs = @("/X:$SUNSHINE_CLIENT_WIDTH", "/Y:$SUNSHINE_CLIENT_HEIGHT", "/R:$SUNSHINE_CLIENT_FPS")
Write-Output "Setting resolution with QRes: $qresCmd $($qresArgs -join ' ')"
& $qresCmd @qresArgs > $null

# Wait for the resolution to be set
Start-Sleep -Seconds 2

# Set HDR using HDRCmd
$hdrCmd = "C:\Tools\HDRTray\HDRCmd"
$hdrArgs = if ($SUNSHINE_CLIENT_HDR -eq "true") { "on" } else { "off" }
Write-Output "Turning HDR $hdrArgs with HDRCmd: $hdrCmd $hdrArgs"
& $hdrCmd $hdrArgs

# Turn off G-Sync using gsynctoggle
$gsyncCmd = "C:\Tools\gsync-toggle\gsynctoggle"
$gsyncArgs = "0"
Write-Output "Turning off G-Sync: $gsyncCmd $gsyncArgs"
& $gsyncCmd $gsyncArgs

# Set FPS limit using frl-toggle
$frlCmd = "C:\Tools\frl-toggle\frltoggle.exe"
$frlArgs = "$SUNSHINE_CLIENT_FPS"
Write-Output "Setting FPS limit with frl-toggle: $frlCmd $frlArgs"
& $frlCmd $frlArgs

# Set FPS limiter and overlay using rtss-cli if RTSS is enabled
if ($USE_RTSS -eq "true") {
    $rtssLimitCmd = "C:\Tools\rtss-cli\rtss-cli.exe"
    $rtssLimitArgs = "limit:set $SUNSHINE_CLIENT_FPS"
    $rtssLimiterArgs = "limiter:set 0"
    $rtssOverlayArgs = "overlay:set 1"

    Write-Output "Setting RTSS FPS limit: $rtssLimitCmd $rtssLimitArgs"
    & $rtssLimitCmd $rtssLimitArgs

    Write-Output "Disabling RTSS limiter: $rtssLimitCmd $rtssLimiterArgs"
    & $rtssLimitCmd $rtssLimiterArgs

    Write-Output "Enabling RTSS overlay: $rtssLimitCmd $rtssOverlayArgs"
    & $rtssLimitCmd $rtssOverlayArgs
}

# Wait a moment to ensure all commands complete
Start-Sleep -Seconds 2
