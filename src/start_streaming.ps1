# Prepares the system for game stream by enabling the virtual display and setting
# the resolution, refresh rate, HDR, G-Sync, FPS limit, and overlay.

# Read parameters passed to the script, or use defaults
param(
    [int] $WIDTH = 1920,
    [int] $HEIGHT = 1080,
    [int] $REFRESH = 60,
    [int] $FPS = 0,
    [string] $HDR = "false",
    [string] $USE_RTSS = "false",
    [string] $VDD_DISPLAY_NAME = "",
    [string] $DEBUG = "false"
)

# Set variables from the Sunshine environment, or use defaults
$CLIENT_WIDTH = if ($null -ne $Env:SUNSHINE_CLIENT_WIDTH) { $Env:SUNSHINE_CLIENT_WIDTH } else { $WIDTH }
$CLIENT_HEIGHT = if ($null -ne $Env:SUNSHINE_CLIENT_HEIGHT) { $Env:SUNSHINE_CLIENT_HEIGHT } else { $HEIGHT }
$CLIENT_REFRESH = if ($null -ne $Env:SUNSHINE_CLIENT_FPS) { $Env:SUNSHINE_CLIENT_FPS } else { $REFRESH }
$CLIENT_HDR = if ($null -ne $Env:SUNSHINE_CLIENT_HDR) { $Env:SUNSHINE_CLIENT_HDR } else { $HDR }

# Set FPS limit by default to the target refresh rate. This value can be overridden
# by the FPS parameter, to customize a limit independent from the refresh rate.
# This can be useful, for example, to run a game at 40 FPS on a 120 Hz display.
$LIMIT = if ($FPS -eq 0) { $CLIENT_REFRESH } else { $FPS }

function Resolve-VddDevice {
    param(
        [string] $PreferredName,
        [string[]] $FallbackNames
    )

    $allVddDevices = Get-PnpDevice | Where-Object { $null -ne $_.FriendlyName }

    if (-not [string]::IsNullOrWhiteSpace($PreferredName)) {
        $matchingDevices = @($allVddDevices | Where-Object { $_.FriendlyName -eq $PreferredName })
        if ($matchingDevices.Count -gt 1) {
            Write-Output "Error: Multiple devices matched the custom VDD display name '$PreferredName'. Exiting script."
            exit
        }
        if ($matchingDevices.Count -eq 1) {
            Write-Output "Found VDD device using custom friendly name: $PreferredName"
            return $matchingDevices[0]
        }
    }

    foreach ($name in $FallbackNames) {
        $matchingDevices = @($allVddDevices | Where-Object { $_.FriendlyName -like "*$name*" })
        if ($matchingDevices.Count -gt 1) {
            Write-Output "Error: Multiple devices matched the known VDD display name '$name'. Exiting script."
            exit
        }
        if ($matchingDevices.Count -eq 1) {
            Write-Output "Found VDD device using known friendly name: $($matchingDevices[0].FriendlyName)"
            return $matchingDevices[0]
        }
    }

    return $null
}

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

# Enable the virtual display
Write-Output "Enabling virtual display..."

$knownVddDisplayNames = @(
    "Virtual Display Driver",
    "IddSampleDriver Device HDR"
)

$customVddDisplayName = ""
if (-not [string]::IsNullOrWhiteSpace($VDD_DISPLAY_NAME)) {
    $customVddDisplayName = $VDD_DISPLAY_NAME.Trim()
}

if (-not [string]::IsNullOrWhiteSpace($customVddDisplayName)) {
    Write-Output "Looking for VDD device using custom friendly name first: $customVddDisplayName"
}
Write-Output "Falling back to known VDD friendly names if needed: $($knownVddDisplayNames -join ', ')"

$device = Resolve-VddDevice -PreferredName $customVddDisplayName -FallbackNames $knownVddDisplayNames

# Enable the device if found; otherwise, stop the script
if ($device) {
    Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
    Write-Output "Enabled device: $($device.FriendlyName)"
}
else {
    Write-Output "Error: No matching virtual display device found. Exiting script."
    exit
}

# Wait for the virtual display to be ready
Start-Sleep -Seconds 3

# Helper function to dynamically find an executable with optional versioning in C:\Tools or its subdirectories
function Get-ToolPath ($BaseName) {
    # Search for the base name followed by anything, ending in .exe (e.g., "gsynctoggle*.exe")
    $filter = "$BaseName*.exe"
    
    # Sort descending so if multiple versions exist, it attempts to grab the highest version first
    $file = Get-ChildItem -Path "C:\Tools" -Filter $filter -Recurse -File -ErrorAction SilentlyContinue | 
            Sort-Object Name -Descending | 
            Select-Object -First 1

    if ($file) {
        return $file.FullName
    } else {
        Write-Warning "Could not find any executable matching '$filter' in C:\Tools or its subdirectories."
        return $null
    }
}

# Find and run QRes
$qresCmd = Get-ToolPath "QRes"
if ($qresCmd) {
    $qresArgs = @("/X:$CLIENT_WIDTH", "/Y:$CLIENT_HEIGHT", "/R:$CLIENT_REFRESH")
    Write-Output "Setting resolution with QRes: $qresCmd $($qresArgs -join ' ')"
    if ($DEBUG -eq "true") { & $qresCmd @qresArgs } else { & $qresCmd @qresArgs > $null }
}

# Wait for the resolution to be set
Start-Sleep -Seconds 2

# Set HDR using HDRCmd
$hdrCmd = Get-ToolPath "HDRCmd"
if ($hdrCmd) {
    $hdrArgs = if ($CLIENT_HDR -eq "true") { "on" } else { "off" }
    Write-Output "Turning HDR $hdrArgs with HDRCmd: $hdrCmd $hdrArgs"
    & $hdrCmd $hdrArgs
}

# Turn off G-Sync using gsynctoggle
$gsyncCmd = Get-ToolPath "gsynctoggle"
if ($gsyncCmd) {
    $gsyncArgs = "0"
    Write-Output "Turning off G-Sync: $gsyncCmd $gsyncArgs"
    & $gsyncCmd $gsyncArgs
}

# Set FPS limit using frl-toggle
$frlCmd = Get-ToolPath "frltoggle"
if ($frlCmd) {
    $frlArgs = "$LIMIT"
    Write-Output "Setting FPS limit with frl-toggle: $frlCmd $frlArgs"
    & $frlCmd $frlArgs
}

# Set FPS limiter and overlay using rtss-cli if RTSS is enabled
if ($USE_RTSS -eq "true") {
    $rtssLimitCmd = Get-ToolPath "rtss-cli"
    if ($rtssLimitCmd) {
        $rtssLimitArgs = "limit:set $LIMIT"
        $rtssLimiterArgs = "limiter:set 0"
        $rtssOverlayArgs = "overlay:set 1"

        Write-Output "Setting RTSS FPS limit: $rtssLimitCmd $rtssLimitArgs"
        & $rtssLimitCmd $rtssLimitArgs

        Write-Output "Disabling RTSS limiter: $rtssLimitCmd $rtssLimiterArgs"
        & $rtssLimitCmd $rtssLimiterArgs

        Write-Output "Enabling RTSS overlay: $rtssLimitCmd $rtssOverlayArgs"
        & $rtssLimitCmd $rtssOverlayArgs
    }
}

# Wait to ensure all commands complete, or wait for user input if in debug mode
if ($DEBUG -eq "true") {
    Read-Host "Debug mode enabled. Press Enter to exit..."
}
else {
    Start-Sleep -Seconds 2
}
