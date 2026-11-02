# Smart Farm ESP32 5F R8.7 HOTFIX 1

## Fixed
- Fixed ArduinoJson v7 compilation failure caused by passing a temporary `StringSumHelper` to `JsonVariantConst::operator|`.
- Device fallback IDs are now constructed as a concrete `String`.
- Relay action data is parsed before generating the fallback device ID, so relay 2 becomes `relay-2` instead of incorrectly defaulting to `relay-1`.
- Preserves an existing device ID when updating a rule without a `deviceId` field.

## Compatibility
- No Flutter changes.
- API v3 and stored rule schema remain compatible with R8.7.
