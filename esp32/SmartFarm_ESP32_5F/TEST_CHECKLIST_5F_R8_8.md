# ESP32 R8.8 checklist
1. Compile with ArduinoJson 7.
2. POST a device profile to /api/v3/devices/config.
3. Restart ESP32 and confirm profile persists.
4. Request ON before schedule: accepted + waiting, relay remains OFF.
5. Request ON with sensor condition false: waiting, relay OFF.
6. Satisfy all conditions: relay starts and runtime becomes running.
7. Request OFF: relay stops and pending intent clears.
8. Verify /api/v3/snapshot advertises deviceCentricConfiguration.
