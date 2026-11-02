# Smart Farm 5F ESP32 R8.12 Foundation Sync

- Active HIGH relay mapping retained: GPIO 4,5,6,7,15,16,17,18.
- Profiles persist in NVS and expose deviceType/controlMode in snapshot.
- Development firmware version change clears Wi-Fi credentials only.
- BOOT hold 5 seconds clears Wi-Fi only; hold 10 seconds performs full factory reset.
- Snapshot schema 3 includes controller identity and storage schema.
