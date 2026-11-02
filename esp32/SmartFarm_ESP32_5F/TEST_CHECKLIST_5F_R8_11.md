# R8.11 ESP32 test
1. Compile for the exact ESP32-S3 board.
2. Serial must print RTC available/valid/quality/error and all relay GPIOs.
3. GET /api/v3/clock. Verify available, valid, quality, errorCode, SDA/SCL.
4. POST /api/v3/clock/sync with phone time, then GET clock must return valid=true.
5. POST /api/relay for channels 0..7. Verify JSON and physical output after RELAY_PINS are configured.
6. Save schedule profile, restart ESP32, and verify profile persists.
