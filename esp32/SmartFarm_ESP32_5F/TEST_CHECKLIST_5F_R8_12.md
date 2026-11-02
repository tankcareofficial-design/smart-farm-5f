# R8.12 ESP32 test checklist

1. Compile for the exact ESP32-S3 N16R8 44-pin board.
2. Confirm the main INO name matches the project folder.
3. Verify relay mapping 4,5,6,7,15,16,17,18 and Active HIGH operation.
4. Flash R8.12 once: saved Wi-Fi must clear, while device profiles and schedules remain.
5. Reboot/EN reset: Wi-Fi must remain stored.
6. Hold BOOT for 5–9 seconds and release: only Wi-Fi is cleared.
7. Hold BOOT for at least 10 seconds: full NVS factory reset occurs.
8. Verify `/api/v3/snapshot` includes controllerId, storageSchemaVersion, deviceType and controlMode.
9. Reconnect Flutter and verify cards restore from stored ESP32 profiles.
