# ESP32 5F R8.8
- Added POST /api/v3/devices/config as the device-centric configuration endpoint.
- Flutter device profiles are persisted by the existing schedule/condition execution engine.
- Supports always-active profiles when schedule is disabled.
- Device ON remains an intent evaluated against stored time, sensor, safety and emergency conditions.
- Snapshot capabilities now advertise device-centric configuration.
