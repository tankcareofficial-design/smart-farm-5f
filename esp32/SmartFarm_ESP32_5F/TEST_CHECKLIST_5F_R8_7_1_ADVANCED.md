# ESP32 test checklist

1. Compile with ESP32 core 3.3.11 and ArduinoJson 7.4.x.
2. Confirm firmware string `0.8.0-5f-r8.7.1-advanced` in Serial Monitor.
3. GET `/api/v3/snapshot`; verify schemaVersion=2, sourceOfTruth=esp32, health and capabilities.
4. GET `/api/v3/runtime`; verify runtime and health arrays/objects.
5. Disconnect phone and internet; confirm schedules continue on ESP32.
6. Trigger emergency stop; verify health.status=emergency and outputs stop.
7. Remove sensors; verify health.status=no_sensor_data rather than false 100% readiness.
