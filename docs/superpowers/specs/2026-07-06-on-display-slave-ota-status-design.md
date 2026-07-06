# On-Display Slave-OTA Status with Device Profiles

Date: 2026-07-06
Repo: esp32p4-c6-hosted-firmware-generator

## Problem

The generator builds a combined ESP32-P4 (host) + ESP32-C6 (slave) firmware. The
P4 host performs an OTA update of the C6 slave firmware at boot
(`host_performs_slave_ota` example). Progress and result are printed only to the
serial console. On a device with an attached LCD, the operator cannot see whether
the co-processor update succeeded without a serial monitor.

Two goals:

1. On a device that has a screen, show the slave-OTA progress and result on the
   LCD. Keep serial logging unchanged (additive).
2. Support multiple target devices from one build script: screenless boards, the
   current Waveshare P4 touch LCD, and future boards with different screens. The
   build script asks which device is being built and applies the correct display
   configuration. Adding a new device must not require editing the build script.

## Constraints and Facts

- The example project is cloned fresh and its files are overwritten on every
  build (`Build-EspHostedFirmware.ps1` copies from the cloned `esp-hosted-mcu`
  repo). Any display code must be applied as an overlay by the build script, not
  committed into the example. A fork of the example is rejected (loses upstream
  sync).
- Target board for the display case is `waveshare/esp32_p4_wifi6_touch_lcd_4b`, a
  published ESP component that provides a board support package exposing
  `bsp/esp-bsp.h`, `bsp_display_start_with_config()`, `bsp_display_lock(ms)`,
  `bsp_display_unlock()`, and an LVGL display. This is the same board the
  ESP32-P4-NINA-Display project drives; hardware bring-up is already solved by the
  BSP. Hand-rolled MIPI-DSI is rejected (fights the BSP, which integrates
  esp_lvgl_port).
- `ota_partition.c` (the partition OTA method used by the merged build) exposes no
  progress callback. Its chunk loop has `total_bytes_sent` and `firmware_size` and
  only logs. A callback must be added.
- The slave OTA runs once at boot: it proceeds only when the slave's running
  firmware differs from the embedded image; otherwise it reports "not required".
  The P4 host is effectively a one-shot updater, so a full dashboard UI is not
  needed.
- Partition layout (example `partitions.csv`): two 2 MB app slots (`ota_0` at
  0x10000, `ota_1` at 0x210000), `slave_fw` data partition at 0x5F0000, flash size
  8 MB. The merged binary places the slave image at 0x5F0000.

## Design

### Overview

Introduce a device-profile system. Each device is a folder under `devices/`
containing a manifest and, for display devices, its screen-specific configuration.
A single shared display overlay (`devices/_common-display/`) supplies the
LVGL status UI and the OTA progress patch for any LVGL-BSP device. The build
script selects a device (interactively or by parameter), then assembles the P4
host project from the cloned example plus the selected device's overlay.

### Directory layout (this repo)

```
devices/
  headless/
    device.psd1                 # HasDisplay = $false, no overlay
  waveshare-p4-touch-4b/
    device.psd1                 # BSP, sdkconfig fragment, flash geometry
    sdkconfig.device            # PSRAM, MIPI-DSI LDO, LVGL settings for this screen
  _common-display/              # shared overlay, copied for any display device
    main/main.c                 # replacement main with display instrumentation
    main/slave_ota_ui.c
    main/slave_ota_ui.h
    main/CMakeLists.txt         # contains @BSP_COMPONENT@ token
    main/idf_component.yml.in   # contains @BSP_NAME@ / @BSP_VERSION@ tokens
    components/ota_partition/ota_partition.c   # progress-callback patch
    components/ota_partition/ota_partition.h
```

### Device manifest (`device.psd1`)

PowerShell data file returning a hashtable. Fields:

- `Id` (string): stable identifier, matches folder name. Used by `-Device`.
- `Name` (string): human-readable label shown in the prompt.
- `Slave` (string): slave chip, e.g. `esp32c6`. Overrides the script default.
- `HasDisplay` (bool): whether to apply the display overlay.
- `Bsp` (hashtable, display devices only):
  - `Name` (string): registry path, e.g. `waveshare/esp32_p4_wifi6_touch_lcd_4b`.
  - `CmakeName` (string): component directory name used in CMake `REQUIRES`,
    e.g. `esp32_p4_wifi6_touch_lcd_4b`.
  - `Version` (string): version spec, e.g. `~1.0.1`.
- `SdkconfigFragment` (string, optional): file name in the device folder appended
  to `sdkconfig.defaults`. Defaults to `sdkconfig.device` if present.
- `FlashSize` (string): e.g. `8MB`. Feeds merge/flash geometry.
- `PartitionsCsv` (string, optional): device-specific partition table; defaults to
  the example's `partitions.csv`.
- `SlaveOffset` (string, optional): slave image flash offset; defaults to
  `0x5F0000`.
- `ExtraOverlayDirs` (string[], optional): extra overlay directories copied after
  `_common-display`, for a screen that needs a custom UI layout. Later copies
  override earlier ones.

Headless manifest sets `HasDisplay = $false` and omits `Bsp`.

### Shared display UI module (`slave_ota_ui.{c,h}`)

Standalone LVGL module. No dependency on NINA themes, `app_config`, or custom
fonts; uses stock Montserrat fonts bundled with LVGL. Widgets use centered flex
layout and percentage widths so the same code adapts to round or rectangular
panels of different sizes. All widget mutations are wrapped in
`bsp_display_lock(timeout)` / `bsp_display_unlock()`.

Public API:

- `void slave_ota_ui_init(void);`
  Build the widget tree on the active screen (`lv_scr_act()`). Call after
  `bsp_display_start_with_config()`.
- `void slave_ota_ui_set_phase(const char *title, const char *detail);`
  Update the phase title and detail line (e.g. "Updating co-processor",
  "Connecting to ESP32-C6...").
- `void slave_ota_ui_set_versions(const char *host, const char *slave);`
  Show host and slave firmware versions.
- `void slave_ota_ui_show_progress(void);`
  Reveal the percentage label and progress bar, reset to 0.
- `void slave_ota_ui_set_progress(int percent);`
  Clamp 0..100, update the label and bar.
- `void slave_ota_ui_show_result(bool ok, const char *msg);`
  Show a terminal result: green title on success, red on failure, with `msg`.

Widget set: phase title label, detail label, version line label, big percentage
label, progress bar, result title label. States are shown/hidden as the flow
advances (info -> progress -> result), mirroring the pattern already proven in
NINA's `nina_ota_prompt` but far smaller.

### OTA progress patch (`ota_partition.c`)

Overlay a patched copy of the example's `ota_partition` component:

- Change the signature to
  `esp_err_t ota_partition_perform(const char *partition_label, void (*progress_cb)(int percent));`
- In the chunk transfer loop, compute
  `percent = (int)((uint64_t)total_bytes_sent * 100 / firmware_size)` and call
  `progress_cb(percent)` when the integer percent changes (throttled, to avoid
  excessive LVGL locking). Guard against `progress_cb == NULL`.
- Header updated to match. All existing `ESP_LOG` output is retained.

This is the only upstream file the overlay shadows.

### Replacement `main.c` (display devices)

Same control flow as the example, instrumented for the display and driving the
OTA progress callback:

1. `nvs_flash_init`, `esp_event_loop_create_default`.
2. `bsp_display_start_with_config(&cfg)` then `slave_ota_ui_init()`. Force at least
   one LVGL render so the screen is visible before the transfer begins.
3. `slave_ota_ui_set_phase("Updating co-processor", "Connecting to ESP32-C6...")`,
   then `esp_hosted_init()` + `esp_hosted_connect_to_slave()`.
4. Version check: read host and slave versions, call
   `slave_ota_ui_set_versions(...)`. If compatible / not required, go to result.
5. If OTA needed: `slave_ota_ui_show_progress()`, then
   `perform_slave_ota()` wired to pass a progress thunk that calls
   `slave_ota_ui_set_progress()`.
6. Result:
   - success: `slave_ota_ui_show_result(true, "Update complete - restarting")`,
     short delay, `esp_restart()` (existing behavior).
   - up to date: `slave_ota_ui_show_result(true, "Co-processor up to date vX.Y.Z")`
     and stay on screen.
   - failure: `slave_ota_ui_show_result(false, "Failed: <reason>")` and stay on
     screen.

Serial `ESP_LOG` output is unchanged throughout; the display is purely additive.

The `main/CMakeLists.txt` template lists `slave_ota_ui.c` in sources and adds the
BSP component and `lvgl` to `REQUIRES` via the `@BSP_COMPONENT@` token. The
`idf_component.yml.in` template declares the BSP and `lvgl` dependencies via the
`@BSP_NAME@` and `@BSP_VERSION@` tokens.

### Build script changes (`Build-EspHostedFirmware.ps1`)

1. Add a `-Device <id>` parameter.
2. Enumerate `devices/*/device.psd1` and load each manifest.
3. Device selection: if `-Device` is given, resolve it; otherwise print a numbered
   list of `Name` values and read the choice with `Read-Host`.
4. Set the slave chip and flash size from the selected manifest, overriding the
   script defaults.
5. After the example is copied into the host project directory, and before build:
   - If `HasDisplay`:
     - Copy `devices/_common-display/*` over the host project.
     - Copy each `ExtraOverlayDirs` entry over the host project (in order).
     - Generate `main/idf_component.yml` from `idf_component.yml.in`, substituting
       `@BSP_NAME@` and `@BSP_VERSION@` from the manifest.
     - Substitute `@BSP_COMPONENT@` in `main/CMakeLists.txt` with the manifest
       `Bsp.CmakeName`.
     - Append the device `SdkconfigFragment` to `sdkconfig.defaults`.
     - If `PartitionsCsv` is set, copy it over the project `partitions.csv`.
   - If not `HasDisplay`: copy nothing. The example builds exactly as it does
     today.
6. Keep the existing base `sdkconfig.defaults` fragment (OTA method, SDIO
   transport, flash size) applied for all devices.
7. Existing slave-embed, build, merge, and export steps unchanged. The merge and
   flash-address values read the slave offset and flash size from the manifest
   instead of hardcoded literals.

The headless device reproduces current behavior, so screenless boards and other
targets continue to build.

## Extensibility

Adding a new LVGL-BSP device is a table entry: create `devices/<new-id>/` with a
`device.psd1` (pointing at that board's BSP and CMake name) and a
`sdkconfig.device` (that screen's PSRAM/LDO/LVGL settings). The shared
`_common-display` overlay and UI are reused unchanged. A device whose screen needs
a bespoke layout adds overlay files under its own folder and lists them in
`ExtraOverlayDirs`; those files override the common ones. No build-script edits are
required for either case.

## Risks

- App image size: the display firmware (LVGL + BSP + esp_hosted + UI) must fit the
  2 MB `ota_0` slot. Verify the built `.bin` size after the first display build; if
  it overflows, adjust the device partition table via `PartitionsCsv`.
- sdkconfig completeness: the device `sdkconfig.device` must enable PSRAM, the
  MIPI-DSI LDO, and LVGL buffers correctly. Derived from the known-good
  ESP32-P4-NINA-Display `sdkconfig.defaults`.
- Display timing: the OTA transfer over SDIO is fast; ensure the UI is initialized
  and at least one frame is flushed before the transfer so the progress screen is
  visible. Throttle progress updates to integer-percent changes to limit LVGL lock
  contention.

## Out of Scope

- Touch interaction on the update screen (the flow is automatic; no buttons).
- Any dashboard or post-update application UI (this firmware is a one-shot
  updater).
- HTTPS or LittleFS OTA methods (the generator uses the partition method).
