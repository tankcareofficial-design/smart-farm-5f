# Smart Farm 5F R8.2 HOTFIX 4 — Soil sensor false-data fix

## Root cause

The firmware configured `SOIL_SENSOR_ADC_PIN` as GPIO4 while no physical soil-moisture sensor was connected. A floating ADC input produced electrical noise, which was converted into a believable 0–100% soil-moisture value.

## Fix

- Set `SOIL_SENSOR_ADC_PIN = -1` by default.
- `StateManager::readSoilPercent()` now returns `NAN` through the existing compile-time disabled path.
- REST and serial protocol continue to expose `soilMoisture: null` when no real sensor is installed.
- No mock or fallback soil value is generated.
- Relay count remains 8.
- SHT31 support remains available but returns null when the sensor is absent.

## Compatibility

- Protocol version: 1 (unchanged)
- API version: 2 (unchanged)
- Flutter changes: none required
- Firmware version: 0.6.13-5f-r8.2-hotfix5

## Enabling a real analog soil sensor later

After installing and calibrating a capacitive analog soil sensor, set `SOIL_SENSOR_ADC_PIN` to the actual ADC-capable GPIO and update `SOIL_ADC_DRY` / `SOIL_ADC_WET` from real measurements.
