# ESP32 5F R8.1 Test Checklist

- [ ] Compile the `.ino` for the project ESP32 board.
- [ ] Confirm no missing include or duplicate symbol.
- [ ] GET `/api/device`: firmware `0.6.9-5f-r8.1-stability`, protocol `1`, API `2`.
- [ ] GET `/api/state`: protocol `1`, API `2`, uptime, free heap, RSSI, emergency, metrics, and relays.
- [ ] POST relay command works.
- [ ] Emergency stop and release work.
- [ ] Flutter connects without requiring a changed endpoint.
