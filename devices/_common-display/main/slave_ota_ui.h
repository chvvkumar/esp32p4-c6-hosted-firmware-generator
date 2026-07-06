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
