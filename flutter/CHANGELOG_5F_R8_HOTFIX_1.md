# Smart Farm 5F R8 Hotfix 1

## Version
- Flutter: 0.8.6+27
- ESP32: unchanged from 5F R8
- Protocol: unchanged

## Fixed
- `lib/widgets/dashboard/dashboard_data_widgets.dart`
  - Fixed `argument_type_not_assignable` when passing `SensorReading?` to `_readingStatusText`.
  - Added a local null assertion only in the branch guarded by `hasLiveValue`.

## Compatibility
- No public API removed or renamed.
- `FarmState`, `SensorReading`, `temperature`, `humidity`, `soilMoisture`, `copyWith()`, and constructors are unchanged.
- No HTTP API or ESP32 protocol changes.
