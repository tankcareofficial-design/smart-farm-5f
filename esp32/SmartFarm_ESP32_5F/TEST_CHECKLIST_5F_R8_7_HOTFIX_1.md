# Test Checklist — ESP32 5F R8.7 HOTFIX 1

- [ ] Compile with ESP32 Arduino Core 3.3.11
- [ ] Compile with ArduinoJson 7.4.x
- [ ] Create a rule without `deviceId`; confirm fallback matches relay channel
- [ ] Update an existing rule without `deviceId`; confirm the existing ID is preserved
- [ ] Create, list, delete, and reload automation rules
- [ ] Confirm `/api/v3/snapshot` returns device runtime and rules
- [ ] Confirm RTC schedule continues while Flutter is disconnected
