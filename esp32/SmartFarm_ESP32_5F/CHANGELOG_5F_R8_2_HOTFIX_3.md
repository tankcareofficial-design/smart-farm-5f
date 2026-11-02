# ESP32 5F R8.2 HOTFIX 3

- Added dependency-free SHT31 readout at I2C address 0x44.
- Uses ESP32-S3 I2C pins SDA GPIO8 and SCL GPIO9.
- Validates both SHT31 CRC bytes.
- Reports null when SHT31 is absent or invalid; no fake fallback.
- Corrected physical relay profile from 12 to 8 channels.
