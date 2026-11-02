# Test Checklist — 5F R8.6 HOTFIX 2 ESP32

1. Open `SmartFarm_ESP32_5F_R8_1.ino` in Arduino IDE.
2. Confirm the installed ArduinoJson library is version 7.x.
3. Compile for the same ESP32 board profile used by R8.6.
4. Verify compilation no longer reports mixed operands for the conditional operator.
5. Upload firmware and open Serial Monitor.
6. Request `GET /api/v2/clock`.
7. Confirm `chipTemperatureC` is a JSON number such as `27.25` when RTC temperature is available.
8. Confirm the field becomes JSON `null` if the temperature snapshot is invalid.
9. Verify DS3231 time, clock sync, schedules, relay control, and emergency stop still operate normally.
