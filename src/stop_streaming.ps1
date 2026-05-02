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
    [string] $VDD_DISPLAY_NAME = "",
    [string] $DEBUG = "false"
)

# Set FPS limit by default to 3 less than the target refresh rate, as it's the
# recommended value for variable refresh rate displays. This value can be overridden
# by the FPS parameter, to customize a limit independent from the refresh rate.
$LIMIT = if ($FPS -eq 0) { $REFRESH - 3 } else { $FPS }

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

# Disable the virtual display
Write-Output "Disabling virtual display..."

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

# Helper function to dynamically find an executable with optional versioning in C:\Tools or its subdirectories
function Get-ToolPath ($BaseName) {
    $filter = "$BaseName*.exe"
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

# Set resolution using QRes
$qresCmd = Get-ToolPath "QRes"
if ($qresCmd) {
    $qresArgs = @("/X:$WIDTH", "/Y:$HEIGHT", "/R:$REFRESH")
    Write-Output "Setting resolution with QRes: $qresCmd $($qresArgs -join ' ')"
    if ($DEBUG -eq "true") { & $qresCmd @qresArgs } else { & $qresCmd @qresArgs > $null }
}

# Wait for the resolution to be set
Start-Sleep -Seconds 2

# Set HDR using HDRCmd
$hdrCmd = Get-ToolPath "HDRCmd"
if ($hdrCmd) {
    $hdrArgs = if ($HDR -eq "true") { "on" } else { "off" }
    Write-Output "Turning HDR $hdrArgs with HDRCmd: $hdrCmd $hdrArgs"
    & $hdrCmd $hdrArgs
}

# Turn on G-Sync using gsynctoggle
$gsyncCmd = Get-ToolPath "gsynctoggle"
if ($gsyncCmd) {
    $gsyncArgs = "1"
    Write-Output "Turning on G-Sync: $gsyncCmd $gsyncArgs"
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
        $rtssOverlayArgs = "overlay:set 0"

        Write-Output "Setting RTSS FPS limit: $rtssLimitCmd $rtssLimitArgs"
        & $rtssLimitCmd $rtssLimitArgs

        Write-Output "Disabling RTSS limiter: $rtssLimitCmd $rtssLimiterArgs"
        & $rtssLimitCmd $rtssLimiterArgs

        Write-Output "Disabling RTSS overlay: $rtssLimitCmd $rtssOverlayArgs"
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
