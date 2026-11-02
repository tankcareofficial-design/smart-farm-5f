# R8.9 Flutter checklist
- Run `dart format lib test`.
- Run `flutter analyze` and `flutter test`.
- With no sensors added, verify Sensor mode is disabled and no fake sensor is listed.
- Add one sensor, enable it, and verify only that sensor appears in the device rule wizard.
- Verify dark theme across every device wizard step.
- Verify manual device profile sends schedule.enabled=false.
- Verify clock display and clock sync use `/api/v3/clock`.
