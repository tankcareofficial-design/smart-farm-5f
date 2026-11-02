# TEST CHECKLIST — 5F R8.1 HOTFIX 2

- [ ] `dart format .`
- [ ] `flutter analyze` => No issues found
- [ ] `flutter test` passes
- [ ] Sensor cards show no BOTTOM OVERFLOW at normal and large text scale
- [ ] Disconnected/no live sensors shows `--` and `Waiting for live data`
- [ ] Health score appears only after at least one configured live sensor reading
- [ ] Temperature remains `No data` until ESP32 reports a real sensor value
- [ ] Dashboard relay count shows 12 after connecting to updated firmware
- [ ] Flutter and ESP32 Protocol Version both equal 1
