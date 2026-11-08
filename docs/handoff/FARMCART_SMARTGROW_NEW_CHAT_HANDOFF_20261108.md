# FarmCart SmartGrow — New Chat Continuation Handoff
Updated: 2026-11-08 (Asia/Bangkok)
Project state: R8.14 Stability 1 candidate, E-Stop no-load runtime PASS

> This file is intentionally written so a fresh ChatGPT conversation can continue the project without retraining from zero.

## 0. Paste this as the first message in the new chat

```text
ทำ FarmCart SmartGrow ต่อจากแชทเดิม ห้ามเริ่มใหม่และห้ามย้อนไปใช้ baseline เก่า

ก่อนทำอะไร ให้ดึง GitHub repo tankcareofficial-design/smart-farm-5f แบบ read-only ก่อน แล้วอ่านให้ครบ:
1) docs/handoff/FARMCART_SMARTGROW_NEW_CHAT_HANDOFF_20261108.md
2) docs/handoff/FARMCART_SMARTGROW_CONTINUATION_HANDOFF_R8_14_20261107.md
3) docs/handoff/FARMCART_SMARTGROW_CONTINUATION_LATEST_20261108.md
4) docs/TEST_CHECKLIST_R8_14_STABILITY.md
5) docs/RELEASE_NOTES_R8_14_STABILITY.md
6) docs/ROADMAP.md
7) README.md
8) source จริงใน esp32/ และ flutter/ ที่เกี่ยวกับงานถัดไป

ใช้ candidate/r8.14-stability-1 เป็น branch ปัจจุบัน และตรวจ branch HEAD / source diff / CI / runtime evidence ล่าสุดก่อนสรุปสถานะ

สำคัญ: Handoff ล่าสุด + source/commit/runtime evidence มี priority สูงกว่า README/ROADMAP/Checklist ที่อาจยังมีข้อความเก่า ห้ามเอาสถานะเก่ามาทับ PASS ใหม่ ห้าม claim PASS ถ้าไม่มีหลักฐาน และห้าม merge main / flash / NVS mutation / ต่อโหลดจริง โดยไม่มี approval ตามรูปแบบงานเดิม

อ่านรูปแบบการทำงานและสถานะทั้งหมดจากไฟล์ก่อน แล้วบอกผมสั้น ๆ ว่าตอนนี้ผ่านอะไรแล้ว เหลืออะไร และงานถัดไปที่ควรทำคืออะไร จากนั้นทำต่อจากจุดล่าสุด
```

---

# 1. Project identity

- Product: **FarmCart SmartGrow**
- Thai: ชุดสาธิตฟาร์มอัจฉริยะควบคุมและดูแลพืชผ่านมือถือ
- English: Smart Farm Control and Plant Monitoring System
- Repository: `tankcareofficial-design/smart-farm-5f`
- Working branch: `candidate/r8.14-stability-1`
- `main` stable baseline must remain untouched until explicit merge approval.
- Local Windows path historically used: `D:\FarmCart\smart-farm-5f`
- Runtime firmware version remains: `0.8.0-5f-r8.14-stability-1`
- Architecture: **local-first**. ESP32-S3 is the source of truth for relay / schedule / RTC. Flutter is UI/client.

Current branch HEAD when this handoff was prepared was after the E-Stop runtime PASS documentation. The new chat MUST fetch the live branch before acting because this file itself may advance HEAD.

---

# 2. Source-of-truth precedence

When documents disagree, use this order:

1. Physical/runtime evidence from the actual controller and current Android app.
2. Latest GitHub source on `candidate/r8.14-stability-1`.
3. Latest Handoff entries and continuation snapshot.
4. CI results tied to exact commit SHA.
5. `docs/TEST_CHECKLIST_R8_14_STABILITY.md`.
6. `docs/RELEASE_NOTES_R8_14_STABILITY.md`.
7. `README.md` / `docs/ROADMAP.md`.

Important: README, ROADMAP and TEST_CHECKLIST contain historical/stale status in places. Example: checklist still showed rapid-command as unchecked even though runtime PASS was recorded later. Do not regress project state because of stale docs; reconcile and then update docs when appropriate.

There is currently **no** `requirements/` or `docs/requirements/` directory. Treat README + ROADMAP + RELEASE_NOTES + TEST_CHECKLIST + Handoff + actual source as the effective requirements set until a dedicated requirements document is added.

---

# 3. Locked working style / rules

These rules are not optional unless the user explicitly changes them.

- Always continue from the latest actual source/branch/commit and latest Handoff. Never restart from an older baseline.
- Before a patch, inspect source and prior fixes first. Do not use trial-and-error patches without root-cause evidence.
- Before hardware mutation, identify the exact physical target.
- Never claim PASS without evidence. Keep these layers separate:
  - SOURCE
  - STATIC
  - HOST/UNIT TEST
  - TARGET BUILD / CI
  - FLASH
  - HARDWARE
  - RUNTIME
- GitHub Handoff must record meaningful actions, root causes, approvals, failures and PASS results.
- Keep `main` untouched until explicit approval.
- Flash/deploy/NVS/RTC/DB/merge/load mutations require explicit user approval when they can affect persistent or real hardware state.
- For commands on Windows, prefer one short CMD block rather than many fragmented probes.
- Do not touch unrelated ESP32 boards connected to the same PC.
- Do not blindly trust COM numbers; verify MAC/USB identity.
- Project diagnostic/flash baud is locked to **115200**.
- Do not erase all flash unless explicitly approved and technically justified.
- Preserve NVS / OTADATA / partition table / bootloader unless the gate explicitly says otherwise.
- During no-load acceptance, external pump/valve/actuator/load power stays disconnected.
- If a test reveals a defect, record the evidence and root cause before patching.
- If Windows Wi-Fi behavior disagrees with Android, remember the known Realtek RTL8188EU instability; Android direct/controller networking has been the authoritative acceptance client.
- Do not ask the user to repeat information that exists in Handoff/GitHub.
- If the conversation gets long, create/update a continuation Handoff before context is lost.

---

# 4. Hardware baseline

Controller:
- ESP32-S3 N16R8, 44-pin
- Flash: 16 MB
- PSRAM: 8 MB
- Physical FarmCart MAC: `14:c1:9f:50:b9:64`

Relays:
- 8-channel relay board
- ACTIVE HIGH
- CH1 GPIO4
- CH2 GPIO5
- CH3 GPIO6
- CH4 GPIO7
- CH5 GPIO15
- CH6 GPIO16
- CH7 GPIO17
- CH8 GPIO18
- `RESTORE_RELAY_STATE_AFTER_POWER_LOSS=true`

RTC:
- DS3231
- SDA GPIO8
- SCL GPIO9
- 100 kHz
- Address 0x68

Canonical ESP32 build profile:
```text
esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi
```

Partition map:
- NVS 0x9000 size 0x5000
- OTADATA 0xE000 size 0x2000
- APP0 0x10000 size 0x300000
- APP1 0x310000 size 0x300000
- FFat 0x610000 size 0x9E0000
- coredump 0xFF0000 size 0x10000
- Dual OTA preserved

Tools known good:
- Arduino core 3.3.12
- Arduino CLI 1.5.1
- ArduinoJson 7.4.3
- esptool 5.3.1

---

# 5. USB / COM identity and proven flash path

Known FarmCart native USB:
- VID:PID `303A:1001`
- USB Serial derived from MAC: `14:C1:9F:50:B9:64`
- Often COM5, but COM number can change.

Known FarmCart CH343 UART:
- VID:PID `1A86:55D3`
- serial historically `5C82118392`
- historically COM7.

A separate Waveshare ESP32-S3 was previously COM4 with USB serial `E8:F6:0A:B8:B7:0C`. **Never touch it when targeting FarmCart.**

Proven stable flash path on FarmCart:
- native USB Serial/JTAG
- 115200
- `--before usb-reset`
- `--after no-reset`
- `--no-stub`
- `--no-compress`
- APP0-only at 0x10000
- no erase-all
- preserve NVS / OTADATA / partition / bootloader

Multiple ESP32 boards connected at once caused Windows USB/COM confusion before. Disconnect unrelated boards when practical.

---

# 6. Important historical progression

## 6.1 R8.13 -> R8.14 Stability

The repo began from R8.13 Rebase baseline and moved to R8.14 Stability work focused on:
- RTC transient failure handling
- keeping controller reachability separate from RTC/clock health
- endpoint-specific polling health
- manual relay safety
- no-load hardware acceptance
- Wi-Fi provisioning stability
- rapid command latest-state semantics
- Emergency Stop safety and UI correctness

Do not return to the old R8.13 baseline just because README/ROADMAP still mention it.

## 6.2 Relay no-load hardware

No-load relay acceptance was completed:
- CH1..CH8 API ON/OFF PASS
- physical LED/click confirmed in correct CH1..CH8 order
- GPIO map confirmed 4,5,6,7,15,16,17,18
- final all relays OFF
- final active overrides 0
- emergency latch false at the end of that gate
- external load power disconnected

Recorded status:
- `RELAY_NOLOAD_API=PASS`
- `RELAY_NOLOAD_PHYSICAL=PASS`
- `RELAY_NOLOAD_HARDWARE=PASS`
- `MANUAL_RELAY_ON_OFF_REGRESSION=PASS`

## 6.3 Windows AP transport caveat

Windows adapter: Realtek RTL8188EU.
Observed severe instability even at reported 100% signal:
- ping 13/30 PASS
- HTTP root 6/20 PASS
- diagnostic classification `AP_OR_RF_LINK_UNSTABLE`

This occurred independently of Wi-Fi scan handler. Therefore Windows RTL8188EU must not be used as the sole authoritative networking acceptance client.

Android was substantially more reliable and became the acceptance client for Wi-Fi scan/provisioning/runtime tests.

---

# 7. Wi-Fi scan defect: root cause, fix, flash, acceptance

Initial async scan fix still failed on Android:
```json
{"ok":false,"error":"wifi_scan_failed","message":"Unable to start Wi-Fi scan."}
```

Root cause:
- failed STA connect could leave ESP-IDF in CONNECTING state
- `esp_wifi_scan_start()` rejects scan with `ESP_ERR_WIFI_STATE`
- Arduino maps it to `WIFI_SCAN_FAILED (-2)`

Final source correction:
- source commit `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- file `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- after failed `connectStation()`: non-erasing `WiFi.disconnect(false,false)`
- async scan start gets one non-erasing retry only if STA is not actually connected
- established STA connection is not deliberately disconnected
- SoftAP remains enabled

CI #14:
- run ID `42456112148`
- overall SUCCESS
- ESP32 compile PASS
- Flutter analyze/test PASS
- Android APK PASS

Approved APP0 scanfix2 runner:
`tools/windows/FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd`

Physical flash PASS:
- `APP0_RECOVERY_WRITE=PASS`
- APP SHA256 `479002f5592a621723181b03b82f8677a4b8a7571b2bbe654801fc77b156edb8`
- APP bytes `1058448`
- COM5
- NVS preserved
- OTADATA preserved
- partition table preserved
- bootloader preserved
- erase-all NO
- evidence dir:
  `D:\FarmCart\smart-farm-5f\tools\windows\\..\..\..\backups\farmcart_r814_scanfix2_sta_state_COM5_20261108_140539`

Android runtime acceptance after flash:
- `/api/wifi/scan` returned `ok=true`
- `scanning=false`
- `scanState=complete`
- network `Ratthaphum` discovered
- prior `wifi_scan_failed` defect CLOSED

Status:
- `WIFI_SCANFIX_RUNTIME=PASS`
- `DEFECT_WIFI_SCAN_FAILED=CLOSED`
- **Do not reflash this fix again.**

---

# 8. End-to-end Wi-Fi provisioning PASS

User tested the real Android app flow:
1. app scanned Wi-Fi
2. selected home Wi-Fi
3. controller provisioned to home STA
4. controller data returned to the app
5. relay ON/OFF worked normally after provisioning

Status:
- `WIFI_SCAN_IN_APP=PASS`
- `WIFI_PROVISIONING_TO_HOME_STA=PASS`
- `POST_PROVISION_CONTROLLER_DATA_RETURN=PASS`
- `POST_PROVISION_RELAY_CONTROL=PASS`
- `LOCAL_TO_STA_TRANSITION=PASS`

---

# 9. Rapid-command latest-state PASS

Flutter `DeviceStore` already contains per-device latest-intent coalescing:
- `_DeviceCommandState.latestDesiredState`
- `_drainOutputCommands()`

Automated tests cover:
- rapid ON -> OFF while first request is active
- command arriving exactly as active request completes

Physical Android runtime sequence:
`ON -> OFF -> ON -> OFF`

User reported PASS:
- final physical/app state OFF
- no stale earlier command reasserted
- controller remained usable

Status:
- `RAPID_LATEST_STATE_RUNTIME=PASS`

---

# 10. Emergency Stop: controller behavior + Android UI bug + final PASS

Controller E-Stop design:
- `POST /api/emergency-stop`
- loops CH1..CH8 and forces OFF via manual override
- overrideSeconds=0 means non-expiring OFF override
- sets `_emergencyLatched=true`
- persists `sf-wifi/emergency=true` to NVS
- relay ON while latched returns HTTP 423 `emergency_latched`
- boot reloads persisted emergency latch and forces all relays OFF
- `POST /api/emergency-release` clears overrides and persists `emergency=false`

User explicitly approved E-Stop NVS mutation and release.

Initial physical test:
- relay physically turned OFF = PASS
- but Android switch stayed visually ON = BUG

Root cause:
- `OutputDeviceCard` used `requestedOn || active`
- `DeviceStore.emergencyStopAllOutputs()` cleared only `isOn`
- stale `requestedOn=true` kept switch visually ON even though hardware was OFF

App fix commits:
- `1ac3e20d8c7fdcfe0ece1e0a939c0fca425940d3` — clear requested state on E-stop
- `c98065d99cb7960d95557acd5f712b2871777ea5` — reconcile all outputs OFF while emergency latched, clear stale queue/waiting state
- `c73e4e2cc0dbad2c200d2a8b631c2cff170dd8d7` — disable output switches while emergency latch active
- `24fbabe33521290bfc59762f77c4d5011d4ab131` — pass emergency latch state into output controls
- `64c85cb328233d9853cfcd43a3eea59726459991` — state regression tests
- `7db8340affe8964560004386966800eea8b9319b` — widget regression tests

Desired UX now locked:
- E-Stop -> all physical relays OFF
- all app switches move OFF
- switches disabled while latched
- reboot while latched -> still OFF/disabled
- Release -> outputs remain OFF, switches enabled
- user can press ON once after Release; no need to press OFF first

CI #20:
- run ID `42476651695`
- head `7db8340affe8964560004386966800eea8b9319b`
- Flutter analyze/test PASS
- ESP32 compile PASS
- Android APK PASS

APK used for runtime retest:
- artifact ID `13615479234`
- artifact ZIP digest `sha256:a067203e608c580e9329fcfec18c328a5d8e4649b55b13abf20153c2c77dfa6a`
- extracted APK bytes `155572718`
- APK SHA256 `f9b02ed1226f70011207fc76a9ceb3d8fd31961e194a37c05d27befca2876eae`

Final user runtime retest: PASS.

Final status:
- `EMERGENCY_STOP_PHYSICAL_OFF=PASS`
- `EMERGENCY_STOP_LATCH_PERSISTENCE=PASS`
- `EMERGENCY_STOP_APP_UI_RUNTIME=PASS`
- `EMERGENCY_RELEASE_RUNTIME=PASS`
- `E_STOP_NOLOAD_GATE=PASS`
- ESP32 reflash required = NO

---

# 11. APK size note

Current CI APK is a **debug APK**, not production package.

CI currently uses:
```text
flutter build apk --debug
```

Observed APK size:
- about 155.6 MB

Reason:
- debug runtime/kernel included
- multiple ABIs bundled (arm64-v8a, armeabi-v7a, x86_64)
- debug/validation libraries included

This is normal for the current demo/test APK and is **not a current functional blocker**.

Later production packaging should use:
- release APK, preferably split per ABI, and/or
- Android App Bundle (.aab)

Do not spend time optimizing package size before functional/safety acceptance unless user changes priority.

---

# 12. RTC current state / deferred issue

RTC work is NOT fully closed.

Historical runtime:
- DS3231 detected
- explicit RTC sync semantic result PASS
- later retention after power interruption failed
- runtime had `available=true`, `valid=false`, `quality=lost_power`, `readFailures=0`
- suspected physical backup-cell / power-retention issue
- no further RTC write/resync should be done casually until battery/power path is revisited

Implication:
- RTC-dependent schedule/clock acceptance remains deferred/blocked until hardware retention is resolved or explicitly waived.
- non-RTC acceptance can continue.

Do not claim overall R8.14 hardware acceptance complete while RTC retention remains unresolved.

---

# 13. Current PASS matrix

Confirmed PASS:
- Flutter analyze/test on current E-Stop UI fix
- ESP32-S3 N16R8 compile
- APP0 scanfix2 physical flash + hash verification
- Android controller API reachability
- Wi-Fi async scan start/complete
- in-app Wi-Fi scan
- home Wi-Fi provisioning
- post-provision controller data return
- post-provision normal relay control
- CH1..CH8 relay no-load API switching
- CH1..CH8 physical LED/click mapping
- rapid latest-state runtime
- E-Stop physical OFF
- E-Stop NVS latch persistence through reboot
- E-Stop Android UI synchronization
- Emergency Release
- final E-Stop no-load gate

Known defects CLOSED:
- `wifi_scan_failed`
- stale Android E-Stop switch state

Known caveat:
- Windows RTL8188EU AP transport is unreliable and must not override Android runtime evidence.

---

# 14. What remains / do not accidentally skip

The new chat must inspect latest Handoff + checklist and reconcile remaining items. At minimum, these remain relevant:

## Non-RTC functional acceptance
- Edit schedule/condition Save regression
- Delete an ON device -> relay must be OFF before profile disappears
- connection-health behavior:
  - clock endpoint failure while controller reachable must stay Online
  - snapshot endpoint failure while controller reachable must stay Online
  - state failure with device probe success must stay Online/degraded
  - three consecutive reachability failures -> Offline
  - one successful reachability cycle -> Online immediately

Some of these may already have partial automated coverage; distinguish CI/unit evidence from physical runtime acceptance.

## RTC
- backup cell / retention investigation
- time continuity after real power interruption
- RTC 10-minute stability/health observation if still required
- schedule execution cannot be fully accepted until RTC validity/retention is trustworthy

## Hardware/load
- External pump/valve/actuator/load power is still considered **not yet accepted**.
- Do not connect real loads simply because relay no-load + E-Stop passed.
- Read latest Handoff/requirements and obtain explicit approval for the next load gate.
- When load testing begins, use staged low-risk acceptance and preserve fail-safe OFF behavior.

## Production cleanup later
- review `DEVELOPMENT_CLEAR_WIFI_ON_FIRMWARE_CHANGE`
- AP password / per-device security
- factory reset behavior
- release APK/AAB size optimization
- documentation / screenshots / BOM / project report evidence

## Remote / R9
- Firebase/remote-control architecture is roadmap work and has not replaced the current local-first controller authority.
- Do not start R9 until R8.14 local stability/hardware acceptance is frozen unless user explicitly changes priority.

---

# 15. Recommended next work order

New chat should NOT guess. First perform read-only reconciliation.

Recommended sequence:

1. Fetch live `candidate/r8.14-stability-1` and record current HEAD.
2. Read this handoff + canonical handoff + latest continuation.
3. Read current source around the next proposed gate.
4. Reconcile stale docs/checklist with runtime PASS already recorded.
5. Prefer closing remaining **non-RTC, no-load** regressions next:
   - schedule/condition Save
   - safe delete of an ON device
   - connection-health/offline threshold behavior
6. Keep RTC retention as a clearly tracked hardware blocker.
7. Only after requirements/Handoff support it and user explicitly approves, proceed to controlled real-load/pump acceptance.
8. After local stable acceptance, freeze a v0.9 Local Stable baseline.
9. Then production cleanup / release package optimization.
10. R9 Remote comes after local stability freeze unless user reprioritizes.

---

# 16. Files the new chat must read

Mandatory:
- `docs/handoff/FARMCART_SMARTGROW_NEW_CHAT_HANDOFF_20261108.md`
- `docs/handoff/FARMCART_SMARTGROW_CONTINUATION_HANDOFF_R8_14_20261107.md`
- `docs/handoff/FARMCART_SMARTGROW_CONTINUATION_LATEST_20261108.md`
- `docs/TEST_CHECKLIST_R8_14_STABILITY.md`
- `docs/RELEASE_NOTES_R8_14_STABILITY.md`
- `docs/ROADMAP.md`
- `README.md`

Then read source relevant to the next gate. Typical important files:
- `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- `esp32/SmartFarm_ESP32_5F/RelayManager.cpp`
- `esp32/SmartFarm_ESP32_5F/AutomationEngine.cpp`
- `esp32/SmartFarm_ESP32_5F/Protocol.cpp`
- `flutter/lib/controllers/smart_farm_controller.dart`
- `flutter/lib/stores/device_store.dart`
- `flutter/lib/services/esp32_http_service.dart`
- `flutter/lib/widgets/output_device_card.dart`
- `flutter/lib/screens/devices_screen.dart`
- `flutter/lib/screens/dashboard_screen.dart`
- relevant tests under `flutter/test/`

---

# 17. Do-not-regress list

The new chat must not:
- reflash scanfix2 without new technical reason
- treat Windows RTL8188EU packet loss as proof of global ESP32 failure
- resurrect stale `wifi_scan_failed` conclusions
- remove latest-intent queue behavior
- let E-Stop UI remain ON while hardware is OFF
- permit relay ON while emergency latch is active
- reconnect real loads before approved load gate
- overwrite NVS/OTADATA/partition/bootloader casually
- erase all flash
- merge main
- use old README/ROADMAP status to undo newer runtime PASS
- claim RTC stable while retention problem remains unresolved

---

# 18. Current project state in one block

```text
PROJECT=FarmCart SmartGrow
BRANCH=candidate/r8.14-stability-1
MAIN=UNTOUCHED

FW=0.8.0-5f-r8.14-stability-1
ESP32=ESP32-S3 N16R8
MAC=14:c1:9f:50:b9:64
FLASH_BAUD=115200

SCANFIX2_FLASH=PASS
WIFI_SCANFIX_RUNTIME=PASS
WIFI_PROVISIONING_TO_HOME_STA=PASS
POST_PROVISION_RELAY_CONTROL=PASS

RELAY_NOLOAD_HARDWARE=PASS
RAPID_LATEST_STATE_RUNTIME=PASS

EMERGENCY_STOP_PHYSICAL_OFF=PASS
EMERGENCY_STOP_LATCH_PERSISTENCE=PASS
EMERGENCY_STOP_APP_UI_RUNTIME=PASS
EMERGENCY_RELEASE_RUNTIME=PASS
E_STOP_NOLOAD_GATE=PASS

ESP32_REFLASH_REQUIRED=NO

RTC_SYNC_SEMANTIC=PASS
RTC_RETENTION_AFTER_POWER_LOSS=FAIL/DEFERRED
RTC_DEPENDENT_ACCEPTANCE=BLOCKED

REAL_LOAD_ACCEPTANCE=NOT_YET_PASS
LOAD_POWER=KEEP_DISCONNECTED_UNTIL_NEXT_APPROVED_GATE

CURRENT_ANDROID_BUILD=CI20_DEBUG
APK_SHA256=f9b02ed1226f70011207fc76a9ceb3d8fd31961e194a37c05d27befca2876eae
APK_SIZE_DEBUG_BYTES=155572718
PRODUCTION_APK_OPTIMIZATION=LATER

NEXT=READ_ONLY_RECONCILE_THEN_CLOSE_REMAINING_NON_RTC_NOLOAD_GATES
```

---

# 19. Final instruction to the next assistant

Act like an embedded/backend/mobile QA engineer continuing an existing system, not like a new assistant starting a new project.

Use evidence, exact SHAs, runtime state and hardware identity. Preserve all already-passed gates. Read before patching. Record meaningful progress into GitHub Handoff. Do not make the user retrain the workflow.

---

## 20. 2026-11-08 evening continuation — non-RTC host regression expansion

### GitHub source-of-truth reconfirmation
- Read-only inspection at start: `candidate/r8.14-stability-1` HEAD was `d7f911c72a5265fa3cbbb3cccf18b6c7e85ac94f`, identical to prior Handoff.
- PR #1 remains DRAFT and UNMERGED; `main` untouched.
- Read current handoffs, README, ROADMAP, R8.14 checklist/release notes, and relevant ESP32 / Flutter production code and test files.
- No separate `requirements/` or `docs/requirements/` currently exists. Effective requirements remain the Handoff, docs and live source.
- CI #20 (`42476651695`) directly verified: Flutter analyze/test, ESP32 compile and debug APK all SUCCESS for `7db8340affe8964560004386966800eea8b9319b`.
- Latest no-load runtime PASS (scan, provisioning, relay CH1–CH8, rapid latest-state, E-Stop/release) is preserved; do not reopen those gates without new evidence.

### Source-path findings
- Schedule/condition Save: `OutputDeviceDialog._save -> DeviceStore.updateOutput -> _syncProfile -> SmartFarmController.saveDeviceProfile -> /api/v3/devices/config`. Local profile is replaced only after controller accepts.
- Safe Delete: `DeviceStore.removeOutput -> SmartFarmController.deleteDeviceProfile -> /api/v3/devices/delete`; ESP32 `WiFiTransport::handleDeviceDelete` forces transient relay OFF, clears persisted channel, then removes the rule before returning success. This is SOURCE observation, not yet physical runtime PASS.
- Connection health: `SmartFarmController.refreshState` falls back from `/api/state` to `/api/device`; clock/snapshot failures have separate counters; 3 reachability misses required for Offline, success returns Online.
- Concurrent Delete while a relay command is in flight is NOT separately accepted. Treat as an unverified edge case, not a confirmed runtime defect. Do not infer safety from the client mock alone.

### Candidate test-only commits
- `42b19441173d511e939eeb799c3e1ee3d9477743`: 2 connection-health tests (3 failures then immediate recovery, clock/snapshot degradation).
- `fbc8090e1416da0f50495f8db8c464638fb29919`: 4 new DeviceStore profile tests (schedule Save, sensor condition Save, rejected Save preserving local model, delete acknowledgement barrier).
- CI #22 / `42482371127`: Flutter analyze PASS; test suite 26 PASS / 1 FAIL. The failure was isolated to the new delete-test fixture: saved device ON but fake controller relay default OFF, so normal reconciliation reset it.
- `1a3a0ce8d394720fde5d7c087ee85c72f53fe8fc`: corrected fake relay physical state to ON at fixture setup; no production source change.
- CI #23 / `42482499529` for `1a3a0ce8d394720fde5d7c087ee85c72f53fe8fc`: Flutter analyze/test job SUCCESS at last check. ESP32 compile / Android APK jobs still IN_PROGRESS when this entry was prepared; full CI SUCCESS must not be claimed until verified.
- No firmware flash, no real load, no NVS write, no RTC sync, no production code change, no `main` merge during this new-chat continuation.

### Remaining next action / gates
1. Verify the final CI #23 result and exact jobs. Ignore stale failures when a newer exact-source CI passes, but retain failure history.
2. Reconcile stale checklist/README statuses against Handoff runtime PASS; do not downgrade an accepted gate.
3. For Android no-load **Edit schedule/condition Save** and **Delete an ON device**, obtain explicit approval for profile/relay Preferences-NVS mutations. Confirm the FarmCart physical target and keep pump/valve/actuator external load power disconnected.
4. Runtime Delete requires relay OFF, controller rule absent, local device gone, and no restored ghost state after reboot if the reboot is separately authorized. Host mocks do not replace this proof.
5. Connection-health host tests are separate from physical/Android failure-injection acceptance.
6. DS3231 retention after power loss remains FAIL/DEFERRED; RTC-dependent schedule execution and real load gates remain BLOCKED.
7. Keep `main` untouched; do not reflash scanfix2 or start R9 Remote before local-stable freeze.

Current continuation target: finish non-RTC, no-load acceptance with source/test/runtime evidence, then investigate RTC battery retention; preserve all previously passed safety behavior.
