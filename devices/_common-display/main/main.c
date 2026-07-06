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
