# Test Checklist

1. Run `flutter analyze` and expect `No issues found!`.
2. Open Add Device in light and dark themes.
3. Verify wizard order: type, name/relay, mode, configuration.
4. Select Schedule and verify the next page contains start time, stop time, and seven day chips.
5. Save weekday-only schedule and verify ESP32 receives daysOfWeek 1-5.
6. Select Sensor and verify the next page contains metric, operator, and target value.
7. Select Manual and verify Add Device is available on the mode page.
8. Verify device cards do not overflow on narrow screens and large text scale.
9. Verify dashboard card switch shows REQUESTED/WAITING without falsely showing relay ON.
10. Connect ESP32 with valid DS/RTC clock and verify Devices page time ticks every second.
11. Disconnect or invalidate clock and verify `--:--:--` with waiting status is shown.
