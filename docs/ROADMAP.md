# Smart Farm 5F — Roadmap (โปรเจกต์จบ ปวส.)

อัปเดต: 2026-11-02 · Baseline: R8.13 Rebase 3 (commit `f341108`)

## เป้าหมาย

1. **Local (ทำงานได้แม้ไม่มีเน็ต):** มือถือต่อ Wi-Fi ของกล่อง `SmartFarm-xxxxxx` → สั่ง Relay / Schedule ได้ (ทำแล้วเป็นส่วนใหญ่)
2. **Remote (เปิดได้ทุกที่):** ESP32 ต่อ Wi-Fi บ้าน/ฟาร์มที่มีเน็ต → ซิงก์กับ Cloud → แอปดู/สั่งงานจากที่ไหนก็ได้ (ยังไม่เริ่ม)
3. **ความปลอดภัยต้องมาก่อน:** ESP32 เป็นผู้ตัดสินสถานะจริงเสมอ ถ้าเน็ตหลุด กล่องต้องรัน Schedule ต่อได้เอง

## สถาปัตยกรรมเป้าหมาย

```text
                 ┌──────────── Cloud (Firebase) ────────────┐
                 │  Auth (login)   Realtime DB   History    │
                 └──────▲──────────────────────────▲────────┘
                        │ TLS (เน็ตบ้าน/4G)         │ TLS (4G/Wi-Fi ที่ไหนก็ได้)
┌───────────────────────┴───────┐          ┌───────┴──────────┐
│ ESP32-S3 Controller           │          │ Flutter App       │
│ - Relay 8 ช่อง (source of truth)│◄──AP────►│ - Local mode       │
│ - Schedule / Condition         │ 192.168.4.1│ - Remote mode     │
│ - DS3231 RTC, SHT31            │          └──────────────────┘
│ - HTTP API (local)             │
│ - Cloud bridge (R9)            │
└───────────────────────────────┘
```

หลักการ Remote: แอปเขียน "คำขอ" (commandId + หมดอายุ) ลง Cloud → ESP32 อ่าน → ตรวจ ownership/emergency/schedule → สั่ง Relay → เขียนสถานะจริงกลับ
แอปแสดงสถานะจากที่ ESP32 รายงานเท่านั้น ไม่เดาเอง

## ขั้นตอน

| Phase | งาน | ใครทำ | สถานะ |
|---|---|---|---|
| 0 | ตั้ง GitHub repo + import baseline | Claude | ✅ เสร็จ |
| 1 | ยืนยัน baseline: `flutter analyze/test`, compile ESP32, flash, smoke test | ผู้ใช้ (ต้องมีบอร์ด) | ⏳ รอ |
| 2 | **R8.14 Stability:** RTC failure threshold (OPEN-01), แยก Online ออกจาก Clock (OPEN-02), แยก poll health ต่อ endpoint (OPEN-03), เลิก auto-sync เวลาทับ RTC เมื่อ error ชั่วคราว | Claude | ⏳ ถัดไป |
| 3 | Hardware acceptance: Connect (OPEN-04), Edit/Save (OPEN-05), Safe Delete (OPEN-06), RTC 10 นาที → Freeze **v0.9 Local Stable** | ผู้ใช้ทดสอบ / Claude แก้ | — |
| 4 | Production cleanup: ปิด dev Wi-Fi auto-clear (OPEN-07), รหัส AP ต่อเครื่อง, factory reset | Claude + ทดสอบ | — |
| 5 | **R9 Remote:** Firebase project, ESP32 cloud bridge, Login ในแอป, Local/Remote auto-switch, สถานะ Offline ของกล่อง (heartbeat) | Claude + ผู้ใช้สร้าง Firebase | — |
| 6 | ฟีเจอร์โชว์: กราฟอุณหภูมิ/ความชื้นย้อนหลัง, แจ้งเตือน (push), ประวัติการทำงาน Relay | Claude | — |
| 7 | เล่มโปรเจกต์ 5 บท + สไลด์นำเสนอ + คู่มือการใช้งาน | Claude ร่าง / ผู้ใช้เติมรูป-ผลจริง | — |

## สิ่งที่ต้องเก็บระหว่างทำ (ใช้ในเล่มบทที่ 3–4)

- รูปบอร์ด, การต่อสาย, กล่องจริง (ก่อน/หลังประกอบ)
- Screenshot แอปทุกหน้า
- Serial log ตอนบูต / ตอน RTC error
- ตารางผลทดสอบตาม Test Matrix ใน Handoff (ผ่าน/ไม่ผ่าน + วันที่)
- เวลาตอบสนองสั่ง Relay (Local vs Remote) เพื่อทำตารางเปรียบเทียบ
- ค่าใช้จ่ายอุปกรณ์ (BOM)
