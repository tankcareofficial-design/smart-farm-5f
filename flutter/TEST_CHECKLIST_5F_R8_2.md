# TEST CHECKLIST — Smart Farm 5F R8.2

## Static validation
- [ ] Run `dart format .`
- [ ] Run `flutter analyze`
- [ ] Confirm `No issues found!`
- [ ] Run `flutter test`
- [ ] Confirm all tests pass

## Dashboard visual validation
- [ ] Test 320×568, 360×640, 393×873, 412×915
- [ ] Test text scale 1.0, 1.3 and 1.5
- [ ] No `BOTTOM OVERFLOW` on any sensor card
- [ ] Four main sensor cards appear even before hardware installation
- [ ] Missing sensor data displays `ไม่มีข้อมูล`
- [ ] No simulated values appear
- [ ] Battery and Solar display `ไม่มีข้อมูล` before INA226 integration
- [ ] A real zero value is displayed as `0`, not as missing data

## Connectivity states
- [ ] ESP32 offline
- [ ] ESP32 connecting
- [ ] ESP32 online
- [ ] Refresh failure/degraded status
- [ ] Emergency banner remains visible and actionable

## Relay validation
- [ ] Relay count follows the ESP32/controller report
- [ ] Current prototype reports 8 channels after flashing the matching firmware
- [ ] Dashboard previews at most 4 configured devices
- [ ] ON/OFF commands still use DeviceStore/SmartFarmController
- [ ] Commands are disabled while offline, pending, disabled, or emergency-latched

## Regression
- [ ] Devices page unchanged
- [ ] Sensors page unchanged
- [ ] Automation page unchanged
- [ ] Settings page unchanged
- [ ] Protocol Version remains 1
- [ ] API Version remains 2
