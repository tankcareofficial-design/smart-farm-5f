# Smart Farm Controller 5F R8.2 — Dashboard UI Refresh

## Version
- Flutter: `0.8.9+30`
- ESP32: `0.6.10-5f-r8.1-hotfix2` (unchanged)
- Protocol: `1`
- API: `2`

## Changed files
- `lib/screens/dashboard_screen.dart`
  - Reordered Dashboard presentation while preserving the current controller/state flow.
  - Added the real-data Battery/Solar presentation card.
- `lib/widgets/dashboard/dashboard_data_widgets.dart`
  - Rebuilt the main sensor grid in the visual direction of release 0.7.6.
  - Always prepares four main sensor cards: temperature, air humidity, soil moisture, and water level.
  - Missing hardware shows `ไม่มีข้อมูล`; no simulation fallback is used.
  - Added Battery/Solar card backed only by `FarmState.sensorReadings`.
  - Added relay summary based on the controller's reported relay count.
  - Preserved relay command callbacks through `DeviceStore`/`SmartFarmController`.
- `lib/widgets/dashboard/dashboard_overview_widgets.dart`
  - Refreshed the Dashboard hero presentation.
  - Preserved `FarmHealthEngine` as the only health calculation source.
- `test/widgets/dashboard/dashboard_r82_widgets_test.dart`
  - Added regression coverage ensuring energy placeholders do not invent values.
  - Added empty/disconnected hero rendering coverage.
- `pubspec.yaml`
  - Updated Flutter version to `0.8.9+30`.

## Compatibility
- No public API removed or renamed.
- No change to `FarmState`, `SmartFarmController`, stores, REST endpoints, Protocol Version, or API Version.
- Legacy getters `temperature`, `humidity`, and `soilMoisture` remain available.
- ESP32 firmware behavior is unchanged.

## Simulation policy
The Dashboard does not display simulated temperature, humidity, soil, water, battery, or solar values. Missing hardware and missing readings are explicitly shown as unavailable data.
