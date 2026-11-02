# Test checklist

- [ ] Dashboard hero matches 0.7.5a green gradient.
- [ ] Dashboard reports 8 relay channels before and after connection.
- [ ] Firmware `/api/device` reports `relayCount: 8`.
- [ ] SHT31 at 0x44 on GPIO8/GPIO9 reports temperature and humidity.
- [ ] Disconnecting SHT31 returns null values, never simulated values.
- [ ] Readiness is unavailable without live sensor data.
- [ ] Readiness score reflects live coverage, quality, relay profile, connectivity, and emergency state.
- [ ] flutter analyze and flutter test pass.
