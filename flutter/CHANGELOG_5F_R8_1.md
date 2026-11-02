# Smart Farm 5F R8.1 Changelog

## Version
- Flutter: `0.8.7+28`
- Architecture checkpoint: `5F R8.1`
- Compatible ESP32 firmware: `0.6.9-5f-r8.1-stability`
- Protocol Version: `1` (unchanged)
- API Version: `2` (unchanged)

## Architecture analysis
R8.1 is a stability release. It does not change the data flow:

`ESP32 -> HTTP API -> SmartFarmController -> FarmState -> Dashboard -> Widgets`

Widgets still do not call HTTP directly. `FarmState` remains the single source of truth.

## Changed files

### `lib/controllers/smart_farm_controller.dart`
- Added additive `ControllerLogEntry` records with stable IDs and timestamps.
- Preserved the public `List<String> logs` API.
- Added read-only `logEntries` without removing legacy behavior.
- Added optional `wifiRssi` and `freeHeap` diagnostics.
- Parses optional protocol and diagnostics fields from `/api/state`.

### `lib/models/farm_state.dart`
- Uses stable controller event records for `FarmEvent` conversion.
- Keeps a compatibility fallback for callers that directly write to `logs`.
- Added optional `wifiRssi` and `freeHeap` fields.
- Extended `copyWith()` with explicit clear flags for nullable fields.
- Preserved `temperature`, `humidity`, `soilMoisture`, `empty`, and existing `copyWith()` arguments.

### `test/models/farm_state_test.dart`
- Added compatibility contract tests for legacy getters.
- Added generic sensor mapping tests.
- Added nullable clear tests.
- Added immutable event list test.

### `test/services/farm_health_engine_test.dart`
- Added health score boundary and penalty tests.

### `pubspec.yaml`
- Updated Flutter version from `0.8.6+27` to `0.8.7+28`.

## Compatibility
- No existing endpoint removed or renamed.
- No existing public property removed.
- No required constructor parameter added to existing callers.
- Protocol Version remains `1`.
