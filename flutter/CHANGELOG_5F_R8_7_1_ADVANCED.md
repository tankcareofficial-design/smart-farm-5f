# Smart Farm 5F R8.7.1 Advanced — Flutter

- Added typed `SystemHealthState` parsed from ESP32 snapshot schema v2.
- Expanded `ControllerSnapshot` with schema version, generated time, source of truth, and health.
- Added lightweight `/api/v3/runtime` client method.
- Backward-compatible with R8.7 snapshot schema v1: missing health becomes unavailable, never fabricated.
- No automation or relay decision logic was moved into Flutter.
