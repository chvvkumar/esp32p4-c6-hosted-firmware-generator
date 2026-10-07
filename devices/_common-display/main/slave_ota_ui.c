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
