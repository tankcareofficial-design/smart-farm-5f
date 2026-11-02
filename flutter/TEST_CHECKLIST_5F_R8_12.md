# R8.12 Flutter test checklist

1. Run `flutter clean`, `flutter pub get`, `dart format lib`, and `flutter analyze`.
2. Add each device type and verify the suggested name follows the selected type.
3. Create a schedule and verify the device card shows start/end time and active days.
4. Verify an overnight schedule shows the overnight label.
5. Clear/reinstall the app, reconnect to the same controller, and verify cards restore from ESP32 profiles.
6. Connect to a different controller and verify its profiles replace the previous controller cache.
7. Confirm manual relay commands still control all eight channels.
