# Smart Farm Controller 5F R8.2 HOTFIX 1

## Root causes

1. `DashboardSensorGrid` replaced the complete grid with a loading indicator whenever `SensorStore.loading` was true. This violated the product requirement that supported sensor cards remain visible and show `ไม่มีข้อมูล` before hardware installation.
2. The Dashboard created a new `Listenable.merge()` during every build and had no last-known-good state fallback if state assembly or health evaluation failed transiently. A build-time exception could therefore leave the main page blank.
3. The grid only considered the four built-in preview types and did not merge configured sensor types into its visible capability list.

## Changed files

- `lib/screens/dashboard_screen.dart`
  - Converted Dashboard to a stateful widget.
  - Keeps one stable merged Listenable per dependency set.
  - Keeps the last successfully assembled `FarmState`.
  - Adds guarded state and health evaluation with Flutter error reporting.
  - Shows a non-blocking warning while retaining the usable Dashboard.
- `lib/widgets/dashboard/dashboard_data_widgets.dart`
  - Sensor cards remain visible during store loading.
  - Loading is shown as a thin progress indicator and card status text.
  - Always includes the four standard farm sensor cards.
  - Includes configured sensor types without requiring a live reading.
  - Uses finite-width fallback for defensive responsive layout.
- `pubspec.yaml`
  - Version updated to `0.8.10+31`.

## Compatibility

- No REST endpoint changed.
- No ESP32 firmware changed.
- No Protocol/API version changed.
- No public FarmState, Controller, Store, or SensorReading API removed.
- No simulated sensor values added.
