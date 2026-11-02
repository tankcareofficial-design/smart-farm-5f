# Smart Farm 5F R8.12 V2 — Power Recovery

## Added
- Persistent 8-channel relay-state bitmask in NVS.
- Safe boot sequence: inactive electrical level is established before each GPIO becomes OUTPUT.
- Relay state is restored after power loss, EN reset, watchdog restart, or ordinary firmware reboot when NVS is retained.
- Writes occur only when the relay mask changes to reduce NVS wear.
- Snapshot relay entries expose `powerLossRestoreEnabled` and `restoredFromStorage`.

## Reconciliation behavior
- The last actual relay output state is restored first.
- Schedule automation then evaluates current RTC time and may correct the output.
- Sensor automation evaluates again when fresh sensor data arrives.
- Emergency stop persists all relays OFF through the same relay-state store.
- Wi-Fi-only reset does not remove relay state; full factory reset removes it with NVS.

## Hardware baseline retained
- ESP32-S3 N16R8, 44 pin.
- RTC SDA GPIO8, SCL GPIO9.
- Active-HIGH relay board.
- CH1..CH8 GPIO4, GPIO5, GPIO6, GPIO7, GPIO15, GPIO16, GPIO17, GPIO18.
