# ESPHome ESP32-P4 + ESP32-C6 Hosted Firmware Generator

This PowerShell script automates the build and deployment of ESP32-P4 in a Hosted configuration with an ESP32-C6 as the slave network adapter.

It handles the nvironment setup, fetching pre-compiled slave binaries from ESPHome, building the host application (with embedded slave firmware), and generating flashable bin files.

## Features

- **Automated Environment Setup**: Automatically checks for and installs the required ESP-IDF version (Default: v5.5.2) if a local installation is not provided.
- **Pre-compiled Slave Integration**: Downloads precompiled ESP32-C6 slave firmware from [ESPHome manifest](https://esphome.github.io/esp-hosted-firmware/manifest/esp32c6.json) to reduce build time.
- **Host Build Automation**: Configures the ESP32-P4 host example project (SDIO) from ESP-IDF and embeds the slave binary for OTA flashing.
- **Artifact Export**: Consolidates all necessary binaries (bootloader, partition table, app, slave firmware) into a single output directory.
- **Flash Helper**: Generates a ready-to-use script for flashing the device and offers immediate flashing capabilities.

## Prerequisites

Ensure the following tools are installed and available in your system `PATH`:

1.  **PowerShell** (Windows default)
2.  **Git**: Download Git
3.  **Python 3.x**: Download Python

## Usage

Open PowerShell and navigate to the directory containing the script.

### 1. Basic Execution
Run with default settings. This will use `C:\ESP_Build_Fast` as the working directory and download ESP-IDF v5.5.2.

```powershell
.\Build-EspHostedFirmware.ps1
```

### 2. Custom Working Directory
Specify a custom directory for downloading tools and building the project.

```powershell
.\Build-EspHostedFirmware.ps1 -WorkDir "C:\Projects\ESP_Hosted"
```

### 3. Using an Existing ESP-IDF
If you already have ESP-IDF installed, provide the path to skip the download/install phase.

```powershell
.\Build-EspHostedFirmware.ps1 -ExistingIdfPath "C:\Espressif\frameworks\esp-idf-v5.5.2"
```

## Parameters

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `-IdfVersion` | `v5.5.2` | The ESP-IDF version tag to clone and use for the host build. |
| `-WorkDir` | `C:\ESP_Build_Fast` | The root directory where the environment, repositories, and builds are stored. |
| `-OutputDir` | `WorkDir\firmware` | The destination folder for the final compiled binaries. |
| `-SlaveChip` | `esp32c6` | The target chip for the network adapter (slave). |
| `-ExistingIdfPath` | `""` | (Optional) Full path to a local ESP-IDF installation. |

## Output Artifacts

Upon successful completion, the `OutputDir` will contain the following files:

- **bootloader.bin**: The project bootloader.
- **partition-table.bin**: The partition table configuration.
- **ota_data_initial.bin**: OTA data initialization binary.
- **host_performs_slave_ota.bin**: The main ESP32-P4 host application.
- **network_adapter.bin**: The ESP32-C6 slave firmware (standalone copy).
- **flash_firmware.ps1**: A generated script to flash all files to the device.

## Flashing the Device

### Immediate Flashing
The script will prompt you at the end: `Do you want to flash the device now? (y/N)`. If you select **Yes**, you will be asked to enter the COM port (e.g., `COM3`).

### Flashing Later
A convenience script `flash_firmware.ps1` is generated in the output folder.

1.  Open PowerShell.
2.  Navigate to the output folder (e.g., `C:\ESP_Build_Fast\firmware`).
3.  Run the script:
    ```powershell
    .\flash_firmware.ps1
    ```
    *Note: You may need to edit this file to change the COM port if it differs from the default or the one provided during the build.*

### Example output 

run
```shell
idf.py -p COMXX monitor
```

```powershell
I (2211) transport: Base transport is set-up, TRANSPORT_TX_ACTIVE
I (2217) H_API: Transport active
I (2220) transport: Slave chip Id[12]
I (2223) transport: raw_tp_dir[-], flow_ctrl: low[60] high[80]
I (2228) transport: transport_delayed_init
I (2232) esp_cli: Registering command: crash
I (2236) esp_cli: Registering command: reboot
I (2240) esp_cli: Registering command: mem-dump
I (2245) esp_cli: Registering command: task-dump
I (2249) esp_cli: Registering command: cpu-dump
I (2253) esp_cli: Registering command: heap-trace
I (2258) esp_cli: Registering command: sock-dump
I (2262) esp_cli: Registering command: host-power-save
I (2267) hci_stub_drv: Host BT Support: Disabled
I (2271) H_SDIO_DRV: Received INIT event
I (2275) H_SDIO_DRV: Event type: 0x22
I (2278) H_SDIO_DRV: Write thread started
I (2342) host_performs_slave_ota: ESP-Hosted initialized successfully
I (2436) RPC_WRAP: Coprocessor Boot-up
I (2438) host_performs_slave_ota: Host firmware version: 2.11.5
I (2438) host_performs_slave_ota: Slave firmware version: 2.11.3
I (2440) host_performs_slave_ota: Versions compatible - OTA not required
I (2446) main_task: Returned from app_main()
```