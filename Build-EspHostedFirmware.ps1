<#
.SYNOPSIS
    Fast build script for Waveshare ESP32-P4 + ESP32-C6.
    Builds both Slave (ESP32-C6) and Host (ESP32-P4) firmware from source
    to ensure version compatibility.

.DESCRIPTION
    1. Sets up ESP-IDF environment (installs tools for P4 and C6).
    2. Clones the ESP-Hosted-MCU repository.
    3. Builds the Slave Firmware (ESP32-C6) from source.
    4. Builds the Host Firmware (ESP32-P4) with the embedded slave binary.
    5. Exports flashable artifacts.
    6. (Optional) Flashes the device immediately.

.PARAMETER IdfVersion
    The ESP-IDF version to use for the HOST build (Default: v5.5.2)
.PARAMETER WorkDir
    The directory where projects will be downloaded and built.
.PARAMETER OutputDir
    The directory where final binaries will be copied. Defaults to WorkDir\firmware.
.PARAMETER SlaveChip
    The chip used as the slave (network adapter). Default: esp32c6.
.PARAMETER EspHostedRef
    The esp-hosted-mcu branch, tag, or commit to build from. Default: main.
#>

param(
    [string]$IdfVersion = "v5.5.2",
    [string]$WorkDir = "C:\ESP_Build_Fast",
    [string]$OutputDir = "", # If empty, defaults to $WorkDir\firmware
    [string]$SlaveChip = "esp32c6",
    [string]$ExistingIdfPath = "",
    [string]$EspHostedRef = "main",
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$env:PYTHONIOENCODING = "utf-8"

. "$PSScriptRoot/tools/Load-DeviceProfiles.ps1"
$DevicesRoot = Join-Path $PSScriptRoot "devices"
$AllProfiles = Get-DeviceProfiles -DevicesRoot $DevicesRoot
$Profile = Select-DeviceProfile -Profiles $AllProfiles -DeviceId $Device
Write-Host "Target device: $($Profile.Name) [$($Profile.Id)]" -ForegroundColor Green
$SlaveChip = $Profile.Slave

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
# Check/Install ESP-IDF (Needed for both Host and Slave builds)
if ([string]::IsNullOrWhiteSpace($ExistingIdfPath)) {
    $SafeVersion = $IdfVersion -replace '[\\/]', '_'
    $LocalIdfPath = Join-Path $WorkDir "esp-idf-$SafeVersion"
    if (-not (Test-Path $LocalIdfPath)) {
        Write-Host "Cloning ESP-IDF ($IdfVersion)..."
        # Depth 1 is much faster
        git clone --depth 1 -b $IdfVersion --recursive https://github.com/espressif/esp-idf.git $LocalIdfPath
        if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Failed to clone ESP-IDF." }
        Set-Location $LocalIdfPath
        
        Write-Host "Installing Tools for esp32p4 and $SlaveChip..."
        # Install tools for both host (p4) and slave (c6)
        ./install.ps1 "esp32p4,$SlaveChip"
    } else {
        Set-Location $LocalIdfPath
    }
    $ExportScript = ".\export.ps1"
} else {
    Set-Location $ExistingIdfPath
    $ExportScript = ".\export.ps1"
}
. $ExportScript

# --- 2. Clone ESP-Hosted Repo ---
Write-Step "Cloning ESP-Hosted Repository"
$EspHostedRepoPath = Join-Path $WorkDir "esp-hosted-mcu-repo"
if (-not (Test-Path $EspHostedRepoPath)) {
    Write-Host "Cloning esp-hosted-mcu (ref: $EspHostedRef)..."
    git clone --depth 1 -b $EspHostedRef https://github.com/espressif/esp-hosted-mcu.git $EspHostedRepoPath
} else {
    Write-Host "ESP-Hosted repo exists. Updating to latest $EspHostedRef..."
    git -C $EspHostedRepoPath fetch --depth 1 origin $EspHostedRef
    git -C $EspHostedRepoPath checkout FETCH_HEAD
}

# --- 3. Build Slave Firmware (ESP32-C6) ---
Write-Step "Building Slave Firmware ($SlaveChip)"

# Fix: Copy common directory which is required by slave build (expects ../common)
$CommonSourcePath = Join-Path $EspHostedRepoPath "common"
$CommonDestPath = Join-Path $WorkDir "common"
if (Test-Path $CommonSourcePath) {
    if (Test-Path $CommonDestPath) { Remove-Item $CommonDestPath -Recurse -Force }
    Copy-Item -Path $CommonSourcePath -Destination $CommonDestPath -Recurse -Force
} else {
    Write-ErrorMsg "Common source not found at $CommonSourcePath"
}

$SlaveBuildDir = Join-Path $WorkDir "slave_build"
$SlaveSourcePath = Join-Path $EspHostedRepoPath "slave"

# Ensure we have the source
if (-not (Test-Path $SlaveSourcePath)) {
    Write-ErrorMsg "Slave source not found at $SlaveSourcePath"
}

# Reset Slave Build Dir to ensure clean build
if (Test-Path $SlaveBuildDir) { Remove-Item $SlaveBuildDir -Recurse -Force }
Copy-Item -Path $SlaveSourcePath -Destination $SlaveBuildDir -Recurse
Set-Location $SlaveBuildDir

Write-Host "Setting target to $SlaveChip..."
idf.py set-target $SlaveChip

Write-Host "Building slave firmware..."
idf.py build

$BuiltSlaveBin = Join-Path $SlaveBuildDir "build\network_adapter.bin"
$SlaveBinPath = Join-Path $WorkDir "network_adapter.bin"

if (Test-Path $BuiltSlaveBin) {
    Copy-Item -Path $BuiltSlaveBin -Destination $SlaveBinPath -Force
    Write-Success "Slave firmware built successfully."
} else {
    Write-ErrorMsg "Slave firmware build failed. Binary not found."
}


# --- 4. Build Host Firmware (ESP32-P4) ---
Write-Step "Setting up Host Project"

$HostDir = Join-Path $WorkDir "host_performs_slave_ota"
$ExampleSourcePath = Join-Path $EspHostedRepoPath "examples\host_performs_slave_ota"

# Reset Host Dir
if (Test-Path $HostDir) { Remove-Item $HostDir -Recurse -Force }
Copy-Item -Path $ExampleSourcePath -Destination $WorkDir -Recurse
Set-Location $HostDir

# Ensure clean config start
if (Test-Path (Join-Path $HostDir "sdkconfig")) { Remove-Item (Join-Path $HostDir "sdkconfig") -Force }

# P4 + SDIO Configuration (Apply BEFORE set-target)
$ConfigContent = @"
CONFIG_OTA_METHOD_PARTITION=y
CONFIG_OTA_METHOD_LITTLEFS=n
CONFIG_OTA_METHOD_HTTPS=n
CONFIG_ESP_HOSTED_TRANSPORT_SDIO=y
"@
Add-Content -Path (Join-Path $HostDir "sdkconfig.defaults") -Value $ConfigContent
if (-not $Profile.HasDisplay) {
    Add-Content -Path (Join-Path $HostDir "sdkconfig.defaults") -Value "CONFIG_ESPTOOLPY_FLASHSIZE_8MB=y`nCONFIG_ESPTOOLPY_FLASHSIZE=`"8MB`""
}

if ($Profile.HasDisplay) {
    Write-Step "Applying display overlay for $($Profile.Id)"

    $CommonOverlay = Join-Path $DevicesRoot "_common-display"
    Copy-Item -Path (Join-Path $CommonOverlay "*") -Destination $HostDir -Recurse -Force

    # Extra per-device overlay dirs (override common), if any
    if ($Profile.ContainsKey('ExtraOverlayDirs')) {
        foreach ($rel in $Profile.ExtraOverlayDirs) {
            $src = Join-Path $Profile._Path $rel
            if (Test-Path $src) { Copy-Item -Path (Join-Path $src "*") -Destination $HostDir -Recurse -Force }
        }
    }

    # Append BSP + lvgl deps to the example's existing main/idf_component.yml
    # (preserves its esp_hosted / esp_wifi_remote / littlefs dependencies)
    $frag = Get-Content (Join-Path $HostDir "main/idf_component.yml.in") -Raw
    $frag = $frag.Replace("@BSP_NAME@", $Profile.Bsp.Name).Replace("@BSP_VERSION@", $Profile.Bsp.Version)
    Add-Content -Path (Join-Path $HostDir "main/idf_component.yml") -Value $frag
    Remove-Item (Join-Path $HostDir "main/idf_component.yml.in") -Force

    # Substitute BSP CMake name in main/CMakeLists.txt
    $cml = Get-Content (Join-Path $HostDir "main/CMakeLists.txt") -Raw
    $cml = $cml.Replace("@BSP_COMPONENT@", $Profile.Bsp.CmakeName)
    Set-Content -Path (Join-Path $HostDir "main/CMakeLists.txt") -Value $cml -Encoding utf8

    # Device partition table (optional)
    if ($Profile.ContainsKey('PartitionsCsv')) {
        Copy-Item -Path (Join-Path $Profile._Path $Profile.PartitionsCsv) -Destination (Join-Path $HostDir "partitions.csv") -Force
    }

    # Device sdkconfig fragment
    if ($Profile.ContainsKey('SdkconfigFragment')) {
        $frag = Get-Content (Join-Path $Profile._Path $Profile.SdkconfigFragment) -Raw
        Add-Content -Path (Join-Path $HostDir "sdkconfig.defaults") -Value $frag
    }
}

Write-Host "Setting target to ESP32-P4..."
idf.py set-target esp32p4
if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Host set-target failed (see build/log)." }

# --- 5. Embed Slave Firmware ---
Write-Step "Embedding Slave Binary"
$OtaPartitionDir = Join-Path $HostDir "components\ota_partition\slave_fw_bin"
if (-not (Test-Path $OtaPartitionDir)) { New-Item -ItemType Directory -Path $OtaPartitionDir -Force | Out-Null }

Copy-Item -Path $SlaveBinPath -Destination $OtaPartitionDir -Force
if (-not (Test-Path (Join-Path $OtaPartitionDir "network_adapter.bin"))) {
    Write-ErrorMsg "Failed to place binary in component folder."
}

# --- 6. Configure & Build Host ---
Write-Step "Configuring and Building Host"

idf.py build
if ($LASTEXITCODE -ne 0) { Write-ErrorMsg "Host build failed (see build/log)." }

# --- 7. Export ---
Write-Step "Exporting Artifacts"
$SlaveOffset = $Profile.SlaveOffset
$FlashSizeArg = $Profile.FlashSize
$BuildDir = Join-Path $HostDir "build"
$HostBinPath = Join-Path $BuildDir "host_performs_slave_ota.bin"

Copy-Item (Join-Path $BuildDir "bootloader\bootloader.bin") -Destination $OutputDir
Copy-Item (Join-Path $BuildDir "partition_table\partition-table.bin") -Destination $OutputDir
Copy-Item (Join-Path $BuildDir "ota_data_initial.bin") -Destination $OutputDir
Copy-Item $HostBinPath -Destination $OutputDir
Copy-Item $SlaveBinPath -Destination $OutputDir

# Create merged factory binary (single file, flash at 0x0000)
$MergedBinPath = Join-Path $OutputDir "merged-flash.bin"
Write-Host "Creating merged factory binary..."
$MergeCmd = "esptool.py --chip esp32p4 merge_bin --flash_mode dio --flash_freq 80m --flash_size $FlashSizeArg -o `"$MergedBinPath`" 0x2000 `"$(Join-Path $OutputDir 'bootloader.bin')`" 0x8000 `"$(Join-Path $OutputDir 'partition-table.bin')`" 0xd000 `"$(Join-Path $OutputDir 'ota_data_initial.bin')`" 0x10000 `"$(Join-Path $OutputDir 'host_performs_slave_ota.bin')`" $SlaveOffset `"$(Join-Path $OutputDir 'network_adapter.bin')`""
Invoke-Expression $MergeCmd
if ($LASTEXITCODE -eq 0) {
    Write-Success "Merged factory binary created: $MergedBinPath"
} else {
    Write-Host "WARNING: Failed to create merged binary. Individual files are still available." -ForegroundColor Yellow
}

Write-Success "Build Artifacts saved to: $OutputDir"

# --- 7b. Print Versions ---
Write-Step "Build Summary & Versions"

# Try to get exact IDF version
$ActualIdfVer = $IdfVersion
try {
    $IdfOut = idf.py --version
    if (-not [string]::IsNullOrWhiteSpace($IdfOut)) {
        $ActualIdfVer = $IdfOut.Trim()
    }
} catch {
    # Keep default if command fails
}

# Get ESP-Hosted Commit
$EspHostedCommit = "Unknown"
if (Test-Path (Join-Path $EspHostedRepoPath ".git")) {
    try {
        $EspHostedCommit = git -C $EspHostedRepoPath rev-parse --short HEAD
    } catch {
        $EspHostedCommit = "Git Error"
    }
}

# --- Helper to extract version from header ---
function Get-FwVersion {
    param (
        [string]$FilePath,
        [string]$Prefix
    )
    $Major = "0"; $Minor = "0"; $Patch = "0"
    if (Test-Path $FilePath) {
        $Content = Get-Content $FilePath -Raw
        if ($Content -match "#define\s+${Prefix}MAJOR_1\s+(\d+)") { $Major = $Matches[1] }
        if ($Content -match "#define\s+${Prefix}MINOR_1\s+(\d+)") { $Minor = $Matches[1] }
        if ($Content -match "#define\s+${Prefix}PATCH_1\s+(\d+)") { $Patch = $Matches[1] }
        return "$Major.$Minor.$Patch"
    }
    return "Unknown"
}

$HostVerPath = Join-Path $EspHostedRepoPath "host\esp_hosted_host_fw_ver.h"
$SlaveVerPath = Join-Path $EspHostedRepoPath "slave\main\esp_hosted_coprocessor_fw_ver.h"

$HostVersion = Get-FwVersion -FilePath $HostVerPath -Prefix "ESP_HOSTED_VERSION_"
$SlaveVersion = Get-FwVersion -FilePath $SlaveVerPath -Prefix "PROJECT_VERSION_"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "                FIRMWARE BUILD SUMMARY                  " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "ESP-IDF Version       : $ActualIdfVer"
Write-Host "ESP-Hosted-MCU Commit : $EspHostedCommit"
Write-Host "Host Version (Source) : $HostVersion"
Write-Host "Slave Version (Source): $SlaveVersion"
Write-Host "Output Directory      : $OutputDir"
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Distributable Firmware Files (flash with esptool):" -ForegroundColor Yellow
Write-Host "  Address   File" -ForegroundColor Yellow
Write-Host "  0x2000    $(Join-Path $OutputDir 'bootloader.bin')"
Write-Host "  0x8000    $(Join-Path $OutputDir 'partition-table.bin')"
Write-Host "  0xd000    $(Join-Path $OutputDir 'ota_data_initial.bin')"
Write-Host "  0x10000   $(Join-Path $OutputDir 'host_performs_slave_ota.bin')"
Write-Host "  $SlaveOffset  $(Join-Path $OutputDir 'network_adapter.bin')  (C6 slave FW)" -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Combined Factory Binary (flash at 0x0000):" -ForegroundColor Yellow
Write-Host "  $(Join-Path $OutputDir 'merged-flash.bin')" -ForegroundColor Green
Write-Host "  esptool.py --chip esp32p4 -p COMx -b 460800 write_flash 0x0 merged-flash.bin" -ForegroundColor DarkGray
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Or flash individual files:" -ForegroundColor Yellow
Write-Host "  esptool.py --chip esp32p4 -p COMx -b 460800 write_flash --flash_mode dio --flash_freq 80m --flash_size $FlashSizeArg 0x2000 bootloader.bin 0x10000 host_performs_slave_ota.bin 0x8000 partition-table.bin 0xd000 ota_data_initial.bin $SlaveOffset network_adapter.bin" -ForegroundColor DarkGray
Write-Host "========================================================`n" -ForegroundColor Cyan

# --- 8. Flashing Logic ---
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
$FlashCmd = "esptool.py --chip esp32p4 -p {0} -b 460800 --before=default_reset --after=hard_reset write_flash --flash_mode dio --flash_freq 80m --flash_size $FlashSizeArg 0x2000 bootloader.bin 0x10000 host_performs_slave_ota.bin 0x8000 partition-table.bin 0xd000 ota_data_initial.bin $SlaveOffset network_adapter.bin --force" -f $ComPort

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
        Write-Host "Starting IDF Monitor on $ComPort..."
        # idf.py monitor must be run from the project directory to decode addresses/symbols correctly
        Set-Location $HostDir
        idf.py -p $ComPort monitor
    } else {
        Write-Error "Flashing failed. Check connection or boot mode."
    }
} else {
    Write-Host "Skipping flash."
    Write-Host "To flash later, run: $FlashScriptPath"
    Write-Host "(Edit the file to change COM port if needed)"
}

Write-Host "--------------------------------------------------------"
