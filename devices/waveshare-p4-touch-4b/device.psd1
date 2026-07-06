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
