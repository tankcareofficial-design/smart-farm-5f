# Smart Farm 5F R8.1 Test Checklist

## Required on development machine

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

Expected analyzer output:

```text
No issues found!
```

## Compatibility tests
- [ ] Existing dashboard opens without changing Widget constructors.
- [ ] `temperature`, `humidity`, and `soilMoisture` still return values.
- [ ] `FarmState.empty` constructs successfully.
- [ ] Existing `FarmState.copyWith(...)` calls compile unchanged.
- [ ] Nullable values can be explicitly cleared with `clear...` flags.
- [ ] Legacy `controller.logs` remains readable.
- [ ] Timeline event IDs do not change when rebuilding the same state snapshot.

## ESP32 integration
- [ ] `/api/device` returns existing fields plus optional `rssi` and `freeHeap`.
- [ ] `/api/state` returns Protocol Version `1` and API Version `2`.
- [ ] Flutter and firmware report the same Protocol Version.
- [ ] Relay commands and emergency stop behave as in R8.
- [ ] Sensor getters still read temperature, humidity, and soil moisture.

## Limitations of package validation
The packaging environment did not contain Flutter SDK, Dart SDK, or Arduino CLI. Therefore `flutter analyze`, `dart format`, `flutter test`, and firmware compilation must be run on the project development machine before release acceptance.
