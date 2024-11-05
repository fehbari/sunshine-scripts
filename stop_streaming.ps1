# Reverts changes made by start_streaming.ps1 and restores the system to its
# original state for regular desktop use.

# Set variables from the environment or use default values.
# The FPS limit is set to 3 less than the target refresh rate, as it's the
# recommended value for variable refresh rate displays.
$WIDTH = if ($Env:WIDTH -ne $null) { $Env:WIDTH } else { 1920 }
$HEIGHT = if ($Env:HEIGHT -ne $null) { $Env:HEIGHT } else { 1080 }
$REFRESH = if ($Env:REFRESH -ne $null) { $Env:REFRESH } else { 60 }
$HDR = if ($Env:HDR -ne $null) { $Env:HDR } else { "false" }
$USE_RTSS = if ($Env:USE_RTSS -ne $null) { $Env:USE_RTSS } else { "false" }
$LIMIT = [int]$REFRESH - 3  # Recommended FPS limit for VRR displays

# Restart script with elevated privileges if not already admin
if (-not ([Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
{
    Start-Process PowerShell `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Disable the virtual display
Write-Output "Disabling virtual display..."

# Search for the VDD device with either of the known friendly names
$device = Get-PnpDevice | Where-Object {
    $_.FriendlyName -eq "Virtual Display Driver by MTT" -or $_.FriendlyName -eq "IddSampleDriver Device HDR"
}

# Disable the device if found; otherwise, stop the script
if ($device) {
    Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    Write-Output "Disabled device: $($device.FriendlyName)"
} else {
    Write-Output "Error: No matching virtual display device found to disable. Exiting script."
    exit
}

# Wait for the virtual display to be disabled
Start-Sleep -Seconds 3

# Set resolution using QRes
$qresCmd = "C:\Tools\QRes\QRes.exe"
$qresArgs = @("/X:$WIDTH /Y:$HEIGHT /R:$REFRESH")
Write-Output "Setting resolution with QRes: $qresCmd $($qresArgs -join ' ')"
& $qresCmd @qresArgs > $null

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

# Wait a moment to ensure all commands complete
Start-Sleep -Seconds 2
