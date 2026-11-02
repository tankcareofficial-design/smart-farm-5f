# Test Checklist — 5F R8.2 HOTFIX 2

- [ ] `dart format .`
- [ ] `flutter analyze` -> No issues found
- [ ] `flutter test` -> All tests passed
- [ ] Open Dashboard with zero configured sensors: four primary cards are visible.
- [ ] Add a sensor configuration without connecting hardware: the card shows `ไม่มีข้อมูล`.
- [ ] Open Dashboard while ESP32 is offline: Dashboard remains visible.
- [ ] Pull to refresh repeatedly: no white screen.
- [ ] Test 320x568 and text scale 1.5: no RenderFlex exception.
- [ ] Verify logs contain no `RenderFlex children have non-zero flex but incoming height constraints are unbounded`.
