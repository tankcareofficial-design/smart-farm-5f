# ESP32 test checklist

- [ ] Compile for ESP32-S3 N16R8.
- [ ] SHT31 VCC=3.3V, GND, SDA=GPIO8, SCL=GPIO9.
- [ ] Serial/API temperature and humidity update every 3 seconds.
- [ ] Removing SHT31 produces null temperature/humidity.
- [ ] `/api/device` and `/api/state` report 8 relays.
