# Test checklist R8.6 ESP32

- [ ] Arduino compile ผ่านโดยติดตั้ง ArduinoJson, WiFi/WebServer และ ESP32 core
- [ ] I2C SDA=GPIO8, SCL=GPIO9 พบ DS3231 ที่ 0x68
- [ ] GET /api/v2/clock คืน valid=true และ source=ds3231
- [ ] ถอด USB แล้วเสียบใหม่ เวลาเดินต่อ
- [ ] POST /api/v2/clock/sync ตั้งเวลาจากโทรศัพท์สำเร็จ
- [ ] สร้าง rule แล้ว GET /api/v2/automations พบ rule และ nextRunAt
- [ ] Rule ทำงานเพียงครั้งเดียวในนาทีที่กำหนด
- [ ] Relay ปิดเมื่อครบ durationSeconds
- [ ] Emergency stop ปิด relay และกัน schedule เปิดซ้ำ
- [ ] RTC invalid ทำให้ schedule ไม่ทำงาน แต่ manual ยังใช้ได้
