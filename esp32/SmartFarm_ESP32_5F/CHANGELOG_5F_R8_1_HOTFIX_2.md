# Smart Farm ESP32 5F R8.1 HOTFIX 2

## Fixed
- Removed fallback to ESP32 `temperatureRead()` because it measures chip temperature, not farm air.
- DS3231 temperature is disabled as an ambient measurement by default.
- Temperature is now `null` until a real supported temperature sensor supplies a reading.
- Relay channel count updated from 4 to 12 for the selected 12-channel relay board.

## Compatibility
- Existing HTTP endpoints and JSON properties are unchanged.
- Protocol Version remains 1.
- API Version remains 2.
- Existing relay array format remains unchanged; only its configured channel count increases.
