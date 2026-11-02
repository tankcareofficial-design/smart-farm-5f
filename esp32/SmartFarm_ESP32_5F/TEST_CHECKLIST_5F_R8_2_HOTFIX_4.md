# Test checklist — 5F R8.2 HOTFIX 4

- Build and upload ESP32 firmware.
- Boot with no soil sensor connected.
- Confirm `/api/state` reports `metrics.soilMoisture` as `null`.
- Confirm the Flutter soil-moisture card shows no data rather than a percentage.
- Leave the unit running for at least 10 minutes and confirm no soil reading appears.
- Confirm temperature and humidity remain null when SHT31 is absent.
- Confirm relay count is 8.
- Confirm no automation rule is triggered by a nonexistent soil reading.
