
```powershell
PS F:\delete> .\Build-EspHostedFirmware.ps1 -AutoDetectVersions -WorkDir "F:\delete"
```

```powershell
=== STEP: Checking ESP-IDF Environment ===
Activating ESP-IDF 5.5
Setting IDF_PATH to 'F:\delete\esp-idf'.
* Checking python version ... 3.13.9
* Checking python dependencies ... OK
* Deactivating the current ESP-IDF environment (if any) ... OK
* Establishing a new ESP-IDF environment ... OK
* Identifying shell ... powershell.exe
* Detecting outdated tools in system ... Found tools that are not used by active ESP-IDF version.
For removing old versions of amazon-corretto-11-x64-windows-jdk, ccache, cmake, espressif-ide, openocd-esp32, riscv32-esp-elf, riscv32-esp-elf-gdb, xtensa-esp-elf, xtensa-esp-elf-gdb use command 'python.exe F:\delete\esp-idf\tools\idf_tools.py uninstall'
To free up even more space, remove installation packages of those tools.
Use option python.exe F:\delete\esp-idf\tools\idf_tools.py uninstall --remove-archives.

Done! You can now compile ESP-IDF projects.
Go to the project directory and run:

  idf.py build


=== STEP: Downloading Pre-compiled Slave Firmware (esp32c6) ===
Latest Version: 2.11.4
URL: https://esphome.github.io/esp-hosted-firmware/v2.11.4/network_adapter_esp32c6.bin
Downloading binary...
Verifying Checksum...
SUCCESS: Checksum Verified (2.11.4)

=== STEP: Setting up Host Project ===
Setting target to ESP32-P4...
Adding "set-target"'s dependency "fullclean" to list of commands with default set of options.
Executing action: fullclean
Build directory 'F:\delete\host_performs_slave_ota\build' not found. Nothing to clean.
Executing action: set-target
Set Target to: esp32p4, new sdkconfig will be created.
Running cmake in directory F:\delete\host_performs_slave_ota\build
Executing "cmake -G Ninja -DPYTHON_DEPS_CHECKED=1 -DPYTHON=C:\Espressif\python_env\idf5.5_py3.13_env\Scripts\python.exe -DESP_PLATFORM=1 -DIDF_TARGET=esp32p4 -DCCACHE_ENABLE=1 F:\delete\host_performs_slave_ota"...
-- Found Git: C:/Program Files/Git/cmd/git.exe (found version "2.49.0.windows.1")
-- Component directory F:/delete/host_performs_slave_ota/components/common_ota_scripts does not contain a CMakeLists.txt file. No component will be added
-- Minimal build - OFF
-- ccache will be used for faster recompilation
-- The C compiler identification is GNU 14.2.0
-- The CXX compiler identification is GNU 14.2.0
-- The ASM compiler identification is GNU
-- Found assembler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-gcc.exe
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-gcc.exe - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-g++.exe - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- git rev-parse returned 'fatal: not a git repository (or any of the parent directories): .git'
-- Could not use 'git describe' to determine PROJECT_VER.
-- Building ESP-IDF components for target esp32p4
NOTICE: Dependencies lock doesn't exist, solving dependencies.
NOTICE: Using component placed at F:\delete\esp-idf\examples\system\console\advanced\components\cmd_nvs for dependency "cmd_nvs", specified in F:\delete\host_performs_slave_ota\main\idf_component.yml
NOTICE: Using component placed at F:\delete\esp-idf\examples\system\console\advanced\components\cmd_system for dependency "cmd_system", specified in F:\delete\host_performs_slave_ota\main\idf_component.yml
...............NOTICE: Updating lock file at F:\delete\host_performs_slave_ota\dependencies.lock
NOTICE: Processing 9 dependencies:
NOTICE: [1/9] cmd_nvs (*) (F:\delete\esp-idf\examples\system\console\advanced\components\cmd_nvs)
NOTICE: [2/9] cmd_system (*) (F:\delete\esp-idf\examples\system\console\advanced\components\cmd_system)
NOTICE: [3/9] espressif/eppp_link (1.1.4)
NOTICE: [4/9] espressif/esp_hosted (2.11.5)
NOTICE: [5/9] espressif/esp_serial_slave_link (1.1.2)
NOTICE: [6/9] espressif/esp_wifi_remote (1.3.1)
NOTICE: [7/9] espressif/wifi_remote_over_eppp (0.3.0)
NOTICE: [8/9] joltwallet/littlefs (1.20.3)
NOTICE: [9/9] idf (5.5.2)
-- ≡ƒöì LittleFS OTA: CONFIG_OTA_METHOD_LITTLEFS =
-- LittleFS OTA: Not selected, skipping firmware processing
-- Using new driver components (IDF ΓëÑ 5.0)
-- ESP-TEE is currently supported only on the esp32c6;esp32h2;esp32c5 SoCs
-- Project sdkconfig file F:/delete/host_performs_slave_ota/sdkconfig
Loading defaults file F:/delete/host_performs_slave_ota/sdkconfig.defaults...
-- Adding linker script F:/delete/esp-idf/components/riscv/ld/rom.api.ld
-- Found Python3: C:/Espressif/python_env/idf5.5_py3.13_env/Scripts/python.exe (found version "3.13.9") found components: Interpreter
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Success
-- Found Threads: TRUE
-- Performing Test C_COMPILER_SUPPORTS_WFORMAT_SIGNEDNESS
-- Performing Test C_COMPILER_SUPPORTS_WFORMAT_SIGNEDNESS - Success
-- USING O3
-- App "host_performs_slave_ota" version: 1
-- Adding linker script F:/delete/host_performs_slave_ota/build/esp-idf/esp_system/ld/memory.ld
-- Adding linker script F:/delete/host_performs_slave_ota/build/esp-idf/esp_system/ld/sections.ld.in
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.api.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.rvfp.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.wdt.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.systimer.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.version.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc-suboptimal_for_misaligned_mem.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.newlib.ld
-- Adding linker script F:/delete/esp-idf/components/soc/esp32p4/ld/esp32p4.peripherals.ld
-- Using Hosted Wi-Fi
-- Using new driver components (IDF ≥ 5.0)
-- ✓ HTTPS OTA: Using CA certificate bundle (Production mode)
-- 🔍 LittleFS OTA: CONFIG_OTA_METHOD_LITTLEFS =
-- LittleFS OTA: Not selected, skipping firmware processing
-- Component idf::espressif__esp_hosted will be linked with -Wl,--whole-archive
-- Components: app_trace app_update bootloader bootloader_support bt cmd_nvs cmd_system cmock console cxx driver efuse esp-tls esp_adc esp_app_format esp_bootloader_format esp_coex esp_common esp_driver_ana_cmpr esp_driver_bitscrambler esp_driver_cam esp_driver_dac esp_driver_gpio esp_driver_gptimer esp_driver_i2c esp_driver_i2s esp_driver_isp esp_driver_jpeg esp_driver_ledc esp_driver_mcpwm esp_driver_parlio esp_driver_pcnt esp_driver_ppa esp_driver_rmt esp_driver_sdio esp_driver_sdm esp_driver_sdmmc esp_driver_sdspi esp_driver_spi esp_driver_touch_sens esp_driver_tsens esp_driver_twai esp_driver_uart esp_driver_usb_serial_jtag esp_eth esp_event esp_gdbstub esp_hid esp_http_client esp_http_server esp_https_ota esp_https_server esp_hw_support esp_lcd esp_local_ctrl esp_mm esp_netif esp_netif_stack esp_partition esp_phy esp_pm esp_psram esp_ringbuf esp_rom esp_security esp_system esp_timer esp_vfs_console esp_wifi espcoredump espressif__eppp_link espressif__esp_hosted espressif__esp_serial_slave_link espressif__esp_wifi_remote espressif__wifi_remote_over_eppp esptool_py fatfs freertos hal heap http_parser idf_test ieee802154 joltwallet__littlefs json log lwip main mbedtls mqtt newlib nvs_flash nvs_sec_provider openthread ota_https ota_littlefs ota_partition partition_table protobuf-c protocomm pthread riscv rt sdmmc soc spi_flash spiffs tcp_transport ulp unity usb vfs wear_levelling wifi_provisioning wpa_supplicant
-- Component paths: F:/delete/esp-idf/components/app_trace F:/delete/esp-idf/components/app_update F:/delete/esp-idf/components/bootloader F:/delete/esp-idf/components/bootloader_support F:/delete/esp-idf/components/bt F:/delete/esp-idf/examples/system/console/advanced/components/cmd_nvs F:/delete/esp-idf/examples/system/console/advanced/components/cmd_system F:/delete/esp-idf/components/cmock F:/delete/esp-idf/components/console F:/delete/esp-idf/components/cxx F:/delete/esp-idf/components/driver F:/delete/esp-idf/components/efuse F:/delete/esp-idf/components/esp-tls F:/delete/esp-idf/components/esp_adc F:/delete/esp-idf/components/esp_app_format F:/delete/esp-idf/components/esp_bootloader_format F:/delete/esp-idf/components/esp_coex F:/delete/esp-idf/components/esp_common F:/delete/esp-idf/components/esp_driver_ana_cmpr F:/delete/esp-idf/components/esp_driver_bitscrambler F:/delete/esp-idf/components/esp_driver_cam F:/delete/esp-idf/components/esp_driver_dac F:/delete/esp-idf/components/esp_driver_gpio F:/delete/esp-idf/components/esp_driver_gptimer F:/delete/esp-idf/components/esp_driver_i2c F:/delete/esp-idf/components/esp_driver_i2s F:/delete/esp-idf/components/esp_driver_isp F:/delete/esp-idf/components/esp_driver_jpeg F:/delete/esp-idf/components/esp_driver_ledc F:/delete/esp-idf/components/esp_driver_mcpwm F:/delete/esp-idf/components/esp_driver_parlio F:/delete/esp-idf/components/esp_driver_pcnt F:/delete/esp-idf/components/esp_driver_ppa F:/delete/esp-idf/components/esp_driver_rmt F:/delete/esp-idf/components/esp_driver_sdio F:/delete/esp-idf/components/esp_driver_sdm F:/delete/esp-idf/components/esp_driver_sdmmc F:/delete/esp-idf/components/esp_driver_sdspi F:/delete/esp-idf/components/esp_driver_spi F:/delete/esp-idf/components/esp_driver_touch_sens F:/delete/esp-idf/components/esp_driver_tsens F:/delete/esp-idf/components/esp_driver_twai F:/delete/esp-idf/components/esp_driver_uart F:/delete/esp-idf/components/esp_driver_usb_serial_jtag F:/delete/esp-idf/components/esp_eth F:/delete/esp-idf/components/esp_event F:/delete/esp-idf/components/esp_gdbstub F:/delete/esp-idf/components/esp_hid F:/delete/esp-idf/components/esp_http_client F:/delete/esp-idf/components/esp_http_server F:/delete/esp-idf/components/esp_https_ota F:/delete/esp-idf/components/esp_https_server F:/delete/esp-idf/components/esp_hw_support F:/delete/esp-idf/components/esp_lcd F:/delete/esp-idf/components/esp_local_ctrl F:/delete/esp-idf/components/esp_mm F:/delete/esp-idf/components/esp_netif F:/delete/esp-idf/components/esp_netif_stack F:/delete/esp-idf/components/esp_partition F:/delete/esp-idf/components/esp_phy F:/delete/esp-idf/components/esp_pm F:/delete/esp-idf/components/esp_psram F:/delete/esp-idf/components/esp_ringbuf F:/delete/esp-idf/components/esp_rom F:/delete/esp-idf/components/esp_security F:/delete/esp-idf/components/esp_system F:/delete/esp-idf/components/esp_timer F:/delete/esp-idf/components/esp_vfs_console F:/delete/esp-idf/components/esp_wifi F:/delete/esp-idf/components/espcoredump F:/delete/host_performs_slave_ota/managed_components/espressif__eppp_link F:/delete/host_performs_slave_ota/managed_components/espressif__esp_hosted F:/delete/host_performs_slave_ota/managed_components/espressif__esp_serial_slave_link F:/delete/host_performs_slave_ota/managed_components/espressif__esp_wifi_remote F:/delete/host_performs_slave_ota/managed_components/espressif__wifi_remote_over_eppp F:/delete/esp-idf/components/esptool_py F:/delete/esp-idf/components/fatfs F:/delete/esp-idf/components/freertos F:/delete/esp-idf/components/hal F:/delete/esp-idf/components/heap F:/delete/esp-idf/components/http_parser F:/delete/esp-idf/components/idf_test F:/delete/esp-idf/components/ieee802154 F:/delete/host_performs_slave_ota/managed_components/joltwallet__littlefs F:/delete/esp-idf/components/json F:/delete/esp-idf/components/log F:/delete/esp-idf/components/lwip F:/delete/host_performs_slave_ota/main F:/delete/esp-idf/components/mbedtls F:/delete/esp-idf/components/mqtt F:/delete/esp-idf/components/newlib F:/delete/esp-idf/components/nvs_flash F:/delete/esp-idf/components/nvs_sec_provider F:/delete/esp-idf/components/openthread F:/delete/host_performs_slave_ota/components/ota_https F:/delete/host_performs_slave_ota/components/ota_littlefs F:/delete/host_performs_slave_ota/components/ota_partition F:/delete/esp-idf/components/partition_table F:/delete/esp-idf/components/protobuf-c F:/delete/esp-idf/components/protocomm F:/delete/esp-idf/components/pthread F:/delete/esp-idf/components/riscv F:/delete/esp-idf/components/rt F:/delete/esp-idf/components/sdmmc F:/delete/esp-idf/components/soc F:/delete/esp-idf/components/spi_flash F:/delete/esp-idf/components/spiffs F:/delete/esp-idf/components/tcp_transport F:/delete/esp-idf/components/ulp F:/delete/esp-idf/components/unity F:/delete/esp-idf/components/usb F:/delete/esp-idf/components/vfs F:/delete/esp-idf/components/wear_levelling F:/delete/esp-idf/components/wifi_provisioning F:/delete/esp-idf/components/wpa_supplicant
-- Configuring done (20.3s)
-- Generating done (0.7s)
-- Build files have been written to: F:/delete/host_performs_slave_ota/build

=== STEP: Embedding Slave Binary ===

=== STEP: Configuring and Building Host ===
Executing action: reconfigure
Running cmake in directory F:\delete\host_performs_slave_ota\build
Executing "cmake -G Ninja -DPYTHON_DEPS_CHECKED=1 -DPYTHON=C:\Espressif\python_env\idf5.5_py3.13_env\Scripts\python.exe -DESP_PLATFORM=1 -DCCACHE_ENABLE=1 F:\delete\host_performs_slave_ota"...
-- Component directory F:/delete/host_performs_slave_ota/components/common_ota_scripts does not contain a CMakeLists.txt file. No component will be added
-- Minimal build - OFF
-- ccache will be used for faster recompilation
-- git rev-parse returned 'fatal: not a git repository (or any of the parent directories): .git'
-- Could not use 'git describe' to determine PROJECT_VER.
-- Building ESP-IDF components for target esp32p4
NOTICE: Using component placed at F:\delete\esp-idf\examples\system\console\advanced\components\cmd_nvs for dependency "cmd_nvs", specified in F:\delete\host_performs_slave_ota\main\idf_component.yml
NOTICE: Using component placed at F:\delete\esp-idf\examples\system\console\advanced\components\cmd_system for dependency "cmd_system", specified in F:\delete\host_performs_slave_ota\main\idf_component.yml
NOTICE: Processing 9 dependencies:
NOTICE: [1/9] cmd_nvs (*) (F:\delete\esp-idf\examples\system\console\advanced\components\cmd_nvs)
NOTICE: [2/9] cmd_system (*) (F:\delete\esp-idf\examples\system\console\advanced\components\cmd_system)
NOTICE: [3/9] espressif/eppp_link (1.1.4)
NOTICE: [4/9] espressif/esp_hosted (2.11.5)
NOTICE: [5/9] espressif/esp_serial_slave_link (1.1.2)
NOTICE: [6/9] espressif/esp_wifi_remote (1.3.1)
NOTICE: [7/9] espressif/wifi_remote_over_eppp (0.3.0)
NOTICE: [8/9] joltwallet/littlefs (1.20.3)
NOTICE: [9/9] idf (5.5.2)
-- ≡ƒöì LittleFS OTA: CONFIG_OTA_METHOD_LITTLEFS =
-- LittleFS OTA: Not selected, skipping firmware processing
-- Using new driver components (IDF ΓëÑ 5.0)
-- ESP-TEE is currently supported only on the esp32c6;esp32h2;esp32c5 SoCs
-- Project sdkconfig file F:/delete/host_performs_slave_ota/sdkconfig
Loading defaults file F:/delete/host_performs_slave_ota/sdkconfig.defaults...
warning: unknown kconfig symbol 'EXAMPLE_ESP_HOSTED_OTA_METHOD_PARTITION' assigned to 'y' in F:/delete/host_performs_slave_ota/sdkconfig.defaults
warning: unknown kconfig symbol 'EXAMPLE_ESP_HOSTED_OTA_METHOD_LITTLEFS' assigned to 'n' in F:/delete/host_performs_slave_ota/sdkconfig.defaults
warning: unknown kconfig symbol 'EXAMPLE_ESP_HOSTED_OTA_METHOD_HTTPS' assigned to 'n' in F:/delete/host_performs_slave_ota/sdkconfig.defaults
warning: unknown kconfig symbol 'EXAMPLE_ESP_HOSTED_SKIP_OTA_IF_VERSION_MATCH' assigned to 'n' in F:/delete/host_performs_slave_ota/sdkconfig.defaults
warning: unknown kconfig symbol 'ESP_HOSTED_TRANSPORT_SDIO' assigned to 'y' in F:/delete/host_performs_slave_ota/sdkconfig.defaults
-- Adding linker script F:/delete/esp-idf/components/riscv/ld/rom.api.ld
-- USING O3
-- App "host_performs_slave_ota" version: 1
-- Adding linker script F:/delete/host_performs_slave_ota/build/esp-idf/esp_system/ld/memory.ld
-- Adding linker script F:/delete/host_performs_slave_ota/build/esp-idf/esp_system/ld/sections.ld.in
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.api.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.rvfp.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.wdt.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.systimer.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.version.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc-suboptimal_for_misaligned_mem.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.newlib.ld
-- Adding linker script F:/delete/esp-idf/components/soc/esp32p4/ld/esp32p4.peripherals.ld
-- Using Hosted Wi-Fi
-- Using new driver components (IDF ≥ 5.0)
-- ✓ HTTPS OTA: Using CA certificate bundle (Production mode)
-- 🔍 LittleFS OTA: CONFIG_OTA_METHOD_LITTLEFS =
-- LittleFS OTA: Not selected, skipping firmware processing
-- Component idf::espressif__esp_hosted will be linked with -Wl,--whole-archive
-- Components: app_trace app_update bootloader bootloader_support bt cmd_nvs cmd_system cmock console cxx driver efuse esp-tls esp_adc esp_app_format esp_bootloader_format esp_coex esp_common esp_driver_ana_cmpr esp_driver_bitscrambler esp_driver_cam esp_driver_dac esp_driver_gpio esp_driver_gptimer esp_driver_i2c esp_driver_i2s esp_driver_isp esp_driver_jpeg esp_driver_ledc esp_driver_mcpwm esp_driver_parlio esp_driver_pcnt esp_driver_ppa esp_driver_rmt esp_driver_sdio esp_driver_sdm esp_driver_sdmmc esp_driver_sdspi esp_driver_spi esp_driver_touch_sens esp_driver_tsens esp_driver_twai esp_driver_uart esp_driver_usb_serial_jtag esp_eth esp_event esp_gdbstub esp_hid esp_http_client esp_http_server esp_https_ota esp_https_server esp_hw_support esp_lcd esp_local_ctrl esp_mm esp_netif esp_netif_stack esp_partition esp_phy esp_pm esp_psram esp_ringbuf esp_rom esp_security esp_system esp_timer esp_vfs_console esp_wifi espcoredump espressif__eppp_link espressif__esp_hosted espressif__esp_serial_slave_link espressif__esp_wifi_remote espressif__wifi_remote_over_eppp esptool_py fatfs freertos hal heap http_parser idf_test ieee802154 joltwallet__littlefs json log lwip main mbedtls mqtt newlib nvs_flash nvs_sec_provider openthread ota_https ota_littlefs ota_partition partition_table protobuf-c protocomm pthread riscv rt sdmmc soc spi_flash spiffs tcp_transport ulp unity usb vfs wear_levelling wifi_provisioning wpa_supplicant
-- Component paths: F:/delete/esp-idf/components/app_trace F:/delete/esp-idf/components/app_update F:/delete/esp-idf/components/bootloader F:/delete/esp-idf/components/bootloader_support F:/delete/esp-idf/components/bt F:/delete/esp-idf/examples/system/console/advanced/components/cmd_nvs F:/delete/esp-idf/examples/system/console/advanced/components/cmd_system F:/delete/esp-idf/components/cmock F:/delete/esp-idf/components/console F:/delete/esp-idf/components/cxx F:/delete/esp-idf/components/driver F:/delete/esp-idf/components/efuse F:/delete/esp-idf/components/esp-tls F:/delete/esp-idf/components/esp_adc F:/delete/esp-idf/components/esp_app_format F:/delete/esp-idf/components/esp_bootloader_format F:/delete/esp-idf/components/esp_coex F:/delete/esp-idf/components/esp_common F:/delete/esp-idf/components/esp_driver_ana_cmpr F:/delete/esp-idf/components/esp_driver_bitscrambler F:/delete/esp-idf/components/esp_driver_cam F:/delete/esp-idf/components/esp_driver_dac F:/delete/esp-idf/components/esp_driver_gpio F:/delete/esp-idf/components/esp_driver_gptimer F:/delete/esp-idf/components/esp_driver_i2c F:/delete/esp-idf/components/esp_driver_i2s F:/delete/esp-idf/components/esp_driver_isp F:/delete/esp-idf/components/esp_driver_jpeg F:/delete/esp-idf/components/esp_driver_ledc F:/delete/esp-idf/components/esp_driver_mcpwm F:/delete/esp-idf/components/esp_driver_parlio F:/delete/esp-idf/components/esp_driver_pcnt F:/delete/esp-idf/components/esp_driver_ppa F:/delete/esp-idf/components/esp_driver_rmt F:/delete/esp-idf/components/esp_driver_sdio F:/delete/esp-idf/components/esp_driver_sdm F:/delete/esp-idf/components/esp_driver_sdmmc F:/delete/esp-idf/components/esp_driver_sdspi F:/delete/esp-idf/components/esp_driver_spi F:/delete/esp-idf/components/esp_driver_touch_sens F:/delete/esp-idf/components/esp_driver_tsens F:/delete/esp-idf/components/esp_driver_twai F:/delete/esp-idf/components/esp_driver_uart F:/delete/esp-idf/components/esp_driver_usb_serial_jtag F:/delete/esp-idf/components/esp_eth F:/delete/esp-idf/components/esp_event F:/delete/esp-idf/components/esp_gdbstub F:/delete/esp-idf/components/esp_hid F:/delete/esp-idf/components/esp_http_client F:/delete/esp-idf/components/esp_http_server F:/delete/esp-idf/components/esp_https_ota F:/delete/esp-idf/components/esp_https_server F:/delete/esp-idf/components/esp_hw_support F:/delete/esp-idf/components/esp_lcd F:/delete/esp-idf/components/esp_local_ctrl F:/delete/esp-idf/components/esp_mm F:/delete/esp-idf/components/esp_netif F:/delete/esp-idf/components/esp_netif_stack F:/delete/esp-idf/components/esp_partition F:/delete/esp-idf/components/esp_phy F:/delete/esp-idf/components/esp_pm F:/delete/esp-idf/components/esp_psram F:/delete/esp-idf/components/esp_ringbuf F:/delete/esp-idf/components/esp_rom F:/delete/esp-idf/components/esp_security F:/delete/esp-idf/components/esp_system F:/delete/esp-idf/components/esp_timer F:/delete/esp-idf/components/esp_vfs_console F:/delete/esp-idf/components/esp_wifi F:/delete/esp-idf/components/espcoredump F:/delete/host_performs_slave_ota/managed_components/espressif__eppp_link F:/delete/host_performs_slave_ota/managed_components/espressif__esp_hosted F:/delete/host_performs_slave_ota/managed_components/espressif__esp_serial_slave_link F:/delete/host_performs_slave_ota/managed_components/espressif__esp_wifi_remote F:/delete/host_performs_slave_ota/managed_components/espressif__wifi_remote_over_eppp F:/delete/esp-idf/components/esptool_py F:/delete/esp-idf/components/fatfs F:/delete/esp-idf/components/freertos F:/delete/esp-idf/components/hal F:/delete/esp-idf/components/heap F:/delete/esp-idf/components/http_parser F:/delete/esp-idf/components/idf_test F:/delete/esp-idf/components/ieee802154 F:/delete/host_performs_slave_ota/managed_components/joltwallet__littlefs F:/delete/esp-idf/components/json F:/delete/esp-idf/components/log F:/delete/esp-idf/components/lwip F:/delete/host_performs_slave_ota/main F:/delete/esp-idf/components/mbedtls F:/delete/esp-idf/components/mqtt F:/delete/esp-idf/components/newlib F:/delete/esp-idf/components/nvs_flash F:/delete/esp-idf/components/nvs_sec_provider F:/delete/esp-idf/components/openthread F:/delete/host_performs_slave_ota/components/ota_https F:/delete/host_performs_slave_ota/components/ota_littlefs F:/delete/host_performs_slave_ota/components/ota_partition F:/delete/esp-idf/components/partition_table F:/delete/esp-idf/components/protobuf-c F:/delete/esp-idf/components/protocomm F:/delete/esp-idf/components/pthread F:/delete/esp-idf/components/riscv F:/delete/esp-idf/components/rt F:/delete/esp-idf/components/sdmmc F:/delete/esp-idf/components/soc F:/delete/esp-idf/components/spi_flash F:/delete/esp-idf/components/spiffs F:/delete/esp-idf/components/tcp_transport F:/delete/esp-idf/components/ulp F:/delete/esp-idf/components/unity F:/delete/esp-idf/components/usb F:/delete/esp-idf/components/vfs F:/delete/esp-idf/components/wear_levelling F:/delete/esp-idf/components/wifi_provisioning F:/delete/esp-idf/components/wpa_supplicant
-- Configuring done (6.6s)
-- Generating done (0.6s)
-- Build files have been written to: F:/delete/host_performs_slave_ota/build
Executing action: all (aliases: build)
Running ninja in directory F:\delete\host_performs_slave_ota\build
Executing "ninja all"...
[93/1106] Generating ../../partition_table/partition-table.bin
Partition table binary generated. Contents:
*******************************************************************************
# ESP-IDF Partition Table
# Name, Type, SubType, Offset, Size, Flags
nvs,data,nvs,0x9000,16K,
otadata,data,ota,0xd000,8K,
phy_init,data,phy,0xf000,4K,
ota_0,app,ota_0,0x10000,2M,
ota_1,app,ota_1,0x210000,2M,
storage,data,littlefs,0x410000,1920K,
slave_fw,data,64,0x5f0000,2M,
*******************************************************************************
[860/1106] Performing configure step for 'bootloader'
-- Found Git: C:/Program Files/Git/cmd/git.exe (found version "2.49.0.windows.1")
-- Minimal build - OFF
-- The C compiler identification is GNU 14.2.0
-- The CXX compiler identification is GNU 14.2.0
-- The ASM compiler identification is GNU
-- Found assembler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-gcc.exe
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-gcc.exe - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: C:/Espressif/tools/riscv32-esp-elf/esp-14.2.0_20251107/riscv32-esp-elf/bin/riscv32-esp-elf-g++.exe - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Building ESP-IDF components for target esp32p4
-- ESP-TEE is currently supported only on the esp32c6;esp32h2;esp32c5 SoCs
-- Project sdkconfig file F:/delete/host_performs_slave_ota/sdkconfig
-- Adding linker script F:/delete/esp-idf/components/riscv/ld/rom.api.ld
-- Adding linker script F:/delete/esp-idf/components/soc/esp32p4/ld/esp32p4.peripherals.ld
-- Bootloader project name: "bootloader" version: 1
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.api.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.rvfp.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.wdt.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.systimer.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.version.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.libc-suboptimal_for_misaligned_mem.ld
-- Adding linker script F:/delete/esp-idf/components/esp_rom/esp32p4/ld/esp32p4.rom.newlib.ld
-- Adding linker script F:/delete/esp-idf/components/bootloader/subproject/main/ld/esp32p4/bootloader.rom.ld
-- Components: bootloader bootloader_support efuse esp_app_format esp_bootloader_format esp_common esp_hw_support esp_rom esp_security esp_system esptool_py freertos hal log main micro-ecc newlib partition_table riscv soc spi_flash
-- Component paths: F:/delete/esp-idf/components/bootloader F:/delete/esp-idf/components/bootloader_support F:/delete/esp-idf/components/efuse F:/delete/esp-idf/components/esp_app_format F:/delete/esp-idf/components/esp_bootloader_format F:/delete/esp-idf/components/esp_common F:/delete/esp-idf/components/esp_hw_support F:/delete/esp-idf/components/esp_rom F:/delete/esp-idf/components/esp_security F:/delete/esp-idf/components/esp_system F:/delete/esp-idf/components/esptool_py F:/delete/esp-idf/components/freertos F:/delete/esp-idf/components/hal F:/delete/esp-idf/components/log F:/delete/esp-idf/components/bootloader/subproject/main F:/delete/esp-idf/components/bootloader/subproject/components/micro-ecc F:/delete/esp-idf/components/newlib F:/delete/esp-idf/components/partition_table F:/delete/esp-idf/components/riscv F:/delete/esp-idf/components/soc F:/delete/esp-idf/components/spi_flash
-- Adding linker script F:/delete/esp-idf/components/bootloader/subproject/main/ld/esp32p4/bootloader.ld
-- Configuring done (4.9s)
-- Generating done (0.1s)
-- Build files have been written to: F:/delete/host_performs_slave_ota/build/bootloader
[132/133] Generating binary image from built executable
esptool.py v4.11.0
Creating esp32p4 image...
Merged 2 ELF sections
Successfully created esp32p4 image.
Generated F:/delete/host_performs_slave_ota/build/bootloader/bootloader.bin
[133/133] C:\WINDOWS\system32\cmd.exe /C "cd /D F:\delete\host_performs_slave_...ader 0x2000 F:/delete/host_performs_slave_ota/build/bootloader/bootloader.bin"
Bootloader binary size 0x5a30 bytes. 0x5d0 bytes (6%) free.
[1105/1106] Generating binary image from built executable
esptool.py v4.11.0
Creating esp32p4 image...
Merged 3 ELF sections
Successfully created esp32p4 image.
Generated F:/delete/host_performs_slave_ota/build/host_performs_slave_ota.bin
[1106/1106] C:\WINDOWS\system32\cmd.exe /C "cd /D F:\delete\host_performs_slav...table.bin F:/delete/host_performs_slave_ota/build/host_performs_slave_ota.bin"
host_performs_slave_ota.bin binary size 0xe9c50 bytes. Smallest app partition is 0x200000 bytes. 0x1163b0 bytes (54%) free.

Project build complete. To flash, run:
 idf.py flash
or
 idf.py -p PORT flash
or
 python -m esptool --chip esp32p4 -b 460800 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_size 8MB --flash_freq 80m 0x2000 build\bootloader\bootloader.bin 0x8000 build\partition_table\partition-table.bin 0xd000 build\ota_data_initial.bin 0x10000 build\host_performs_slave_ota.bin
or from the "F:\delete\host_performs_slave_ota\build" directory
 python -m esptool --chip esp32p4 -b 460800 --before default_reset --after hard_reset write_flash "@flash_args"

=== STEP: Exporting Artifacts ===
SUCCESS: Build Artifacts saved to: F:\delete\firmware
```


```powershell
=== STEP: Flash Device ===
Do you want to flash the device now? (y/N): y
Enter COM Port (e.g., COM3, COM26): COM26
Flashing using COM26...
esptool.py v4.11.0
Serial port COM26
Connecting....
Chip is ESP32-P4 (revision v1.0)
Features: High-Performance MCU
Crystal is 40MHz
MAC: 30:ed:a0:e1:f3:32
Uploading stub...
Running stub...
Stub running...
Changing baud rate to 460800
Changed.
Configuring flash size...
Flash will be erased from 0x00002000 to 0x00007fff...
Flash will be erased from 0x00010000 to 0x000f9fff...
Flash will be erased from 0x00008000 to 0x00008fff...
Flash will be erased from 0x0000d000 to 0x0000efff...
Flash will be erased from 0x005f0000 to 0x0070ffff...
SHA digest in image updated
Compressed 23088 bytes to 14199...
Wrote 23088 bytes (14199 compressed) at 0x00002000 in 0.6 seconds (effective 325.4 kbit/s)...
Hash of data verified.
Compressed 957520 bytes to 479545...
Wrote 957520 bytes (479545 compressed) at 0x00010000 in 11.5 seconds (effective 668.3 kbit/s)...
Hash of data verified.
Compressed 3072 bytes to 158...
Wrote 3072 bytes (158 compressed) at 0x00008000 in 0.0 seconds (effective 591.7 kbit/s)...
Hash of data verified.
Compressed 8192 bytes to 31...
Wrote 8192 bytes (31 compressed) at 0x0000d000 in 0.1 seconds (effective 889.9 kbit/s)...
Hash of data verified.
Compressed 1177008 bytes to 684675...
Wrote 1177008 bytes (684675 compressed) at 0x005f0000 in 16.1 seconds (effective 584.1 kbit/s)...
Hash of data verified.

Leaving...
Hard resetting via RTS pin...
SUCCESS: Flashing Complete!
--------------------------------------------------------
PS F:\delete\firmware> cd ..\host_performs_slave_ota\
PS F:\delete\host_performs_slave_ota> idf.py -p com26 monitor
Executing action: monitor
Running idf_monitor in directory F:\delete\host_performs_slave_ota
Executing "C:\Espressif\python_env\idf5.5_py3.13_env\Scripts\python.exe F:\delete\esp-idf\tools/idf_monitor.py -p com26 -b 115200 --toolchain-prefix riscv32-esp-elf- --target esp32p4 --revision 1 --decode-panic backtrace F:\delete\host_performs_slave_ota\build\host_performs_slave_ota.elf F:\delete\host_performs_slave_ota\build\bootloader\bootloader.elf --force-color -m 'C:\Espressif\python_env\idf5.5_py3.13_env\Scripts\python.exe' 'F:\delete\esp-idf\tools\idf.py' '-p' 'com26'"...
--- esp-idf-monitor 1.9.0 on com26 115200
--- Quit: Ctrl+] | Menu: Ctrl+T | Help: Ctrl+T followed by Ctrl+H
ESP-ROM:esp32p4-eco2-20240710
Build:Jul 10 2024
rst:0x1 (POWERON),boot:0x30f (SPI_FAST_FLASH_BOOT)
SPI mode:DIO, clock div:1
load:0x4ff33ce0,len:0x164c
load:0x4ff29ed0,len:0xe08
--- 0x4ff29ed0: esp_bootloader_get_description at F:/delete/esp-idf/components/esp_bootloader_format/esp_bootloader_desc.c:39
load:0x4ff2cbd0,len:0x3588
--- 0x4ff2cbd0: esp_flash_encryption_enabled at F:/delete/esp-idf/components/bootloader_support/src/flash_encrypt.c:89
entry 0x4ff29eda
--- 0x4ff29eda: call_start_cpu0 at F:/delete/esp-idf/components/bootloader/subproject/main/bootloader_start.c:25
I (25) boot: ESP-IDF v5.5.2 2nd stage bootloader
I (26) boot: compile time Jan 28 2026 21:00:15
I (26) boot: Multicore bootloader
I (27) boot: chip revision: v1.0
I (29) boot: efuse block revision: v0.3
I (32) boot.esp32p4: SPI Speed      : 80MHz
I (36) boot.esp32p4: SPI Mode       : DIO
I (40) boot.esp32p4: SPI Flash Size : 8MB
I (44) boot: Enabling RNG early entropy source...
I (48) boot: Partition Table:
I (51) boot: ## Label            Usage          Type ST Offset   Length
I (57) boot:  0 nvs              WiFi data        01 02 00009000 00004000
I (63) boot:  1 otadata          OTA data         01 00 0000d000 00002000
I (70) boot:  2 phy_init         RF data          01 01 0000f000 00001000
I (77) boot:  3 ota_0            OTA app          00 10 00010000 00200000
I (83) boot:  4 ota_1            OTA app          00 11 00210000 00200000
I (90) boot:  5 storage          Unknown data     01 83 00410000 001e0000
I (96) boot:  6 slave_fw         Unknown data     01 40 005f0000 00200000
I (104) boot: End of partition table
I (107) esp_image: segment 0: paddr=00010020 vaddr=40090020 size=4a9d8h (305624) map
I (165) esp_image: segment 1: paddr=0005aa00 vaddr=30100000 size=00044h (    68) load
I (167) esp_image: segment 2: paddr=0005aa4c vaddr=4ff00000 size=055cch ( 21964) load
I (175) esp_image: segment 3: paddr=00060020 vaddr=40000020 size=8b4e4h (570596) map
I (273) esp_image: segment 4: paddr=000eb50c vaddr=4ff055cc size=0bf7ch ( 49020) load
I (284) esp_image: segment 5: paddr=000f7490 vaddr=4ff11580 size=0279ch ( 10140) load
I (291) boot: Loaded app from partition at offset 0x10000
I (291) boot: Disabling RNG early entropy source...
I (303) cpu_start: Multicore app
I (314) cpu_start: GPIO 38 and 37 are used as console UART I/O pins
I (314) cpu_start: Pro cpu start user code
I (314) cpu_start: cpu freq: 360000000 Hz
I (316) app_init: Application information:
I (320) app_init: Project name:     host_performs_slave_ota
I (325) app_init: App version:      1
I (329) app_init: Compile time:     Jan 28 2026 21:00:08
I (334) app_init: ELF file SHA256:  b47c4ce05...
I (338) app_init: ESP-IDF:          v5.5.2
I (342) efuse_init: Min chip rev:     v0.1
I (346) efuse_init: Max chip rev:     v1.99
I (350) efuse_init: Chip rev:         v1.0
I (354) heap_init: Initializing. RAM available for dynamic allocation:
I (360) heap_init: At 4FF169F0 len 000245D0 (145 KiB): RETENT_RAM
I (366) heap_init: At 4FF3AFC0 len 00004BF0 (18 KiB): RAM
I (371) heap_init: At 4FF40000 len 00060000 (384 KiB): RAM
I (376) heap_init: At 50108080 len 00007F80 (31 KiB): RTCRAM
I (381) heap_init: At 30100044 len 00001FBC (7 KiB): TCM
I (387) spi_flash: detected chip: gd
I (390) spi_flash: flash io: dio
W (393) spi_flash: Detected size(32768k) larger than the size in the binary image header(8192k). Using the size in the binary image header.
I (405) host_init: ESP Hosted : Host chip_ip[18]
I (409) H_API: ESP-Hosted starting. Hosted_Tasks: prio:23, stack: 5120 RPC_task_stack: 5120
I (417) H_API: ** add_esp_wifi_remote_channels **
I (423) sleep_gpio: Configure to isolate all GPIO pins in sleep state
I (428) sleep_gpio: Enable automatic switching of GPIO sleep configuration
I (435) H_SDIO_DRV: sdio_data_to_rx_buf_task started
I (439) main_task: Started on CPU0
I (443) main_task: Calling app_main()
I (446) host_performs_slave_ota: Initializing ESP-Hosted...
I (456) H_API: ESP-Hosted Try to communicate with ESP-Hosted slave

I (457) transport: Attempt connection with slave: retry[0]
W (462) H_SDIO_DRV: Reset slave using GPIO[54]
I (467) os_wrapper_esp: GPIO [54] configured
I (1991) sdio_wrapper: SDIO master: Slot 1, Data-Lines: 4-bit Freq(KHz)[40000 KHz]
I (1991) sdio_wrapper: GPIOs: CLK[18] CMD[19] D0[14] D1[15] D2[16] D3[17] Slave_Reset[54]
I (1995) sdio_wrapper: Queues: Tx[20] Rx[20] SDIO-Rx-Mode[1]
I (2034) sdio_wrapper: Function 0 Blocksize: 512
I (2034) sdio_wrapper: Function 1 Blocksize: 512
I (2134) H_SDIO_DRV: Card init success, TRANSPORT_RX_ACTIVE
I (2134) transport: set_transport_state: 1
I (2134) transport: Waiting for esp_hosted slave to be ready
I (2135) H_SDIO_DRV: SDIO Host operating in STREAMING MODE
I (2135) H_SDIO_DRV: Starting SDIO process rx task
I (2142) H_SDIO_DRV: Open data path at slave
I (2178) H_SDIO_DRV: Received ESP_PRIV_IF type message
I (2179) transport: Received INIT event from ESP32 peripheral
I (2179) transport: EVENT: 12
I (2180) transport: Identified slave [esp32c6]
I (2185) transport: EVENT: 11
I (2187) transport: capabilities: 0xd
I (2191) transport: Features supported are:
I (2195) transport:      * WLAN
I (2197) transport:        - HCI over SDIO
I (2201) transport:        - BLE only
I (2204) transport: EVENT: 13
I (2207) transport: ESP board type is : 13

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