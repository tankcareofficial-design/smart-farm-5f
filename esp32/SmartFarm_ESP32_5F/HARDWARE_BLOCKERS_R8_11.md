# Hardware blockers

1. `RELAY_PINS` is currently `-1` for all eight channels. API state can change, but no physical GPIO will switch until the real pins are configured.
2. Current target documents identify ESP32-S3 with DS3231 SDA GPIO8 and SCL GPIO9. Confirm the board is ESP32-S3. Do not use GPIO8/9 for I2C on a classic ESP32-WROOM module without checking its pinout.
3. DS3231 must answer at I2C address 0x68 and have common GND.
