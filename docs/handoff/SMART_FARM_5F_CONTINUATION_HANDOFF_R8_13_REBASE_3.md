# SMART FARM 5F — CONTINUATION HANDOFF

**Handoff date:** 2026-11-02  
**Current code baseline:** R8.13 Rebase 3  
**Purpose:** ใช้ย้ายโปรเจกต์ไปแชท/Workspace ใหม่โดยไม่ต้องเทรนบริบทใหม่ตั้งแต่ต้น

---

## 0. ข้อความสำหรับเปิดแชทใหม่

ให้เริ่มจากไฟล์ Handoff นี้และ Source ZIP ล่าสุด 2 ไฟล์เท่านั้น:

- `SmartFarm_ESP32_5F_R8_13_REBASE_3.zip`
- `SmartFarm_Flutter_5F_R8_13_REBASE_3.zip`

ก่อนแก้โค้ดต้องอ่าน Source ที่เกี่ยวข้องจริงก่อนเสมอ และห้ามอ้างว่า Compile / Test / Hardware PASS หากไม่มีหลักฐานจากการรันจริง

**ห้ามเริ่มใหม่จากศูนย์ และห้ามย้อนกลับไปใช้ baseline เก่าโดยไม่เทียบ diff กับ R8.13 Rebase 3 ก่อน**

---

# 1. เป้าหมายโครงการ

Smart Farm 5F เป็นระบบควบคุมฟาร์มแบบ Local-first ประกอบด้วย:

- **ESP32-S3 Controller** เป็น source of truth ของรีเลย์, schedule, runtime, RTC และ profile
- **Flutter App** สำหรับ pairing/connection, dashboard, device configuration, manual control, schedule/condition, Wi-Fi provisioning และ monitoring
- Controller เปิด Wi-Fi AP ของตัวเอง และสามารถทำ AP+STA
- การทำงานของรีเลย์ต้องปลอดภัยก่อนความสะดวกของ UI

หลักสำคัญ:

> Flutter เป็น UI/Client แต่ ESP32 เป็นผู้ตัดสินสถานะจริงของ Relay / Automation / Runtime

---

# 2. Baseline ปัจจุบัน

## ESP32

```text
Firmware: 0.8.0-5f-r8.13-rebase-3
Hardware profile: smart_farm_8ch_v1
Protocol version: 1
API version: 3
Storage schema: 2
Automation schema: 3
Snapshot schema: 3
```

Source entry:

```text
SmartFarm_ESP32_5F_R8_13_REBASE_3/SmartFarm_ESP32_5F_R8_13_REBASE_3.ino
```

## Flutter

```text
Version: 0.8.13+136
```

Source root:

```text
SmartFarm_Flutter_5F_R8_13_REBASE_3/
```

---

# 3. Hardware baseline — ห้ามเปลี่ยนโดยไม่มีหลักฐาน

Controller:

```text
ESP32-S3 N16R8, 44-pin
```

RTC DS3231:

```text
SDA = GPIO8
SCL = GPIO9
I2C = 100 kHz
Address = 0x68
```

Relay board:

```text
ACTIVE HIGH
CH1 = GPIO4
CH2 = GPIO5
CH3 = GPIO6
CH4 = GPIO7
CH5 = GPIO15
CH6 = GPIO16
CH7 = GPIO17
CH8 = GPIO18
```

Config ปัจจุบัน:

```text
RELAY_ACTIVE_LOW = false
RESTORE_RELAY_STATE_AFTER_POWER_LOSS = true
```

**กฎ:** ห้ามสลับเป็น Active LOW และห้ามเปลี่ยน GPIO mapping เอง

---

# 4. Controller ที่ทดสอบจริงก่อน Rebase 3

ตอน R8.13 Rebase 2 ผู้ใช้ทดสอบ `/api/device` จริงและ Controller ตอบกลับ:

```text
deviceId = sf-64B9509FC114
displayName = กล่องควบคุมฟาร์ม
firmwareVersion = 0.8.0-5f-r8.13-rebase-2
mode = access_point_and_station
SSID = SmartFarm-9FC114
AP IP = 192.168.4.1
wifiClientCount = 1
stationConnected = false
provisioningConfigured = false
relayCount = 8
```

ดังนั้น ณ จุดนั้น AP และ HTTP `/api/device` ใช้งานได้จริง

**ยังไม่มี Hardware Acceptance ของ R8.13 Rebase 3 หลังแฟลช** ณ ตอนทำ Handoff นี้

---

# 5. API สำคัญใน R8.13 Rebase 3

```text
GET  /api/device
GET  /api/state
GET  /api/relays
POST /api/relay
GET  /api/wifi/scan
POST /api/wifi/connect
POST /api/emergency-stop
POST /api/emergency-release

GET  /api/v3/clock
POST /api/v3/clock/sync
GET  /api/v3/snapshot
GET  /api/v3/runtime
POST /api/v3/devices/config
POST /api/v3/devices/request
POST /api/v3/devices/evaluate
POST /api/v3/devices/delete

GET  /api/v2/automations
POST /api/v2/automations
POST /api/v2/automations/delete
POST /api/v2/automations/test
```

---

# 6. ปัญหาหลักที่เกิดก่อน R8.13 Rebase 2

พบอาการต่อเนื่องหลายรุ่น:

1. ลบ Device แล้ว Device/Rule เดิมกลับมาจาก ESP32/NVS
2. สร้าง Device ใหม่ใช้ Relay เดิม แล้ว Schedule/Condition เก่าตามกลับมา
3. Relay เคย ON เองหลังผู้ใช้ OFF หรือหลัง Reboot
4. กด Relay เร็ว ON→OFF→ON แล้วคำสั่งบางตัวตกหรือ UI/Controller ไม่ตรงกัน
5. Schedule และ Legacy Automation เคยมีสิทธิ์เขียน GPIO พร้อมกัน
6. Persisted relay state เคยถูก restore ก่อนแยก ownership ระหว่าง Manual กับ Automation

แนวทาง Rebase 2 จึงเน้น Relay ownership, safe boot, command integrity และ one-run-per-occurrence

---

# 7. สิ่งที่ R8.13 Rebase 2 วางไว้

แกนหลักใน Source ปัจจุบันที่ต้องรักษา:

- Legacy `AutomationEngine` ไม่ควรเป็นผู้เขียน GPIO หลักอีก
- `RelayManager::setTransient()` ใช้กับ runtime automation โดยไม่ทำ persisted manual state
- Boot เริ่มรีเลย์ OFF ก่อน แล้ว restore เฉพาะช่อง Manual ที่อนุญาต
- Schedule มี `lastExecutionKey` ป้องกันการรัน occurrence เดิมซ้ำหลัง reboot
- Schedule ข้ามเที่ยงคืนอ้างอิงวันเริ่ม occurrence
- Flutter มี command lane/worker ต่อ Device เพื่อให้ latest desired state ชนะ

อย่ารื้อหลักการเหล่านี้ถ้าไม่มี regression evidence

---

# 8. R8.13 Rebase 3 — สิ่งที่เพิ่มใน Source

Rebase 3 มี 3 เป้าหมาย:

```text
1. Connection Stability
2. Safe Device Delete
3. Edit / Save Recovery
```

## 8.1 Connection

Flutter `smart_farm_controller.dart` เปลี่ยนให้:

- `/api/device` เป็น reachability contract หลักตอน connect
- `/api/state`, `/api/v3/clock`, `/api/v3/snapshot` โหลดแยกในช่วง initial connect
- clock/snapshot fail ครั้งเดียวไม่ทำให้ initial connect ถูกมองว่า "controller not found"
- poll ล้มเหลวต่อเนื่อง 3 รอบจึงเปลี่ยน `connected=false`
- `GET /api/device` มี retry 0 ms / 300 ms / 800 ms

HTTP base URL default:

```text
http://192.168.4.1
```

## 8.2 Safe Device Delete

เพิ่ม:

```text
POST /api/v3/devices/delete
```

ESP32 flow ปัจจุบัน:

```text
หา Device
→ หา Relay channel
→ setTransient(channel, false)
→ clearPersistedChannel(channel)
→ removeDevice(deviceId)
→ save schedule/profile
→ response actualRelayState = off
```

Flutter จะลบ Local Device หลัง Controller ตอบ delete สำเร็จ

## 8.3 Edit/Save

Flutter:

- update Device โดยใช้ Device ID เดิม
- validation relay channel ยกเว้น Device ตัวเอง
- `_syncProfile()` ต้องสำเร็จก่อนอัปเดต local list
- Dialog มี `_isSaving`
- Loading state ถูกล้างใน `finally`
- Save failure ไม่ปิด dialog

---

# 9. ปัญหา OPEN ที่สำคัญมาก — ต้องแก้ต่อจาก R8.13 Rebase 3

## OPEN-01 — DS3231 / Clock ไม่เสถียร และ UI Online/Offline แกว่ง

ผู้ใช้รายงานว่า:

- เวลาจาก DS3231 เป็น ๆ หาย ๆ
- Online/Offline กลับไปกลับมา
- รุ่นก่อนหน้ารู้สึกเสถียรกว่า

**ตรวจ Source R8.13 Rebase 3 แล้วพบจุดเสี่ยงจริง:**

`ClockService::readRtc()` ทำดังนี้เมื่อเกิด I2C failure เพียงครั้งเดียว:

```text
probe fail → snapshot.valid = false
read 7 bytes fail → snapshot.valid = false
status-register read fail → lostPower = true
```

และ `update()` อ่าน RTC ทุกประมาณ 500 ms

ดังนั้น transient I2C error เพียงหนึ่งรอบสามารถทำ Clock invalid ทันที

สิ่งที่ควรทำรุ่นถัดไป:

```text
- เพิ่ม consecutive RTC failure threshold เช่น 3 ครั้งก่อน invalid
- เก็บ last-known-good clock snapshot
- แยก device_not_found / i2c_read_failed / lost_power จริง
- อย่า set lostPower=true เพียงเพราะอ่าน status register ไม่สำเร็จ
- success 1 ครั้งควร reset failure counter
```

## OPEN-02 — Flutter ยังผูกบาง UI กับ Clock validity

ใน `lib/screens/devices_screen.dart` ปัจจุบันมี logic:

```dart
final connected = widget.store.controllerConnected;
final clockValid = widget.store.controllerClockValid;
final hasClockValue = dateTime != null;
final online = hasClockValue && clockValid;
```

นี่ทำให้ UI บางส่วนดูเหมือน Offline/ไม่พร้อมเมื่อ RTC invalid ทั้งที่ Controller HTTP ยัง reachable

**กฎรุ่นถัดไป:**

```text
Controller Online = HTTP reachability / controller.connected
Clock Health = RTC valid/invalid เป็นสถานะคนละชุด
```

ห้ามใช้ RTC validity ตัดสิน Controller Online

## OPEN-03 — Poll cycle ยังรวม State + Clock + Snapshot เป็น transaction เดียว

Initial connect แยก endpoint แล้ว แต่ `refreshState()` ปัจจุบันยังทำ:

```text
/api/state
→ /api/v3/clock
→ /api/v3/snapshot
```

ภายใน try/catch เดียว

ดังนั้น Clock timeout สามารถนับเป็น poll failure ของ Controller ได้ ถึงแม้ HTTP `/api/device` ยัง reachable

แนวทางถัดไป:

```text
- แยก health counters ต่อ endpoint
- controller reachability ใช้ /api/device หรือ lightweight health probe
- clock failure ไม่ควรเพิ่ม controller-offline failure counter
- snapshot failure = data degraded, not offline
```

## OPEN-04 — Connection ครั้งแรกยังเคยต้องกด Refresh/Connect หลายครั้ง

ก่อน Rebase 3 ผู้ใช้เจอ:

```text
โทรศัพท์เชื่อม SmartFarm AP แล้ว
แต่ Flutter บอกไม่พบ Controller
ต้องกด refresh/connect หลายครั้งจึงติด
```

Rebase 3 เพิ่ม retry แล้ว แต่ **ยังไม่ได้ Hardware Acceptance**

ต้องทดสอบจริงหลังแฟลช R8.13 Rebase 3

## OPEN-05 — Edit เวลา/เงื่อนไขเคยกด Save ไม่ได้

Rebase 3 มีการแก้ flow แล้ว แต่ **ยังไม่ได้ยืนยันจากผู้ใช้หลังทดสอบ**

Acceptance ต้องครอบคลุม:

```text
แก้ชื่อ
แก้เวลาเริ่ม
แก้เวลาสิ้นสุด
แก้วันทำงาน
แก้ condition
เปลี่ยน mode
Save สำเร็จและ snapshot ใหม่ตรงกับ form
```

## OPEN-06 — Safe Delete ยังต้อง Hardware Acceptance

ต้องทดสอบจริง:

```text
Relay ON
→ Delete Device
→ Relay ต้อง OFF ก่อน Device หาย
→ reboot ESP32
→ Relay ต้องไม่กลับ ON
→ Profile เดิมต้องไม่กลับ
→ Relay channel เดิมต้องสร้าง Device ใหม่ได้
```

## OPEN-07 — Development Wi-Fi auto-clear ยังเปิดอยู่

`Config.h` ปัจจุบัน:

```text
WIFI_PROVISIONING_VERSION = 81202
DEVELOPMENT_CLEAR_WIFI_ON_FIRMWARE_CHANGE = true
```

`ProvisioningResetManager::begin()` จะล้าง Wi-Fi credentials เมื่อ build/version marker ไม่ตรง

นี่เป็น behavior สำหรับ development และต้องทบทวนก่อน production เพราะอาจทำให้ผู้ใช้คิดว่า Controller "ลืม Wi-Fi"

**ห้ามเปลี่ยนทันทีโดยไม่ทดสอบ migration/NVS ก่อน**

---

# 10. สถานะ Compile / Analyze ที่มีหลักฐานจริง

ก่อน Rebase 3 ผู้ใช้รัน Flutter Analyzer กับ Rebase 2 แล้วได้:

```text
1 info:
curly_braces_in_flow_control_structures
lib/stores/device_store.dart:347:7
```

เป็น lint ไม่ใช่ runtime error

Rebase 3 ตั้งใจแก้ lint นี้แล้ว แต่ **ยังไม่มีผล `flutter analyze` จากเครื่องผู้ใช้ยืนยัน R8.13 Rebase 3**

Environment ที่สร้างไฟล์ Handoff นี้ไม่มี:

```text
flutter
dart
arduino-cli
```

ดังนั้นห้ามเขียนว่า R8.13 Rebase 3 Compile PASS จนกว่าจะรันจริงบนเครื่องผู้ใช้

---

# 11. Quality Gate ที่ต้องใช้หลังย้ายโปรเจกต์

## Flutter

```powershell
flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
```

ต้องเป้าหมาย:

```text
flutter analyze = No issues found
flutter test = PASS
```

## ESP32

ใช้ Arduino/PlatformIO toolchain ที่ตรงกับ ESP32-S3 N16R8 แล้ว Compile source จริง

ห้าม Flash ก่อน compile ผ่าน

## Hardware Smoke Test

ทดสอบ LED relay ก่อนต่อโหลดจริง:

```text
1. Boot → ทุก channel ปลอดภัย
2. Manual ON/OFF CH1–CH8
3. ON→OFF→ON เร็ว
4. Schedule window
5. reboot กลาง schedule
6. delete ขณะ relay ON
7. edit schedule แล้ว save
8. RTC 5–10 นาที
9. Wi-Fi AP connect/reconnect หลายรอบ
10. ถอด/เสียบ Wi-Fi phone และดู recovery
```

---

# 12. Test Matrix สำหรับรุ่นถัดไป

## CONNECTION-01

```text
Phone ต่อ SmartFarm-xxxxxx
→ เปิด App
→ Connect 1 ครั้ง
→ /api/device ตอบ
→ ต้อง Connected โดยไม่ต้องกดซ้ำ
```

## CONNECTION-02

```text
/api/v3/clock fail 1 ครั้ง
→ Controller ยัง Online
→ Clock status degraded เท่านั้น
```

## CONNECTION-03

```text
/api/v3/snapshot fail 1 ครั้ง
→ Controller ยัง Online
→ Data status degraded
```

## RTC-01

```text
Transient I2C fail 1 ครั้ง
→ RTC ไม่ invalid ทันที
```

## RTC-02

```text
I2C fail >= threshold
→ Clock degraded/invalid
→ Controller HTTP ยัง Online
```

## DELETE-01

```text
Relay ON → Delete
→ OFF ก่อน
→ profile หาย
→ reboot ไม่กลับ
```

## EDIT-01

```text
แก้ Start/End time → Save
→ ESP32 profile revision เพิ่ม
→ snapshot ใหม่ตรง
```

## COMMAND-01

```text
ON→OFF→ON เร็ว
→ final state = ON
→ ไม่มี worker ซ้อน
→ ไม่มีคำสั่งสุดท้ายตก
```

---

# 13. รูปแบบการทำงานที่ผู้ใช้ต้องการ

1. อ่าน Handoff ก่อนทุกครั้ง
2. อ่าน Source ที่เกี่ยวข้องทุกไฟล์ก่อนแก้
3. วิเคราะห์ Root Cause จาก evidence ไม่เดาสุ่ม
4. รักษา baseline เดิมที่ผ่านแล้ว
5. แก้เฉพาะจุดและตรวจ regression
6. ห้าม claim PASS ถ้าไม่ได้รันจริง
7. แยกสถานะให้ชัด:

```text
SOURCE REVIEW
STATIC CHECK
FLUTTER ANALYZE
FLUTTER TEST
ESP32 COMPILE
FLASH
HARDWARE TEST
RUNTIME ACCEPTANCE
```

8. Hardware mapping / Relay polarity / NVS behavior ห้ามเปลี่ยนโดยไม่มีเหตุผลและหลักฐาน
9. ถ้าพบ bug ที่เคยแก้แล้ว ให้ย้อนดู history ก่อนสร้าง logic ใหม่
10. ZIP รุ่นใหม่ให้ส่ง **Flutter และ ESP32 แยกกัน** — ไม่ต้องสร้าง FULL_PROJECT เพราะเปลืองพื้นที่

---

# 14. ไฟล์ Source ปัจจุบันและ SHA256

```text
SmartFarm_ESP32_5F_R8_13_REBASE_3.zip
SHA256 = 9e1141e4564981845090cc8b70e86a6c1fb65ca842ff1f072705e56187918fd9

SmartFarm_Flutter_5F_R8_13_REBASE_3.zip
SHA256 = 35e0def31f1cb4f2bf8468c6fb1e24d4cdbb0b02c0f9c3aef2b58502fd1fbe0e
```

Archive integrity (`unzip -t`) ผ่านทั้งสองไฟล์ตอนสร้าง Handoff

Source inventory โดยประมาณ:

```text
ESP32 files: 103
ESP32 .cpp/.h/.ino lines: 3004
Flutter files: 340
Flutter Dart lines: 13819
```

---

# 15. GitHub status ตอน Handoff

ตรวจ GitHub connector แล้ว **ยังไม่พบ repository ของ Smart Farm 5F** ใน repository ที่เชื่อมอยู่

พบ repository อื่น เช่น `tankcareofficial-design/smart-gauge-cyd` แต่ไม่ใช่โปรเจกต์นี้

ดังนั้น Handoff นี้ **ไม่ได้ push Smart Farm ไป repo อื่นโดยเดาเอง**

เมื่อมี repo สำหรับ Smart Farm ให้ใช้ชื่อชัดเจน เช่น:

```text
tankcareofficial-design/smart-farm-5f
```

แล้วค่อย import source พร้อม Handoff โดยรักษา R8.13 Rebase 3 เป็น baseline แรก

---

# 16. งานถัดไปที่แนะนำทันที

ลำดับที่ควรทำหลังย้ายโปรเจกต์:

```text
1. Run flutter analyze/test บน R8.13 Rebase 3
2. Compile ESP32 R8.13 Rebase 3
3. Flash + smoke test connection
4. ทดสอบ Safe Delete
5. ทดสอบ Edit/Save
6. เก็บ log RTC/Clock 5–10 นาที
7. แก้ Clock failure threshold + แยก Clock Health ออกจาก Online
8. แยก poll health counter ตาม endpoint
9. Freeze รุ่นเสถียรใหม่หลัง Hardware Acceptance
```

**Priority สูงสุด:** RTC/connection stability เพราะตอนนี้ Clock failure ยังสามารถทำให้ UI ดูเหมือน Controller หลุดได้

---

# 17. Final Handoff State

```text
CURRENT_BASELINE = R8.13_REBASE_3
ESP32_FW = 0.8.0-5f-r8.13-rebase-3
FLUTTER_VERSION = 0.8.13+136
SOURCE_ZIPS = READY
ZIP_INTEGRITY = PASS
R8.13_REBASE_3_FLUTTER_ANALYZE = NOT_YET_VERIFIED_ON_USER_MACHINE
R8.13_REBASE_3_ESP32_COMPILE = NOT_YET_VERIFIED_ON_USER_MACHINE
R8.13_REBASE_3_HARDWARE_ACCEPTANCE = NOT_YET_RUN
CONNECTION_STABILITY = OPEN / NEEDS ACCEPTANCE
RTC_STABILITY = OPEN / SOURCE RISK IDENTIFIED
SAFE_DELETE = IMPLEMENTED / NEEDS HARDWARE ACCEPTANCE
EDIT_SAVE_RECOVERY = IMPLEMENTED / NEEDS USER ACCEPTANCE
```

