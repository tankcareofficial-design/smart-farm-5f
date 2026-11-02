# Smart Farm 5F

ระบบควบคุมฟาร์มแบบ Local-first: **ESP32-S3 Controller** (source of truth ของ Relay / Schedule / RTC) + **Flutter App** (UI/Client)

| ส่วน | ที่อยู่ | เวอร์ชัน |
|---|---|---|
| ESP32 firmware | `esp32/SmartFarm_ESP32_5F/SmartFarm_ESP32_5F.ino` | `0.8.0-5f-r8.13-rebase-3` |
| Flutter app | `flutter/` | `0.8.13+136` |
| Handoff / บริบทโครงการ | `docs/handoff/` | R8.13 Rebase 3 |
| Roadmap / แผนงาน | `docs/ROADMAP.md` | — |

> Baseline แรกของ repo นี้ = **R8.13 Rebase 3** (import จาก ZIP: ESP32 SHA256 `9e1141e4…18fd9`, Flutter SHA256 `35e0def3…be0e`)
> เปลี่ยนเพียงอย่างเดียวตอน import: ย้ายโฟลเดอร์ sketch และเปลี่ยนชื่อ `.ino` เป็น `SmartFarm_ESP32_5F` (Arduino ต้องให้ชื่อโฟลเดอร์ตรงกับชื่อ `.ino`) เพื่อไม่ต้องเปลี่ยนชื่อทุกรุ่น

## Hardware baseline (ห้ามเปลี่ยนโดยไม่มีหลักฐาน)

- ESP32-S3 N16R8 44-pin
- DS3231: SDA=GPIO8, SCL=GPIO9, 100 kHz, 0x68
- Relay ACTIVE HIGH: CH1–CH8 = GPIO 4, 5, 6, 7, 15, 16, 17, 18

## Quality gate (รันบนเครื่องผู้พัฒนา)

```powershell
cd flutter
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
```

ESP32: เปิด `esp32/SmartFarm_ESP32_5F/SmartFarm_ESP32_5F.ino` ใน Arduino IDE (บอร์ด ESP32S3 Dev Module, Flash 16MB, PSRAM OPI) → Compile ให้ผ่านก่อน Flash ทุกครั้ง

## สถานะ (ดูรายละเอียดใน `docs/handoff/`)

```text
R8.13_REBASE_3_FLUTTER_ANALYZE      = NOT_YET_VERIFIED
R8.13_REBASE_3_ESP32_COMPILE        = NOT_YET_VERIFIED
R8.13_REBASE_3_HARDWARE_ACCEPTANCE  = NOT_YET_RUN
OPEN-01 RTC transient failure        = OPEN (confirmed in source)
OPEN-02 Online ผูกกับ Clock validity  = OPEN (confirmed in source)
OPEN-03 Poll รวม state+clock+snapshot = OPEN (confirmed in source)
OPEN-04 Connect ครั้งแรก             = NEEDS ACCEPTANCE
OPEN-05 Edit/Save                    = NEEDS ACCEPTANCE
OPEN-06 Safe Delete                  = NEEDS HARDWARE ACCEPTANCE
OPEN-07 Dev Wi-Fi auto-clear         = OPEN (ต้องทบทวนก่อน production)
```
