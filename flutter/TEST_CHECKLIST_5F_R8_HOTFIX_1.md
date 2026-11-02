# Test Checklist — Smart Farm 5F R8 Hotfix 1

- [ ] Run `dart format lib/widgets/dashboard/dashboard_data_widgets.dart`
- [ ] Run `flutter analyze` and confirm `No issues found`
- [ ] Open Dashboard with a configured sensor that has live data
- [ ] Confirm sensor value, unit, and live/stale status render correctly
- [ ] Open Dashboard while Controller is offline
- [ ] Confirm `Controller offline` renders without crash
- [ ] Disable a sensor and confirm disabled state renders correctly
- [ ] Confirm legacy getters `temperature`, `humidity`, and `soilMoisture` still work
- [ ] Confirm ESP32 protocol and firmware behavior are unchanged
