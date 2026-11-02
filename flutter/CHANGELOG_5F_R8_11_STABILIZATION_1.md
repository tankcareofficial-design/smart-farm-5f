# Smart Farm 5F R8.11 Core Recovery - Stabilization 1

- Configured ESP32-S3 N16R8 relay GPIO: 4, 5, 6, 7, 15, 16, 17, 18.
- Kept DS3231 I2C on GPIO8/GPIO9.
- Raised safe schedule runtime ceiling to 24 hours.
- Firmware recalculates schedule-window duration, including cross-midnight windows.
- Rejects equal start/end time with `invalid_schedule_window`.
- Fixed `>=` sensor stop-threshold comparison.
- Flutter rejects equal start/end before sending HTTP.
- Flutter clock baseline is re-anchored only for >=2 second drift or clock-state changes.
- Flutter version 0.8.11+101.
