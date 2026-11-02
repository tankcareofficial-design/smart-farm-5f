# Smart Farm+ 0.8.0 — ESP32 Wi-Fi Edition

## เป้าหมายของเวอร์ชัน
เวอร์ชัน 0.8 เปลี่ยนช่องทางสื่อสารหลักจาก USB Serial เป็น HTTP API ผ่าน Wi-Fi โดยคงแนวคิด UI เดิมของ Smart Farm+ และเตรียมฐานสำหรับใช้งานร่วมกับ ESP32 จริง

## สิ่งที่ทำแล้วในชุดนี้
- ใช้ `http` package ติดต่อ ESP32
- รองรับ `GET /api/device`
- รองรับ `GET /api/state`
- รองรับ `POST /api/relay`
- ตั้งค่า Base URL ของ ESP32 ได้ โดยค่าเริ่มต้นคือ `http://192.168.4.1`
- Poll ข้อมูลทุก 2 วินาที
- Auto reconnect หลังการเชื่อมต่อขาดหาย
- แสดงสถานะ Online/Offline, Device ID, Firmware, Uptime และจำนวน Wi-Fi client
- แสดงค่าความชื้นดิน อุณหภูมิ และความชื้นอากาศ
- ควบคุมรีเลย์จากข้อมูลจริงของ ESP32
- เปลี่ยนหน้า USB Serial เดิมเป็นหน้า ESP32 Controller ที่รองรับหน้าจอมือถือ
- แก้ข้อความและเลขเวอร์ชันในหน้า Settings/About เป็น 0.8.0
- นำชื่อไฟล์และคลาส Serial Dashboard เดิมออกจาก `lib/`

## API ที่คาดหวัง
Base URL เริ่มต้น: `http://192.168.4.1`

- `GET /api/device`
- `GET /api/state`
- `POST /api/relay`

ตัวอย่าง body สำหรับรีเลย์:

```json
{
  "channel": 0,
  "on": true,
  "overrideSeconds": 300
}
```

## การตรวจบนเครื่องพัฒนา

```powershell
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run -d R83YC0TAJXP
```

เวอร์ชัน 0.8 จะยังไม่ถูกปิดจนกว่ารายการสเปกและการทดสอบกับ ESP32 จริงจะผ่านครบทุกข้อ


### Checkpoint 2
- Fixed dark-theme text contrast and theme-aware surfaces.

## Checkpoint 3 — Dashboard dark-theme contrast

- Made SFCard surfaces and borders follow the active Material color scheme.
- Fixed Dashboard quick-action cards that were permanently white.
- Fixed the live date/time header icon container for dark mode.
- Fixed inactive device icon tiles and project-credit contrast.
- Preserved intentionally dark hero and energy cards with explicit light text.
