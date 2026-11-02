# Flutter test checklist

1. Run `flutter analyze` and require `No issues found`.
2. Open cached UI while ESP32 is offline.
3. Connect to ESP32 and fetch snapshot schema v2.
4. Confirm health is unavailable when missing, not synthesized as 100%.
5. Confirm device requests still use `/api/v3/devices/request`.
6. Confirm reconnect replaces cached runtime with ESP32 runtime.
