# TEST CHECKLIST — ESP32 5F R8.1 HOTFIX 2

- [ ] Firmware compiles for the target ESP32 board
- [ ] `/api/device` reports `relayCount: 12`
- [ ] `/api/state` reports 12 relay objects
- [ ] `metrics.temperature` is null without a supported real sensor
- [ ] No sinusoidal or ESP32 internal-chip temperature is reported
- [ ] Protocol Version is 1 and API Version is 2
- [ ] Relay GPIO pins are configured before connecting a physical relay board
