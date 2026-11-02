# Test checklist — 5F R8.8 HOTFIX 1

Run:
```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

Expected analyzer result: `No issues found!`

Manual checks:
- Add/edit device dialog opens correctly.
- Sensor metric and operator dropdowns retain their initial values.
- Device runtime text still shows waiting/running/off states.
- Device ON intent still waits for schedule/condition rather than forcing relay ON.
