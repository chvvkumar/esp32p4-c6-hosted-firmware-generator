<#
.SYNOPSIS
    Fast build script for Waveshare ESP32-P4 + ESP32-C6.
    Uses pre-compiled ESPHome slave binaries to save time.

.DESCRIPTION
    1. Downloads the correct Slave Firmware (ESP32-C6) from ESPHome.
    2. Verifies the SHA256 checksum against the official manifest.
    3. Builds ONLY the Host Firmware (ESP32-P4) with the embedded slave.
    4. Exports flashable artifacts.
    5. (Optional) Flashes the device immediately.

.PARAMETER IdfVersion
    The ESP-IDF version to use for the HOST build (Default: v5.5.2)
.PARAMETER WorkDir
    The directory where projects will be downloaded and built.
.PARAMETER OutputDir
    The directory where final binaries will be copied. Defaults to WorkDir\firmware.
.PARAMETER SlaveChip
    The chip used as the slave (network adapter). Default: esp32c6.
#>

param(
    [string]$IdfVersion = "v5.5.2",
    [string]$WorkDir = "C:\ESP_Build_Fast",
    [string]$OutputDir = "", # If empty, defaults to $WorkDir\firmware
    [string]$SlaveChip = "esp32c6",
    [string]$ExistingIdfPath = ""
)

$ErrorActionPreference = "Stop"

# --- Helper Functions ---
function Write-Step { param([string]$msg) Write-Host "`n=== STEP: $msg ===" -ForegroundColor Cyan }
function Write-Success { param([string]$msg) Write-Host "SUCCESS: $msg" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$msg) Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# --- 0. Set Defaults ---
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $WorkDir "firmware"
}

# --- 1. Environment Setup ---
if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
Set-Location $WorkDir

Write-Step "Checking ESP-IDF Environment"
# Check/Install ESP-IDF (Only needed for the Host P4 build now)
if ([string]::IsNullOrWhiteSpace($ExistingIdfPath)) {
    $LocalIdfPath = Join-Path $WorkDir "esp-idf"
    if (-not (Test-Path $LocalIdfPath)) {
        Write-Host "Cloning ESP-IDF ($IdfVersion)..."
        # Depth 1 is much faster
        git clone --depth 1 -b $IdfVersion --recursive https://github.com/espressif/esp-idf.git
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Failed to clone ESP-IDF." }
        Set-Location $LocalIdfPath
        Write-Host "Installing Tools for esp32p4..."
        ./install.ps1 esp32p4
    } else {
        Set-Location $LocalIdfPath
    }
    $ExportScript = ".\export.ps1"
} else {
    Set-Location $ExistingIdfPath
    $ExportScript = ".\export.ps1"
}
. $ExportScript

# --- 2. Download Slave Binary ---
Write-Step "Downloading Pre-compiled Slave Firmware ($SlaveChip)"

# 1. Get Manifest
$ManifestUrl = "https://esphome.github.io/esp-hosted-firmware/manifest/${SlaveChip}.json"
try {
    $Manifest = Invoke-RestMethod -Uri $ManifestUrl -Method Get
    # Handle version array vs single object
    if ($Manifest.versions) { $Latest = $Manifest.versions[0] } else { $Latest = $Manifest }
    
    $Version = $Latest.version
    $DownloadUrl = $Latest.url
    $ExpectedHash = $Latest.sha256
    
    Write-Host "Latest Version: $Version"
    Write-Host "URL: $DownloadUrl"
} catch {
    Write-ErrorMsg "Failed to fetch manifest: $_"
}

# 2. Download Binary
$SlaveBinPath = Join-Path $WorkDir "network_adapter.bin"
Write-Host "Downloading binary..."
Invoke-WebRequest -Uri $DownloadUrl -OutFile $SlaveBinPath

# 3. Verify Checksum
Write-Host "Verifying Checksum..."
$FileHash = Get-FileHash -Path $SlaveBinPath -Algorithm SHA256
if ($FileHash.Hash.ToLower() -ne $ExpectedHash.ToLower()) {
    Write-ErrorMsg "Checksum Mismatch! Expected: $ExpectedHash, Got: $($FileHash.Hash)"
}
Write-Success "Checksum Verified ($Version)"


# --- 3. Build Host Firmware (ESP32-P4) ---
Write-Step "Setting up Host Project"

$EspHostedRepoPath = Join-Path $WorkDir "esp-hosted-mcu-repo"
if (-not (Test-Path $EspHostedRepoPath)) {
    Write-Host "Cloning esp-hosted-mcu..."
    git clone --depth 1 https://github.com/espressif/esp-hosted-mcu.git $EspHostedRepoPath
}

$HostDir = Join-Path $WorkDir "host_performs_slave_ota"
$ExampleSourcePath = Join-Path $EspHostedRepoPath "examples\host_performs_slave_ota"

# Reset Host Dir
if (Test-Path $HostDir) { Remove-Item $HostDir -Recurse -Force }
Copy-Item -Path $ExampleSourcePath -Destination $WorkDir -Recurse
Set-Location $HostDir

Write-Host "Setting target to ESP32-P4..."
idf.py set-target esp32p4

# --- 4. Embed Slave Firmware ---
Write-Step "Embedding Slave Binary"
$OtaPartitionDir = Join-Path $HostDir "components\ota_partition\slave_fw_bin"
if (-not (Test-Path $OtaPartitionDir)) { New-Item -ItemType Directory -Path $OtaPartitionDir -Force | Out-Null }

Copy-Item -Path $SlaveBinPath -Destination $OtaPartitionDir -Force
if (-not (Test-Path (Join-Path $OtaPartitionDir "network_adapter.bin"))) {
    Write-ErrorMsg "Failed to place binary in component folder."
}

# --- 5. Configure & Build ---
Write-Step "Configuring and Building Host"

# P4 + SDIO Configuration
$ConfigContent = @"
CONFIG_EXAMPLE_ESP_HOSTED_OTA_METHOD_PARTITION=y
CONFIG_EXAMPLE_ESP_HOSTED_OTA_METHOD_LITTLEFS=n
CONFIG_EXAMPLE_ESP_HOSTED_OTA_METHOD_HTTPS=n
CONFIG_EXAMPLE_ESP_HOSTED_SKIP_OTA_IF_VERSION_MATCH=n
CONFIG_ESP_HOSTED_TRANSPORT_SDIO=y
"@
Add-Content -Path (Join-Path $HostDir "sdkconfig.defaults") -Value $ConfigContent

idf.py reconfigure
idf.py build

# --- 6. Export ---
Write-Step "Exporting Artifacts"
$BuildDir = Join-Path $HostDir "build"
$HostBinPath = Join-Path $BuildDir "host_performs_slave_ota.bin"

Copy-Item (Join-Path $BuildDir "bootloader\bootloader.bin") -Destination $OutputDir
Copy-Item (Join-Path $BuildDir "partition_table\partition-table.bin") -Destination $OutputDir
Copy-Item (Join-Path $BuildDir "ota_data_initial.bin") -Destination $OutputDir
Copy-Item $HostBinPath -Destination $OutputDir
Copy-Item $SlaveBinPath -Destination $OutputDir

Write-Success "Build Artifacts saved to: $OutputDir"

# --- 7. Flashing Logic ---
Write-Step "Flash Device"

$ShouldFlash = Read-Host "Do you want to flash the device now? (y/N)"
$ComPort = "COM3" # Default placeholder for the script file

if ($ShouldFlash -match "^[Yy]") {
    $UserPort = Read-Host "Enter COM Port (e.g., COM3, COM26)"
    if (-not [string]::IsNullOrWhiteSpace($UserPort)) {
        $ComPort = $UserPort
    }
}

# Construct the Single-Line Command (Fixes ParserError)
# Using Format operator -f to insert variables cleanly
$FlashCmd = "esptool.py --chip esp32p4 -p {0} -b 460800 --before=default_reset --after=hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size 8MB 0x2000 bootloader.bin 0x10000 host_performs_slave_ota.bin 0x8000 partition-table.bin 0xd000 ota_data_initial.bin 0x5F0000 network_adapter.bin --force" -f $ComPort

# Save to file
$FlashScriptPath = Join-Path $OutputDir "flash_firmware.ps1"
Set-Content -Path $FlashScriptPath -Value $FlashCmd

if ($ShouldFlash -match "^[Yy]") {
    Write-Host "Flashing using $ComPort..."
    Set-Location $OutputDir
    
    # execute the command string directly
    Invoke-Expression $FlashCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Flashing Complete!"
    } else {
        Write-Error "Flashing failed. Check connection or boot mode."
    }
} else {
    Write-Host "Skipping flash."
    Write-Host "To flash later, run: $FlashScriptPath"
    Write-Host "(Edit the file to change COM port if needed)"
}

Write-Host "--------------------------------------------------------"