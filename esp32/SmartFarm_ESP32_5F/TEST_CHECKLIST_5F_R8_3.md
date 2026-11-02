# Test checklist — ESP32 5F R8.3

- [ ] Firmware compiles for ESP32-S3.
- [ ] `/api/device` returns relayCount 8, hardwareProfile and accessories.
- [ ] `/api/state` returns soilMoisture, temperature and humidity as null with no sensors.
- [ ] No random soil percentage appears after 10 minutes.
- [ ] Battery and solar appear as separate roles and remain not_installed.
- [ ] Existing relay and emergency endpoints remain functional.
- [ ] Old Flutter clients can ignore new fields without failure.
