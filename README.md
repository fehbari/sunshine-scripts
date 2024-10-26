![Windows](https://img.shields.io/badge/platform-Windows-blue.svg)
![Batch](https://img.shields.io/badge/language-Batch-yellow.svg)
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
  - [`start_streaming.bat`](#start_streamingbat)
  - [`stop_streaming.bat`](#stop_streamingbat)
  - [`IddSampleDriver/option.txt`](#iddsampledriveroptiontxt)
- [Attributions](#attributions)

## Introduction

This setup assumes that you have already installed:
- **[Sunshine](https://github.com/LizardByte/Sunshine)** on your host PC for game streaming.
- **[Moonlight](https://moonlight-stream.org/)** on your client device to connect to your host.

Follow the links above for installation instructions if these are not yet set up.

**Important Notes**:
- These scripts are tailored for PCs with **NVIDIA graphics cards** and **G-Sync or G-Sync compatible monitors**.
- If you have an AMD setup and there’s enough interest, I might provide AMD-compatible versions of these scripts in the future.

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

In both scripts (`start_streaming.bat` and `stop_streaming.bat`), an extra environment variable controls whether RTSS settings are applied. If you don’t have RTSS installed, set this variable to `false`.

---

## Configuration

### Sunshine Settings

To fully automate the process, download the scripts from this repository and place them in the `C:\Tools\sunshine-scripts` folder. Then, configure these scripts in the [Sunshine web interface](https://localhost:47990/config):

1. Go to **Configuration > General > Command Preparations**.
2. Set the **Do Command** to:
   ```cmd
   cmd /C set USE_RTSS=false & C:\Tools\sunshine-scripts\start_streaming.bat
   ```
3. Set the **Undo Command** to:
   ```cmd
   cmd /C set WIDTH=1920 & set HEIGHT=1080 & set REFRESH=60 & set HDR=false & set USE_RTSS=true & C:\Tools\sunshine-scripts\stop_streaming.bat
   ```
   - **Important**: Edit the `WIDTH`, `HEIGHT`, `REFRESH`, `HDR`, and `USE_RTSS` values to match your monitor’s resolution, refresh rate, and whether or not you want to use RTSS for **regular desktop use** (i.e., when you're not streaming). These values will be passed to the `stop_streaming.bat` script when the streaming session ends.
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

### `start_streaming.bat`

This script prepares your system for streaming by enabling a virtual display, setting resolution, refresh rate, toggling HDR, disabling G-Sync, and adjusting FPS limits.

#### Usage

This script is automatically triggered by the Sunshine server when Moonlight starts streaming. It uses environment variables provided by Sunshine based on the settings received from the Moonlight client. No manual editing of variables is required.

#### Actions performed:
- Enables the virtual display.
- Sets the resolution and refresh rate with `QRes` based on the Moonlight client’s settings.
- Toggles HDR on/off using `HDRTray`.
- Disables G-Sync for the streaming session using `gsync-toggle`.
- Sets the FPS limit using `frl-toggle` and `RTSS` (if enabled via `USE_RTSS`).

---

### `stop_streaming.bat`

This script restores your system to its normal desktop configuration after streaming has ended.

#### Usage

This script is automatically triggered by the Sunshine server when Moonlight stops streaming. The necessary variables are passed through the **Undo Command** configuration, so no manual editing of the script is required.

#### Actions performed:
- Disables the virtual display.
- Restores the resolution and refresh rate for your primary display.
- Toggles HDR off using `HDRTray`.
- Re-enables G-Sync using `gsync-toggle`.
- Resets the FPS limit using `frl-toggle` and `RTSS` (if enabled via `USE_RTSS`).

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
