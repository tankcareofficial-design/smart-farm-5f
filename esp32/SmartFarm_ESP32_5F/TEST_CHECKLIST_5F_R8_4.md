# R8.4 Test Checklist

- Compile for ESP32-S3.
- Confirm `/api/device` reports firmware 0.7.1 and accessory schema 2.
- Confirm 8 relay channels.
- Confirm absent sensors return null/not_installed.
- Confirm battery and solar use different deviceId, role and port values.
- Confirm R8.3 clients can ignore new fields.
