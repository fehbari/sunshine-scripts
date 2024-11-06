![Windows](https://img.shields.io/badge/platform-Windows-blue.svg)
![PowerShell](https://img.shields.io/badge/language-Powershell-yellow.svg)
![gpu](https://img.shields.io/badge/gpu-NVIDIA-green.svg)

# Sunshine Automation Scripts

This repository contains scripts to manage the setup and teardown of a game streaming session using the Sunshine server on your host PC. The scripts automate system changes, such as enabling a virtual display, adjusting resolution, refresh rate, HDR, G-Sync, and FPS limits for optimal streaming.

## Table of Contents

- [Introduction](#introduction)
- [Requirements](#requirements)
  - [Required Tools](#required-tools)
  - [Optional Tools](#optional-tools)
- [Configuration](#configuration)
  - [Sunshine Settings](#sunshine-settings)
  - [Set Virtual Display as Main Display](#set-virtual-display-as-main-display)
  - [Optional Failure Recovery](#optional-failure-recovery)
- [Scripts](#scripts)
  - [`start_streaming`](#start_streaming)
  - [`stop_streaming`](#stop_streaming)
  - [`IddSampleDriver/option.txt`](#iddsampledriveroptiontxt)
- [Attributions](#attributions)

## Introduction

This setup assumes that you have already installed:
- **[Sunshine](https://github.com/LizardByte/Sunshine)** on your host PC for game streaming.
- **[Moonlight](https://moonlight-stream.org/)** on your client device to connect to your host.

Follow the links above for installation instructions if these are not yet set up.

**Important Notes**:
- These scripts are tailored for PCs with **NVIDIA graphics cards** and **G-Sync or G-Sync compatible monitors**.
- If you have an AMD setup and there’s enough interest, I might provide AMD-compatible versions of these scripts in the future. I'm open to contributions if you want to help with that. Please refer to the [AMD support issue](https://github.com/fehbari/sunshine-scripts/issues/4) for more information.

---

## Requirements

### Tools

All required tools, except the virtual display driver, are bundled and available for download in the [binaries folder](bin/) for convenience. A malware scan result is included. Alternatively, you can download the tools manually from their official sources if preferred. **Note**: The tools **must** be placed in the `C:\Tools` folder for the scripts to function correctly.

### Required Tools

1. **[Virtual-Display-Driver](https://github.com/itsmikethetech/Virtual-Display-Driver)** - A virtual display driver that enables a virtual monitor for streaming. Follow the installation instructions on their [GitHub page](https://github.com/itsmikethetech/Virtual-Display-Driver?tab=readme-ov-file#installation). **Important**: Ensure the provided [option.txt](IddSampleDriver/option.txt) file is placed at `C:\IddSampleDriver\options.txt` before installing.
2. **[QRes](https://sourceforge.net/projects/qres/)** - A tool to set display resolution and refresh rate.
3. **[HDRTray](https://github.com/res2k/HDRTray)** - A command-line tool for toggling HDR.
4. **[gsync-toggle](https://github.com/FrogTheFrog/gsync-toggle)** - A tool for toggling G-Sync on and off.
5. **[frl-toggle](https://github.com/FrogTheFrog/frl-toggle)** - A tool to set the frame rate limit (FRL) for NVIDIA GPUs.

*Disclaimer*: I am not the author of these tools and cannot guarantee their safety or functionality. Use them at your own risk.

### Optional Tools

- **[RTSS (RivaTuner Statistics Server)](https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html)** - Used for managing FPS limits and on-screen overlays. This is optional, as the NVIDIA frame limiter will be set via `frl-toggle` even without RTSS.
- **[rtss-cli](https://github.com/xanderfrangos/rtss-cli)** - Command-line interface for RTSS to manage FPS limits and overlays from scripts.

In both scripts (`start_streaming` and `stop_streaming`), an extra environment variable controls whether RTSS settings are applied. If you don’t have RTSS installed, set this variable to `false`.

---

## Configuration

### Sunshine Settings

To fully automate the process, download the scripts from this repository and place them in the `C:\Tools\sunshine-scripts` folder. Then, configure these scripts in the [Sunshine web interface](https://localhost:47990/config):

1. Go to **Configuration > General > Command Preparations**.

2. Set the **Do Command** to:
   ```cmd
   cmd /c C:\Tools\sunshine-scripts\start_streaming.bat
   ```
   See [start_streaming](#start_streaming) to learn all the additional parameters that can be passed to this script.

3. Set the **Undo Command** to:
   ```cmd
   cmd /c C:\Tools\sunshine-scripts\stop_streaming.bat -WIDTH 1920 -HEIGHT 1080 -REFRESH 60 -HDR false
   ```
   **Important**: Edit the `WIDTH`, `HEIGHT`, `REFRESH` and `HDR` values to match your monitor’s resolution, refresh rate and HDR preference for **regular desktop use**, when the streaming session ends.
   
   See [stop_streaming](#stop_streaming) to learn all the additional parameters that can be passed to this script.

4. Check the **Run As Admin** box for both commands.

This setup will automate the execution of the scripts whenever Moonlight starts or stops a streaming session.

### Set Virtual Display as Main Display

After installing the **Virtual Display Driver**, you will need to set the virtual display as your main display in Windows **Display Settings**. This step ensures that Windows automatically switches between the virtual display (during streaming) and your primary display (when not streaming). This setup is only needed once.

To set the virtual display as the main display:
1. Open **Settings** > **System** > **Display**.
2. Scroll down to **Multiple Displays**.
3. Select the virtual display, and check **Make this my main display**.

Windows will now automatically switch between displays when starting or stopping a stream.

### Optional Failure Recovery

You can configure a task in **Windows Task Scheduler** to revert your system to its default settings if something goes wrong during streaming or if you forget to stop the stream. This task will run the `stop_streaming.bat` script at login, ensuring your computer reverts to its normal settings after a restart.

1. Download the [stop_streaming_task.xml](stop_streaming_task.xml) file, which is preconfigured to run `stop_streaming.bat` at login.

2. Import the task into **Windows Task Scheduler**:
   - Open **Task Scheduler** in Windows.
   - In the right-hand pane, click on **Import Task**.
   - Browse and select the `stop_streaming_task.xml` file.
   - Check the option to *"Run with highest privileges"*, in order to avoid seeing a UAC prompt.
   - Review the settings and click **OK** to import the task.

3. (Optional) Test the task by restarting your computer to ensure that the `stop_streaming.bat` script runs automatically and your settings revert to normal.

---

## Scripts

### `start_streaming`

This script prepares your system for streaming by enabling a virtual display, setting resolution, refresh rate, toggling HDR, disabling G-Sync, and adjusting FPS limits.

#### Usage

This script is automatically triggered by the Sunshine server when Moonlight starts streaming. It uses environment variables provided by Sunshine based on the settings received from the Moonlight client. No manual editing of variables is required.

#### Actions performed:
- Enables the virtual display.
- Sets the resolution and refresh rate with `QRes` based on the Moonlight client’s settings.
- Toggles HDR on/off using `HDRTray`.
- Disables G-Sync for the streaming session using `gsync-toggle`.
- Sets the global FPS limit in the Nvidia Control Panel using `frl-toggle`.
- If enabled via `USE_RTSS`, sets the global FPS limit using `RTSS` and disables its overlay while streaming.

#### Parameters:

- **WIDTH** - The width of the virtual display. **Default:** 1920, or the width passed by the Moonlight client.
- **HEIGHT** - The height of the virtual display. **Default:** 1080, or the height passed by the Moonlight client.
- **REFRESH** - The refresh rate of the virtual display. **Default:** 60, or the target FPS passed by the Moonlight client.
- **FPS** - The FPS limit for the stream. **Default:** 60, or the target FPS passed by the Moonlight client.
- **HDR** - Whether to enable HDR. **Default:** false, or the HDR setting passed by the Moonlight client.
- **USE_RTSS** - Whether to use RTSS for FPS limiting and turn off its overlay while streaming. **Default:** false.
- **DEBUG** - Whether to enable debug mode and view additional information. **Default:** false.

---

### `stop_streaming`

This script restores your system to its normal desktop configuration after streaming has ended.

#### Usage

This script is automatically triggered by the Sunshine server when Moonlight stops streaming. The necessary variables are passed through the **Undo Command** configuration, so no manual editing of the script is required.

#### Actions performed:
- Disables the virtual display.
- Restores the resolution and refresh rate for your primary display.
- Toggles HDR off using `HDRTray`.
- Re-enables G-Sync using `gsync-toggle`.
- Resets the global FPS limit in the Nvidia Control Panel using `frl-toggle`.
- If enabled via `USE_RTSS`, restores the FPS limit set in RTSS. The overlay remains disabled regardless of the parameter value.

#### Parameters:

- **WIDTH** - The width of the primary display. **Default:** 1920.
- **HEIGHT** - The height of the primary display. **Default:** 1080.
- **REFRESH** - The refresh rate of the primary display. **Default:** 60.
- **FPS** - The FPS limit for non-streaming gameplay. **Default:** Refresh rate - 3, as recommended for variable refresh rate displays.
- **HDR** - Whether to enable HDR. **Default:** false.
- **USE_RTSS** - Whether to restore the FPS limit set in RTSS. Keeps the overlay disabled regardless of the parameter value. **Default:** false.
- **DEBUG** - Whether to enable debug mode and view additional information. **Default:** false.

---

### `IddSampleDriver/option.txt`

This file defines the supported resolutions and refresh rates for the virtual display used during streaming. Ensure it is placed at `C:\IddSampleDriver\options.txt` before installing the [Virtual Display Driver](https://github.com/itsmikethetech/Virtual-Display-Driver). You may edit the file as needed to match your client device's supported resolutions and refresh rates. Some common resolutions and refresh rates are already included for convenience.

---

## Attributions

This project heavily relies on the following open-source tools and utilities:

- **[Virtual-Display-Driver](https://github.com/itsmikethetech/Virtual-Display-Driver)** - For creating a virtual display.
- **[QRes](https://sourceforge.net/projects/qres/)** - For managing display resolution.
- **[HDRTray](https://github.com/res2k/HDRTray)** - For controlling HDR settings.
- **[gsync-toggle](https://github.com/FrogTheFrog/gsync-toggle)** - For toggling G-Sync on and off.
- **[frl-toggle](https://github.com/FrogTheFrog/frl-toggle)** - For setting the NVIDIA frame rate limit.
- **[rtss-cli](https://github.com/xanderfrangos/rtss-cli)** - For controlling RTSS settings from the command line.

And of course:

- **[Sunshine](https://github.com/LizardByte/Sunshine)** - For enabling game streaming on any PC.
- **[Moonlight](https://moonlight-stream.org/)** - For connecting to the Sunshine server from virtually any device.
- **[RTSS (RivaTuner Statistics Server)](https://www.guru3d.com/files-details/rtss-rivatuner-statistics-server-download.html)** - For providing a universal tool for managing FPS limits and on-screen overlays.

Without these excellent tools, this project would not be possible. I’m merely providing the glue that makes these tools work together for an enhanced game streaming experience.
