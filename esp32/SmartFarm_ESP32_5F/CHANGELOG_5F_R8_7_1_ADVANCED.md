# Smart Farm 5F R8.7.1 Advanced — ESP32

- Added `SystemHealthManager` as an ESP32-owned health calculation layer.
- Added deterministic health states: healthy, no_sensor_data, local_automation_only, clock_unavailable, degraded_memory, emergency.
- Added `/api/v3/runtime` for lightweight runtime synchronization by Flutter and future CYD clients.
- Snapshot schema upgraded to v2 with `health`, `capabilities`, `sourceOfTruth`, and `runtimeModel`.
- Preserved the intent → decision → execution architecture and all R8.7 endpoints.
- ArduinoJson v7-safe parsing from HOTFIX 1 remains included.
