/*
 * SPDX-FileCopyrightText: 2025 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Perform partition OTA of the slave firmware.
 * @param partition_label  Data partition holding the slave image.
 * @param progress_cb      Called with integer percent (0..100) on each change.
 *                         May be NULL.
 */
esp_err_t ota_partition_perform(const char* partition_label, void (*progress_cb)(int percent));

#ifdef __cplusplus
}
#endif
