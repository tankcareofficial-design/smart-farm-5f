# Test Checklist — 5F R8.2 HOTFIX 1

## Required static checks

- [ ] `dart format .`
- [ ] `flutter analyze` → No issues found
- [ ] `flutter test` → All tests passed

## Dashboard sensor cards

- [ ] Fresh install with zero configured sensors still shows Temperature, Air humidity, Soil moisture, and Water level cards.
- [ ] Each missing sensor shows `ไม่มีข้อมูล` and does not show a simulated number.
- [ ] While SensorStore is loading, the cards remain visible.
- [ ] After adding a sensor configuration, its card remains visible before physical wiring.
- [ ] Enabled but unread sensor shows `รอข้อมูลจริง`.
- [ ] Disabled sensor shows `ปิดใช้งาน`.
- [ ] Controller offline shows `Controller ออฟไลน์`.

## Dashboard stability

- [ ] Open Dashboard repeatedly and switch tabs at least 30 times without a blank white page.
- [ ] Pull to refresh while ESP32 is offline; Dashboard remains rendered.
- [ ] Disconnect/reconnect Wi-Fi while Dashboard is open; last usable state remains visible.
- [ ] A transient state error shows a warning card instead of a blank page.

## Regression

- [ ] Battery and Solar cards remain visible with `ไม่มีข้อมูล` when INA226 is absent.
- [ ] Relay controls still route through DeviceStore/SmartFarmController.
- [ ] Emergency banner and emergency command still work.
- [ ] Devices, Sensors, Automation, and Settings pages are unchanged.
