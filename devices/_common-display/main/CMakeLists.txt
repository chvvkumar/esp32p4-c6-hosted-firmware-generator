# Assembled by the generator: @BSP_COMPONENT@ is replaced with the device BSP
# CMake component name before build.
idf_component_register(
    SRCS "main.c" "slave_ota_ui.c"
    INCLUDE_DIRS "."
    REQUIRES esp_hosted esp_timer nvs_flash esp_event ota_partition esp_lvgl_port @BSP_COMPONENT@ lvgl
)
