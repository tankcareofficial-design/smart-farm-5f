# Test checklist — Smart Farm 5F R8.3

- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes.
- [ ] Dashboard opens without a white screen at widths 320, 360, 393, 412 and 600 px.
- [ ] With no sensors connected, temperature/humidity/soil cards show no data.
- [ ] Accessory card uses simple names and shows “ยังไม่ได้เสียบ”.
- [ ] `/api/device` and `/api/state` with no `accessories` field still work.
- [ ] Eight control channels remain visible.
- [ ] Farm readiness does not show a score without real sensor evidence.
- [ ] Emergency stop changes readiness to emergency.
