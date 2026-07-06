# On-Display Slave-OTA Status with Device Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the generator build a P4+C6 combined firmware that shows the C6 slave-OTA progress and result on the device LCD, while a build-time device selection lets the same script target screenless boards or future boards with different screens.

**Architecture:** A device-profile registry (`devices/<id>/device.psd1`) drives the build. A single shared display overlay (`devices/_common-display/`) supplies a small standalone LVGL status UI plus a progress-callback patch to the partition OTA component. The PowerShell build script selects a device, copies the example, applies the overlay (display devices only), substitutes BSP tokens, appends the device sdkconfig fragment, then builds and merges using flash geometry from the manifest.

**Tech Stack:** ESP-IDF v5.5.2, ESP-Hosted (`host_performs_slave_ota` example), LVGL 9.5, Waveshare `esp32_p4_wifi6_touch_lcd_4b` BSP, PowerShell build script on Windows.

## Global Constraints

- The example project is re-cloned and overwritten every build. All display code lives in this repo under `devices/` and is applied as an overlay by the script. Never commit changes into the cloned example.
- Serial `ESP_LOG` output must remain unchanged. The display is additive only.
- The display UI must not depend on ESP32-P4-NINA-Display code (no themes, no `app_config`, no custom fonts). Use stock LVGL Montserrat fonts.
- All LVGL widget access happens between `bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)` and `bsp_display_unlock()`. Define `LVGL_LOCK_TIMEOUT_MS` as `1000`.
- Panel is 720x720; pin it with `CONFIG_BSP_LCD_TYPE_720_720_4_INCH=y` (BSP otherwise defaults to 800x800).
- BSP display API (verified): `lv_display_t *bsp_display_start_with_config(const bsp_display_cfg_t *cfg)`, `bool bsp_display_lock(uint32_t timeout_ms)`, `void bsp_display_unlock(void)`, `void bsp_display_backlight_on(void)`. Macros: `BSP_LCD_DRAW_BUFF_SIZE`, `BSP_LCD_DRAW_BUFF_DOUBLE`, `ESP_LVGL_PORT_INIT_CONFIG()`.
- Adding a new LVGL-BSP device must require no build-script edits: a new `devices/<id>/` folder with `device.psd1` + `sdkconfig.device` only.
- Existing merged/flash addresses today: bootloader 0x2000, partition-table 0x8000, ota_data 0xd000, host app 0x10000, slave_fw at the manifest `SlaveOffset`. Chip `esp32p4`, flash mode dio, freq 80m.

---

## File Structure

New files in this repo:

- `devices/headless/device.psd1` — headless manifest (no overlay).
- `devices/waveshare-p4-touch-4b/device.psd1` — display manifest.
- `devices/waveshare-p4-touch-4b/sdkconfig.device` — screen sdkconfig fragment.
- `devices/waveshare-p4-touch-4b/partitions-16m.csv` — 16 MB layout with app slots large enough for LVGL+BSP.
- `devices/_common-display/main/slave_ota_ui.h` — UI module interface.
- `devices/_common-display/main/slave_ota_ui.c` — UI module implementation.
- `devices/_common-display/main/main.c` — replacement app entry (instrumented).
- `devices/_common-display/main/CMakeLists.txt` — main component build (has `@BSP_COMPONENT@` token).
- `devices/_common-display/main/idf_component.yml.in` — deps template (has `@BSP_NAME@`, `@BSP_VERSION@`).
- `devices/_common-display/components/ota_partition/ota_partition.h` — patched header (adds progress callback).
- `devices/_common-display/components/ota_partition/ota_partition.c` — patched source (calls callback).
- `tools/Load-DeviceProfiles.ps1` — dot-sourced helpers: enumerate/load/select device manifests. Kept separate so it can be exercised without running a full firmware build.

Modified:

- `Build-EspHostedFirmware.ps1` — device selection, overlay application, token substitution, geometry from manifest.

---

### Task 1: Device-profile loader and selection helpers

**Files:**
- Create: `tools/Load-DeviceProfiles.ps1`
- Create: `devices/headless/device.psd1`
- Create: `devices/waveshare-p4-touch-4b/device.psd1`
- Test: `tools/Test-DeviceProfiles.ps1` (throwaway verification script)

**Interfaces:**
- Produces:
  - `Get-DeviceProfiles([string]$DevicesRoot)` -> array of hashtables, each with an added `Id` (folder name) and `_Path` (device folder full path).
  - `Select-DeviceProfile([array]$Profiles, [string]$DeviceId)` -> single profile hashtable. If `$DeviceId` is empty and the host is interactive, prints a numbered menu and reads a choice; if `$DeviceId` is given, resolves by `Id` (case-insensitive) or throws.
  - Manifest schema (hashtable returned by each `device.psd1`): keys `Name` (string), `Slave` (string), `HasDisplay` (bool), `FlashSize` (string), `SlaveOffset` (string). Display manifests also have `Bsp` (hashtable: `Name`, `CmakeName`, `Version`), `SdkconfigFragment` (string, file name), and optional `PartitionsCsv` (string, file name), optional `ExtraOverlayDirs` (string[]).

- [ ] **Step 1: Write the headless manifest**

Create `devices/headless/device.psd1`:

```powershell
@{
    Name        = 'Headless / no display (serial console only)'
    Slave       = 'esp32c6'
    HasDisplay  = $false
    FlashSize   = '8MB'
    SlaveOffset = '0x5F0000'
}
```

- [ ] **Step 2: Write the Waveshare display manifest**

Create `devices/waveshare-p4-touch-4b/device.psd1`:

```powershell
@{
    Name              = 'Waveshare ESP32-P4 WiFi6 Touch LCD 4B (720x720 round, 4-inch)'
    Slave             = 'esp32c6'
    HasDisplay        = $true
    FlashSize         = '16MB'
    SlaveOffset       = '0xB00000'
    SdkconfigFragment = 'sdkconfig.device'
    PartitionsCsv     = 'partitions-16m.csv'
    Bsp = @{
        Name      = 'waveshare/esp32_p4_wifi6_touch_lcd_4b'
        CmakeName = 'esp32_p4_wifi6_touch_lcd_4b'
        Version   = '~1.0.1'
    }
}
```

- [ ] **Step 3: Write the loader helpers**

Create `tools/Load-DeviceProfiles.ps1`:

```powershell
# Dot-source into the build script. Provides device-profile discovery/selection.
Set-StrictMode -Version Latest

function Get-DeviceProfiles {
    param([Parameter(Mandatory)][string]$DevicesRoot)

    if (-not (Test-Path $DevicesRoot)) {
        throw "Devices root not found: $DevicesRoot"
    }

    $profiles = @()
    $dirs = Get-ChildItem -Path $DevicesRoot -Directory |
        Where-Object { $_.Name -notlike '_*' }   # skip shared overlay dirs like _common-display

    foreach ($dir in $dirs) {
        $manifestPath = Join-Path $dir.FullName 'device.psd1'
        if (-not (Test-Path $manifestPath)) { continue }
        $data = Import-PowerShellDataFile -Path $manifestPath
        $data.Id = $dir.Name
        $data._Path = $dir.FullName
        $profiles += $data
    }

    if ($profiles.Count -eq 0) {
        throw "No device profiles found under $DevicesRoot"
    }
    return ,$profiles
}

function Select-DeviceProfile {
    param(
        [Parameter(Mandatory)][array]$Profiles,
        [string]$DeviceId = ''
    )

    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        $match = $Profiles | Where-Object { $_.Id -ieq $DeviceId }
        if (-not $match) {
            $ids = ($Profiles | ForEach-Object { $_.Id }) -join ', '
            throw "Unknown device '$DeviceId'. Available: $ids"
        }
        return $match
    }

    Write-Host "`nSelect target device:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        Write-Host ("  [{0}] {1}" -f ($i + 1), $Profiles[$i].Name)
    }
    $choice = Read-Host "Enter number (1-$($Profiles.Count))"
    $idx = 0
    if (-not [int]::TryParse($choice, [ref]$idx) -or $idx -lt 1 -or $idx -gt $Profiles.Count) {
        throw "Invalid selection: $choice"
    }
    return $Profiles[$idx - 1]
}
```

- [ ] **Step 4: Write the verification script**

Create `tools/Test-DeviceProfiles.ps1`:

```powershell
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/Load-DeviceProfiles.ps1"

$root = Join-Path (Split-Path $PSScriptRoot -Parent) 'devices'
$profiles = Get-DeviceProfiles -DevicesRoot $root

$ids = ($profiles | ForEach-Object { $_.Id }) | Sort-Object
if (($ids -join ',') -ne 'headless,waveshare-p4-touch-4b') {
    throw "FAIL: unexpected device ids: $($ids -join ',')"
}

$hl = Select-DeviceProfile -Profiles $profiles -DeviceId 'headless'
if ($hl.HasDisplay -ne $false) { throw "FAIL: headless HasDisplay should be false" }

$ws = Select-DeviceProfile -Profiles $profiles -DeviceId 'waveshare-p4-touch-4b'
if ($ws.HasDisplay -ne $true) { throw "FAIL: waveshare HasDisplay should be true" }
if ($ws.Bsp.CmakeName -ne 'esp32_p4_wifi6_touch_lcd_4b') { throw "FAIL: bad CmakeName" }

try {
    Select-DeviceProfile -Profiles $profiles -DeviceId 'nope' | Out-Null
    throw "FAIL: unknown device did not throw"
} catch {
    if ($_.Exception.Message -notlike 'Unknown device*') { throw }
}

Write-Host 'PASS: device profile loader' -ForegroundColor Green
```

- [ ] **Step 5: Run the verification and confirm it passes**

Run (PowerShell):
```
powershell -ExecutionPolicy Bypass -File tools/Test-DeviceProfiles.ps1
```
Expected: `PASS: device profile loader`

- [ ] **Step 6: Commit**

```
git add tools/Load-DeviceProfiles.ps1 tools/Test-DeviceProfiles.ps1 devices/headless/device.psd1 devices/waveshare-p4-touch-4b/device.psd1
git commit -m "Add device-profile registry and loader"
```

---

### Task 2: Standalone LVGL slave-OTA status UI module

**Files:**
- Create: `devices/_common-display/main/slave_ota_ui.h`
- Create: `devices/_common-display/main/slave_ota_ui.c`

**Interfaces:**
- Consumes: BSP display API and LVGL (available at compile time in the assembled project).
- Produces (used by `main.c` in Task 4):
  - `void slave_ota_ui_init(void);`
  - `void slave_ota_ui_set_phase(const char *title, const char *detail);`
  - `void slave_ota_ui_set_versions(const char *host, const char *slave);`
  - `void slave_ota_ui_show_progress(void);`
  - `void slave_ota_ui_set_progress(int percent);`
  - `void slave_ota_ui_show_result(bool ok, const char *msg);`

- [ ] **Step 1: Write the header**

Create `devices/_common-display/main/slave_ota_ui.h`:

```c
#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* LVGL lock timeout for all widget access (ms). */
#define LVGL_LOCK_TIMEOUT_MS 1000

/* Build the status widget tree on the active LVGL screen.
 * Call once after bsp_display_start_with_config(). */
void slave_ota_ui_init(void);

/* Set the large phase title and the smaller detail line beneath it. */
void slave_ota_ui_set_phase(const char *title, const char *detail);

/* Show a "host X  ->  slave Y" version line. Pass NULL to hide it. */
void slave_ota_ui_set_versions(const char *host, const char *slave);

/* Reveal the percentage label and progress bar (reset to 0). */
void slave_ota_ui_show_progress(void);

/* Update progress (percent clamped to 0..100). */
void slave_ota_ui_set_progress(int percent);

/* Terminal result screen: green title if ok, red if not, with message body. */
void slave_ota_ui_show_result(bool ok, const char *msg);

#ifdef __cplusplus
}
#endif
```

- [ ] **Step 2: Write the implementation**

Create `devices/_common-display/main/slave_ota_ui.c`:

```c
#include "slave_ota_ui.h"
#include "bsp/esp-bsp.h"
#include "lvgl.h"
#include <stdio.h>

/* Colors (fixed palette, screen-agnostic). */
#define COL_BG       0x000000
#define COL_TEXT     0xFFFFFF
#define COL_DETAIL   0x888888
#define COL_ACCENT   0x3B82F6
#define COL_OK       0x22C55E
#define COL_FAIL     0xEF4444

static lv_obj_t *s_title;
static lv_obj_t *s_detail;
static lv_obj_t *s_versions;
static lv_obj_t *s_percent;
static lv_obj_t *s_bar;
static lv_obj_t *s_result;

static int s_last_percent = -1;

void slave_ota_ui_init(void)
{
    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) {
        return;
    }

    lv_obj_t *scr = lv_scr_act();
    lv_obj_set_style_bg_color(scr, lv_color_hex(COL_BG), 0);
    lv_obj_set_style_bg_opa(scr, LV_OPA_COVER, 0);
    lv_obj_clear_flag(scr, LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_set_flex_flow(scr, LV_FLEX_FLOW_COLUMN);
    lv_obj_set_flex_align(scr, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER, LV_FLEX_ALIGN_CENTER);
    lv_obj_set_style_pad_row(scr, 14, 0);
    lv_obj_set_style_pad_all(scr, 30, 0);

    s_title = lv_label_create(scr);
    lv_label_set_text(s_title, "Co-processor Update");
    lv_obj_set_style_text_font(s_title, &lv_font_montserrat_24, 0);
    lv_obj_set_style_text_color(s_title, lv_color_hex(COL_TEXT), 0);
    lv_obj_set_style_text_align(s_title, LV_TEXT_ALIGN_CENTER, 0);
    lv_obj_set_width(s_title, LV_PCT(90));

    s_detail = lv_label_create(scr);
    lv_label_set_text(s_detail, "Starting...");
    lv_obj_set_style_text_font(s_detail, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(s_detail, lv_color_hex(COL_DETAIL), 0);
    lv_obj_set_style_text_align(s_detail, LV_TEXT_ALIGN_CENTER, 0);
    lv_label_set_long_mode(s_detail, LV_LABEL_LONG_WRAP);
    lv_obj_set_width(s_detail, LV_PCT(85));

    s_versions = lv_label_create(scr);
    lv_label_set_text(s_versions, "");
    lv_obj_set_style_text_font(s_versions, &lv_font_montserrat_20, 0);
    lv_obj_set_style_text_color(s_versions, lv_color_hex(COL_ACCENT), 0);
    lv_obj_set_style_text_align(s_versions, LV_TEXT_ALIGN_CENTER, 0);
    lv_obj_add_flag(s_versions, LV_OBJ_FLAG_HIDDEN);

    s_percent = lv_label_create(scr);
    lv_label_set_text(s_percent, "0%");
    lv_obj_set_style_text_font(s_percent, &lv_font_montserrat_48, 0);
    lv_obj_set_style_text_color(s_percent, lv_color_hex(COL_ACCENT), 0);
    lv_obj_add_flag(s_percent, LV_OBJ_FLAG_HIDDEN);

    s_bar = lv_bar_create(scr);
    lv_obj_set_size(s_bar, LV_PCT(75), 16);
    lv_bar_set_range(s_bar, 0, 100);
    lv_bar_set_value(s_bar, 0, LV_ANIM_OFF);
    lv_obj_set_style_bg_color(s_bar, lv_color_hex(0x1A1A2E), LV_PART_MAIN);
    lv_obj_set_style_radius(s_bar, 8, LV_PART_MAIN);
    lv_obj_set_style_bg_color(s_bar, lv_color_hex(COL_ACCENT), LV_PART_INDICATOR);
    lv_obj_set_style_radius(s_bar, 8, LV_PART_INDICATOR);
    lv_obj_add_flag(s_bar, LV_OBJ_FLAG_HIDDEN);

    s_result = lv_label_create(scr);
    lv_label_set_text(s_result, "");
    lv_obj_set_style_text_font(s_result, &lv_font_montserrat_24, 0);
    lv_obj_set_style_text_color(s_result, lv_color_hex(COL_TEXT), 0);
    lv_obj_set_style_text_align(s_result, LV_TEXT_ALIGN_CENTER, 0);
    lv_label_set_long_mode(s_result, LV_LABEL_LONG_WRAP);
    lv_obj_set_width(s_result, LV_PCT(85));
    lv_obj_add_flag(s_result, LV_OBJ_FLAG_HIDDEN);

    bsp_display_unlock();
}

void slave_ota_ui_set_phase(const char *title, const char *detail)
{
    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) return;
    if (title && s_title)   lv_label_set_text(s_title, title);
    if (detail && s_detail) lv_label_set_text(s_detail, detail);
    bsp_display_unlock();
}

void slave_ota_ui_set_versions(const char *host, const char *slave)
{
    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) return;
    if (!s_versions) { bsp_display_unlock(); return; }
    if (host && slave) {
        char buf[96];
        snprintf(buf, sizeof(buf), "host %s  >>  slave %s", host, slave);
        lv_label_set_text(s_versions, buf);
        lv_obj_clear_flag(s_versions, LV_OBJ_FLAG_HIDDEN);
    } else {
        lv_obj_add_flag(s_versions, LV_OBJ_FLAG_HIDDEN);
    }
    bsp_display_unlock();
}

void slave_ota_ui_show_progress(void)
{
    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) return;
    s_last_percent = -1;
    if (s_percent) {
        lv_label_set_text(s_percent, "0%");
        lv_obj_clear_flag(s_percent, LV_OBJ_FLAG_HIDDEN);
    }
    if (s_bar) {
        lv_bar_set_value(s_bar, 0, LV_ANIM_OFF);
        lv_obj_clear_flag(s_bar, LV_OBJ_FLAG_HIDDEN);
    }
    if (s_result) lv_obj_add_flag(s_result, LV_OBJ_FLAG_HIDDEN);
    bsp_display_unlock();
}

void slave_ota_ui_set_progress(int percent)
{
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;
    if (percent == s_last_percent) return;   /* throttle: only on integer-% change */
    s_last_percent = percent;

    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) return;
    if (s_percent) {
        char buf[8];
        snprintf(buf, sizeof(buf), "%d%%", percent);
        lv_label_set_text(s_percent, buf);
    }
    if (s_bar) lv_bar_set_value(s_bar, percent, LV_ANIM_OFF);
    bsp_display_unlock();
}

void slave_ota_ui_show_result(bool ok, const char *msg)
{
    if (!bsp_display_lock(LVGL_LOCK_TIMEOUT_MS)) return;
    if (s_percent) lv_obj_add_flag(s_percent, LV_OBJ_FLAG_HIDDEN);
    if (s_bar)     lv_obj_add_flag(s_bar, LV_OBJ_FLAG_HIDDEN);
    if (s_result) {
        lv_label_set_text(s_result, msg ? msg : "");
        lv_obj_set_style_text_color(s_result,
            lv_color_hex(ok ? COL_OK : COL_FAIL), 0);
        lv_obj_clear_flag(s_result, LV_OBJ_FLAG_HIDDEN);
    }
    if (s_detail) lv_label_set_text(s_detail, ok ? "" : "See serial log for details");
    bsp_display_unlock();
}
```

- [ ] **Step 3: Static self-check of the source**

There is no host compiler for ESP target code; verify structural soundness instead.

Run (Git Bash):
```
awk '{o+=gsub(/{/,"{"); c+=gsub(/}/,"}")} END{print "braces open="o" close="c}' devices/_common-display/main/slave_ota_ui.c
```
Expected: `braces open` count equals `close` count.

Confirm each public function in the header has a definition:
```
grep -oE 'slave_ota_ui_[a-z_]+' devices/_common-display/main/slave_ota_ui.h | sort -u
grep -oE 'void slave_ota_ui_[a-z_]+\(' devices/_common-display/main/slave_ota_ui.c | sort -u
```
Expected: every name in the header appears as a definition in the `.c`.

- [ ] **Step 4: Commit**

```
git add devices/_common-display/main/slave_ota_ui.h devices/_common-display/main/slave_ota_ui.c
git commit -m "Add standalone LVGL slave-OTA status UI module"
```

---

### Task 3: Progress-callback patch for the partition OTA component

**Files:**
- Create: `devices/_common-display/components/ota_partition/ota_partition.h`
- Create: `devices/_common-display/components/ota_partition/ota_partition.c`

**Interfaces:**
- Produces:
  - `esp_err_t ota_partition_perform(const char *partition_label, void (*progress_cb)(int percent));`
  - `progress_cb` is called with the integer percent (0..100) whenever the percent changes; may be NULL.

- [ ] **Step 1: Copy the upstream component as the starting point**

The upstream files are on disk from a prior build. Copy them into the overlay:
```
mkdir -p devices/_common-display/components/ota_partition
cp "C:/ESP_Build_Fast/host_performs_slave_ota/components/ota_partition/ota_partition.h" devices/_common-display/components/ota_partition/ota_partition.h
cp "C:/ESP_Build_Fast/host_performs_slave_ota/components/ota_partition/ota_partition.c" devices/_common-display/components/ota_partition/ota_partition.c
```
If `C:/ESP_Build_Fast` is absent, run one full build of the headless device first (Task 7) to populate it, or clone `espressif/esp-hosted-mcu` and take `examples/host_performs_slave_ota/components/ota_partition`.

- [ ] **Step 2: Change the header signature**

Edit `devices/_common-display/components/ota_partition/ota_partition.h`. Find the existing declaration of `ota_partition_perform` and replace it with:

```c
/**
 * @brief Perform partition OTA of the slave firmware.
 * @param partition_label  Data partition holding the slave image.
 * @param progress_cb      Called with integer percent (0..100) on each change.
 *                         May be NULL.
 */
esp_err_t ota_partition_perform(const char* partition_label, void (*progress_cb)(int percent));
```

- [ ] **Step 3: Change the implementation signature and emit progress**

Edit `devices/_common-display/components/ota_partition/ota_partition.c`:

Change the function signature line from
```c
esp_err_t ota_partition_perform(const char* partition_label)
```
to
```c
esp_err_t ota_partition_perform(const char* partition_label, void (*progress_cb)(int percent))
```

Add a percent tracker just before the transfer loop. Find:
```c
	uint32_t total_bytes_sent = 0;
	uint32_t chunk_count = 0;

	while (offset < firmware_size) {
```
and insert an `int last_percent = -1;` declaration immediately above the `while`:
```c
	uint32_t total_bytes_sent = 0;
	uint32_t chunk_count = 0;
	int last_percent = -1;

	while (offset < firmware_size) {
```

Then find the existing progress log block inside the loop:
```c
		/* Progress indicator */
		if (chunk_count % 50 == 0) {
			ESP_LOGD(TAG, "Progress: %" PRIu32 "/%u bytes (%.1f%%)",
					total_bytes_sent, (unsigned int)firmware_size, (float)total_bytes_sent * 100 / firmware_size);
		}
```
and replace it with:
```c
		/* Progress indicator (serial log unchanged) */
		if (chunk_count % 50 == 0) {
			ESP_LOGD(TAG, "Progress: %" PRIu32 "/%u bytes (%.1f%%)",
					total_bytes_sent, (unsigned int)firmware_size, (float)total_bytes_sent * 100 / firmware_size);
		}

		/* Display progress callback: fire only when integer percent changes */
		if (progress_cb && firmware_size > 0) {
			int percent = (int)(((uint64_t)total_bytes_sent * 100) / firmware_size);
			if (percent != last_percent) {
				last_percent = percent;
				progress_cb(percent);
			}
		}
```

- [ ] **Step 4: Verify brace balance and signature**

Run (Git Bash):
```
awk '{o+=gsub(/{/,"{"); c+=gsub(/}/,"}")} END{print "open="o" close="c}' devices/_common-display/components/ota_partition/ota_partition.c
grep -n "ota_partition_perform(const char\* partition_label, void (\*progress_cb)(int percent))" devices/_common-display/components/ota_partition/ota_partition.c
```
Expected: braces balanced; the grep returns the modified signature line.

- [ ] **Step 5: Commit**

```
git add devices/_common-display/components/ota_partition/ota_partition.h devices/_common-display/components/ota_partition/ota_partition.c
git commit -m "Patch partition OTA to emit display progress callback"
```

---

### Task 4: Instrumented main.c plus main build templates

**Files:**
- Create: `devices/_common-display/main/main.c`
- Create: `devices/_common-display/main/CMakeLists.txt`
- Create: `devices/_common-display/main/idf_component.yml.in`

**Interfaces:**
- Consumes: `slave_ota_ui_*` (Task 2), `ota_partition_perform(label, cb)` (Task 3).
- Produces: a `main` component that builds against the BSP named by `@BSP_COMPONENT@` / `@BSP_NAME@` / `@BSP_VERSION@` tokens (substituted by the build script in Task 6).

- [ ] **Step 1: Write the replacement main.c**

Create `devices/_common-display/main/main.c`:

```c
/*
 * ESP-Hosted Slave OTA with on-display status.
 * Derived from the espressif host_performs_slave_ota example; serial logging
 * preserved, LCD status added. Applied as an overlay by the generator build.
 */

#include <stdio.h>
#include <inttypes.h>
#include "esp_log.h"
#include "esp_system.h"
#include "nvs_flash.h"
#include "esp_event.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_err.h"
#include "esp_hosted.h"
#include "esp_hosted_ota.h"
#include "esp_hosted_api_types.h"
#include "esp_app_desc.h"

#include "bsp/esp-bsp.h"
#include "lvgl.h"
#include "slave_ota_ui.h"
#include "ota_partition.h"

static const char *TAG = "host_slave_ota_display";

/* Progress thunk passed to the OTA component. */
static void ota_progress(int percent)
{
    slave_ota_ui_set_progress(percent);
}

/* Format a slave version struct into "M.m.p". */
static void fmt_slave_ver(const esp_hosted_coprocessor_fwver_t *v, char *out, size_t n)
{
    snprintf(out, n, "%" PRIu32 ".%" PRIu32 ".%" PRIu32, v->major1, v->minor1, v->patch1);
}

static void activate_and_restart(void)
{
    bool activate_supported = false;
    esp_hosted_coprocessor_fwver_t slave_version = {0};

    if (esp_hosted_get_coprocessor_fwversion(&slave_version) == ESP_OK) {
        if ((slave_version.major1 > 2) ||
                (slave_version.major1 == 2 && slave_version.minor1 > 5)) {
            activate_supported = true;
        }
    }
    if (activate_supported) {
        esp_err_t ret = esp_hosted_slave_ota_activate();
        if (ret == ESP_OK) {
            ESP_LOGI(TAG, "New firmware activated - slave will reboot");
        } else {
            ESP_LOGE(TAG, "Failed to activate firmware: %s", esp_err_to_name(ret));
        }
    }
    ESP_LOGW(TAG, "Restarting host to resync with slave...");
    vTaskDelay(pdMS_TO_TICKS(2500));
    esp_restart();
}

void app_main(void)
{
    /* Bring up display first so every phase is visible. */
    bsp_display_cfg_t cfg = {
        .lvgl_port_cfg = ESP_LVGL_PORT_INIT_CONFIG(),
        .buffer_size   = BSP_LCD_DRAW_BUFF_SIZE,
        .double_buffer = BSP_LCD_DRAW_BUFF_DOUBLE,
        .flags = {
            .buff_dma    = true,
            .buff_spiram = true,
            .sw_rotate   = false,
        }
    };
    bsp_display_start_with_config(&cfg);
    bsp_display_backlight_on();
    slave_ota_ui_init();
    slave_ota_ui_set_phase("Co-processor Update", "Connecting to ESP32-C6...");

    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    ESP_ERROR_CHECK(esp_hosted_init());
    ESP_ERROR_CHECK(esp_hosted_connect_to_slave());
    ESP_LOGI(TAG, "ESP-Hosted initialized successfully");

    /* Host version string from ESP-Hosted macros. */
    char host_ver[16];
    snprintf(host_ver, sizeof(host_ver), "%d.%d.%d",
             ESP_HOSTED_VERSION_MAJOR_1, ESP_HOSTED_VERSION_MINOR_1, ESP_HOSTED_VERSION_PATCH_1);

    /* Slave version (best effort). */
    char slave_ver[16] = "?";
    esp_hosted_coprocessor_fwver_t sv = {0};
    if (esp_hosted_get_coprocessor_fwversion(&sv) == ESP_OK) {
        fmt_slave_ver(&sv, slave_ver, sizeof(slave_ver));
    }
    slave_ota_ui_set_versions(host_ver, slave_ver);
    slave_ota_ui_set_phase("Co-processor Update", "Updating ESP32-C6 firmware");

    ESP_LOGI(TAG, "Starting slave OTA update...");
    slave_ota_ui_show_progress();
    int ret = ota_partition_perform(CONFIG_OTA_PARTITION_LABEL, ota_progress);

    if (ret == ESP_HOSTED_SLAVE_OTA_COMPLETED) {
        ESP_LOGI(TAG, "OTA completed successfully!");
        slave_ota_ui_set_progress(100);
        slave_ota_ui_show_result(true, "Update complete\nRestarting...");
        activate_and_restart();
    } else if (ret == ESP_HOSTED_SLAVE_OTA_NOT_REQUIRED) {
        ESP_LOGI(TAG, "OTA not required - slave firmware is up to date");
        char msg[64];
        snprintf(msg, sizeof(msg), "Co-processor up to date\nv%s", slave_ver);
        slave_ota_ui_show_result(true, msg);
    } else {
        ESP_LOGE(TAG, "OTA failed with error: %s", esp_err_to_name(ret));
        slave_ota_ui_show_result(false, "Update failed");
    }
}
```

Note: this overlay hardwires the partition OTA method (the generator always builds with `CONFIG_OTA_METHOD_PARTITION`), so the HTTPS/LittleFS branches are intentionally dropped. `CONFIG_OTA_PARTITION_LABEL` is provided by the example's Kconfig and defaults to `slave_fw`.

- [ ] **Step 2: Write the main CMakeLists with the BSP token**

Create `devices/_common-display/main/CMakeLists.txt`:

```cmake
# Assembled by the generator: @BSP_COMPONENT@ is replaced with the device BSP
# CMake component name before build.
idf_component_register(
    SRCS "main.c" "slave_ota_ui.c"
    INCLUDE_DIRS "."
    REQUIRES esp_hosted esp_timer ota_partition @BSP_COMPONENT@ lvgl
)
```

- [ ] **Step 3: Write the idf_component.yml template**

Create `devices/_common-display/main/idf_component.yml.in`:

```yaml
## Assembled by the generator. Tokens replaced before build.
dependencies:
  idf: ">=5.5"
  @BSP_NAME@:
    version: "@BSP_VERSION@"
    public: true
  lvgl/lvgl:
    version: "~9.5.0"
    public: true
```

- [ ] **Step 4: Verify structure**

Run (Git Bash):
```
awk '{o+=gsub(/{/,"{"); c+=gsub(/}/,"}")} END{print "main.c braces open="o" close="c}' devices/_common-display/main/main.c
grep -n "@BSP_COMPONENT@" devices/_common-display/main/CMakeLists.txt
grep -n "@BSP_NAME@\|@BSP_VERSION@" devices/_common-display/main/idf_component.yml.in
```
Expected: braces balanced; each token grep returns its line.

- [ ] **Step 5: Commit**

```
git add devices/_common-display/main/main.c devices/_common-display/main/CMakeLists.txt devices/_common-display/main/idf_component.yml.in
git commit -m "Add instrumented main.c and BSP-tokenized build templates"
```

---

### Task 5: Waveshare device sdkconfig fragment and partition table

**Files:**
- Create: `devices/waveshare-p4-touch-4b/sdkconfig.device`
- Create: `devices/waveshare-p4-touch-4b/partitions-16m.csv`

**Interfaces:**
- Consumes: applied by the build script (Task 6) via append (`sdkconfig.device`) and copy (`partitions-16m.csv` -> project `partitions.csv`).

- [ ] **Step 1: Write the screen sdkconfig fragment**

Create `devices/waveshare-p4-touch-4b/sdkconfig.device`. Values derived from the known-good ESP32-P4-NINA-Display config, minus the tear-avoidance/rotation path (static screen does not need it):

```
# ── Waveshare ESP32-P4 WiFi6 Touch LCD 4B display config ──
# PSRAM (required for MIPI-DSI framebuffers + LVGL buffers)
CONFIG_SPIRAM=y
CONFIG_SPIRAM_SPEED_200M=y
CONFIG_SPIRAM_XIP_FROM_PSRAM=y
CONFIG_SPIRAM_MALLOC_RESERVE_INTERNAL=16384
CONFIG_CACHE_L2_CACHE_256KB=y
CONFIG_CACHE_L2_CACHE_LINE_128B=y

# Flash size for this board
CONFIG_ESPTOOLPY_FLASHSIZE_16MB=y
CONFIG_ESPTOOLPY_FLASHSIZE="16MB"

# Pin the 4-inch 720x720 panel (BSP default is 800x800 / 3.4-inch)
CONFIG_BSP_LCD_TYPE_720_720_4_INCH=y
CONFIG_BSP_LCD_DPI_BUFFER_NUMS=2

# Stock LVGL Montserrat fonts used by slave_ota_ui.c
CONFIG_LV_FONT_MONTSERRAT_20=y
CONFIG_LV_FONT_MONTSERRAT_24=y
CONFIG_LV_FONT_MONTSERRAT_48=y

# Trim LVGL: no demos/examples in this firmware
CONFIG_LV_BUILD_EXAMPLES=n
```

- [ ] **Step 2: Write the 16 MB partition table**

Create `devices/waveshare-p4-touch-4b/partitions-16m.csv`. App slots enlarged to 4 MB so LVGL+BSP+esp_hosted fit; slave image partition matches manifest `SlaveOffset = 0xB00000`:

```
# 16 MB layout for display-enabled slave-OTA firmware
# Name,     Type, SubType,  Offset,    Size,     Flags
nvs,       data, nvs,      0x9000,    16K,
otadata,   data, ota,      0xd000,    8K,
phy_init,  data, phy,      0xf000,    4K,
ota_0,     app,  ota_0,    0x10000,   4M,
ota_1,     app,  ota_1,    0x410000,  4M,
storage,   data, littlefs, 0x810000,  0x2F0000,
slave_fw,  data, 0x40,     0xB00000,  0x200000,
```

Note: `slave_fw` offset 0xB00000 == manifest `SlaveOffset`. The `storage` region spans 0x810000..0xB00000 (2.9 MB). Total used ends at 0xD00000 (13 MB), within 16 MB.

- [ ] **Step 3: Sanity-check the offsets**

Run (Git Bash):
```
grep -n "slave_fw" devices/waveshare-p4-touch-4b/partitions-16m.csv
grep -n "SlaveOffset" devices/waveshare-p4-touch-4b/device.psd1
```
Expected: the `slave_fw` offset (`0xB00000`) and the manifest `SlaveOffset` (`0xB00000`) match.

- [ ] **Step 4: Commit**

```
git add devices/waveshare-p4-touch-4b/sdkconfig.device devices/waveshare-p4-touch-4b/partitions-16m.csv
git commit -m "Add Waveshare display device sdkconfig and 16MB partition table"
```

---

### Task 6: Wire device selection and overlay application into the build script

**Files:**
- Modify: `Build-EspHostedFirmware.ps1`

**Interfaces:**
- Consumes: `Get-DeviceProfiles`, `Select-DeviceProfile` (Task 1); overlay files (Tasks 2-5).
- Produces: an assembled host project with the display overlay applied for display devices; merge/flash geometry taken from the manifest.

- [ ] **Step 1: Add parameters and dot-source the loader**

In `Build-EspHostedFirmware.ps1`, add a `-Device` parameter to the `param(...)` block:
```powershell
    [string]$Device = "",
```
After `$ErrorActionPreference = "Stop"` near the top, dot-source the loader and resolve the profile:
```powershell
. "$PSScriptRoot/tools/Load-DeviceProfiles.ps1"
$DevicesRoot = Join-Path $PSScriptRoot "devices"
$AllProfiles = Get-DeviceProfiles -DevicesRoot $DevicesRoot
$Profile = Select-DeviceProfile -Profiles $AllProfiles -DeviceId $Device
Write-Host "Target device: $($Profile.Name) [$($Profile.Id)]" -ForegroundColor Green
$SlaveChip = $Profile.Slave
```
(The manifest now supplies `$SlaveChip`, overriding the parameter default.)

- [ ] **Step 2: Drive the base sdkconfig fragment from flash size**

Locate the block that appends `sdkconfig.defaults` (the here-string beginning `CONFIG_OTA_METHOD_PARTITION=y`). Replace the hardcoded transport/flash fragment with one that always sets the OTA method + SDIO transport, and let flash size come from the device fragment for display devices while keeping the current 8 MB for headless:
```powershell
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
```

- [ ] **Step 3: Apply the display overlay after the example is copied**

Immediately after the example is copied into `$HostDir` and before `idf.py set-target`, insert the overlay step:
```powershell
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

    # Generate idf_component.yml from template (token substitution)
    $tmpl = Get-Content (Join-Path $HostDir "main/idf_component.yml.in") -Raw
    $tmpl = $tmpl.Replace("@BSP_NAME@", $Profile.Bsp.Name).Replace("@BSP_VERSION@", $Profile.Bsp.Version)
    Set-Content -Path (Join-Path $HostDir "main/idf_component.yml") -Value $tmpl -Encoding utf8
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
```

Note: the overlay's `components/ota_partition/` overwrites the example's copy (same path), so the patched OTA component with the progress callback is the one built.

- [ ] **Step 4: Take merge/flash geometry from the manifest**

Find the `$MergeCmd` construction and the two documented `esptool.py ... write_flash` command strings. Replace the literal `0x5F0000` slave address with the manifest value. Add near the export step:
```powershell
$SlaveOffset = $Profile.SlaveOffset
$FlashSizeArg = $Profile.FlashSize
```
Then in `$MergeCmd`, replace `0x5F0000` with `$SlaveOffset` and `--flash_size 8MB` with `--flash_size $FlashSizeArg`. Do the same substitution in the `$FlashCmd` string and in the two `Write-Host` lines that print the manual flash commands (the `0x5F0000` address and the `--flash_size 8MB` flag).

- [ ] **Step 5: Verify the script parses**

Run (PowerShell):
```
powershell -NoProfile -Command "$null = [System.Management.Automation.Language.Parser]::ParseFile('Build-EspHostedFirmware.ps1', [ref]$null, [ref]$null); if ($?) { 'PARSE OK' }"
```
Expected: `PARSE OK`

- [ ] **Step 6: Verify device listing works end to end (no build)**

Run (PowerShell):
```
powershell -ExecutionPolicy Bypass -File tools/Test-DeviceProfiles.ps1
```
Expected: `PASS: device profile loader` (unchanged from Task 1 — confirms loader still consumed correctly).

- [ ] **Step 7: Commit**

```
git add Build-EspHostedFirmware.ps1
git commit -m "Wire device selection and display overlay into build script"
```

---

### Task 7: Full build verification for both devices

**Files:**
- None (build-only verification).

- [ ] **Step 1: Build the headless device (must match today's behavior)**

Run (PowerShell, from repo root):
```
powershell -ExecutionPolicy Bypass -File Build-EspHostedFirmware.ps1 -Device headless
```
When prompted to flash, answer `N`.
Expected: build completes; `FIRMWARE BUILD SUMMARY` prints; `merged-flash.bin` created; slave address shown as `0x5F0000`, flash size `8MB`.

- [ ] **Step 2: Build the display device**

Run (PowerShell):
```
powershell -ExecutionPolicy Bypass -File Build-EspHostedFirmware.ps1 -Device waveshare-p4-touch-4b
```
Answer `N` at the flash prompt.
Expected: build completes without errors; summary shows slave address `0xB00000`, flash size `16MB`.

- [ ] **Step 3: Confirm the host app fits its OTA slot**

The display build uses a 4 MB `ota_0`. Confirm the built app is under 4 MB.
Run (Git Bash):
```
ls -l "C:/ESP_Build_Fast/host_performs_slave_ota/build/host_performs_slave_ota.bin"
```
Expected: size well under 4194304 bytes. If it overflows, increase `ota_0`/`ota_1` in `partitions-16m.csv` and adjust downstream offsets + manifest `SlaveOffset`, then rebuild.

- [ ] **Step 4: Confirm the overlay was applied (not the stock example)**

Run (Git Bash):
```
grep -l "slave_ota_ui" "C:/ESP_Build_Fast/host_performs_slave_ota/main/main.c"
grep -n "esp32_p4_wifi6_touch_lcd_4b" "C:/ESP_Build_Fast/host_performs_slave_ota/main/CMakeLists.txt"
grep -n "progress_cb" "C:/ESP_Build_Fast/host_performs_slave_ota/components/ota_partition/ota_partition.c"
```
Expected: `main.c` references the UI, `CMakeLists.txt` shows the substituted BSP name, `ota_partition.c` has the callback.

- [ ] **Step 5: Commit (verification note only, if anything was adjusted)**

If `partitions-16m.csv` or manifest offsets were adjusted to fit, commit:
```
git add devices/waveshare-p4-touch-4b/partitions-16m.csv devices/waveshare-p4-touch-4b/device.psd1
git commit -m "Adjust display partition geometry to fit built app"
```
Otherwise skip.

---

### Task 8: On-device verification

**Files:**
- None (hardware verification).

- [ ] **Step 1: Flash the display firmware**

Connect the Waveshare ESP32-P4 board over USB. Re-run the display build and answer `Y` at the flash prompt, or run the emitted `flash_firmware.ps1` from the output directory with the correct COM port.

- [ ] **Step 2: Observe the screen through the update**

Expected on the LCD, without a serial monitor:
- "Co-processor Update" title with "Connecting to ESP32-C6..." then "Updating ESP32-C6 firmware".
- A `host X >> slave Y` version line.
- If an update runs: percentage climbs 0->100% with the progress bar, then a green "Update complete / Restarting..." and the device reboots.
- If already current: a green "Co-processor up to date vX.Y.Z" that stays on screen.
- On failure: a red "Update failed" that stays on screen.

- [ ] **Step 3: Confirm serial output is unchanged**

Run `idf.py -p <COM> monitor` (or the script's auto-monitor) and confirm the same `ESP_LOG` lines as before still appear. The display is additive; nothing in the serial log was removed.

- [ ] **Step 4: Final commit / branch wrap-up**

No code change expected here. If any tweak was needed (timing delay, wording), commit it with a descriptive message.

---

## Notes for the implementer

- There is no host-side unit-test harness for ESP target code. Verification is: PowerShell logic tested off-target (Task 1), structural checks on C sources (brace balance, symbol presence), successful `idf.py build`, app-size-fits check, and on-device observation.
- If `C:/ESP_Build_Fast` does not exist when Task 3 needs the upstream `ota_partition` files, run the headless build once (Task 7 Step 1) to populate the clone, then return to Task 3.
- Keep the `_common-display` overlay screen-agnostic. Anything specific to a panel belongs in that device's `sdkconfig.device` (or an `ExtraOverlayDirs` override), never in `_common-display`.
