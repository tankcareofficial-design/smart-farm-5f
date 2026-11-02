# Smart Farm 5F R8.6 HOTFIX 2 — ESP32

## Fixed

- Fixed ArduinoJson v7 compile failure in `WiFiTransport::handleClock()`.
- Removed the mixed-type ternary expression combining `nullptr` and `serialized(String(...))`.
- `chipTemperatureC` is now emitted as a JSON number rounded to two decimal places, or JSON `null` when the DS3231 temperature is unavailable.
- Updated firmware version to `0.8.0-5f-r8.6-hotfix2`.

## Compatibility

- No Flutter changes.
- API field name remains `chipTemperatureC`.
- JSON consumers continue to receive either a numeric value or `null`.
- DS3231, ClockService, automation rules, relay mapping, and persisted settings are unchanged.
