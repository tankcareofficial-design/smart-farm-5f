# FarmCart SmartGrow — Continuation Handoff

> READ THIS FIRST before continuing Smart Farm / FarmCart work.
> Do not restart from an older baseline. Do not claim PASS without evidence.

## Project identity

- Official working name: **FarmCart SmartGrow**
- Thai project name: **FarmCart SmartGrow ชุดสาธิตฟาร์มอัจฉริยะควบคุมและดูแลพืชผ่านมือถือ**
- English subtitle: **Smart Farm Control and Plant Monitoring System**
- Repository: `tankcareofficial-design/smart-farm-5f`
- Stable branch: `main`
- Active candidate branch: `candidate/r8.14-stability-1`
- Draft PR: #1 — R8.14 Stability 1: RTC & Controller Link Health

## Current source truth — 2026-11-07

- `main` baseline remains unchanged at the accepted R8.13 Rebase 3 line.
- Active candidate head before this handoff commit:
  `4cdf60fde2cb77e01190830c6e662e5300f41618`
- Earlier R8.14 commits:
  - `ffe38abf9ac1527305247b667cab7ccf3637ff2b` — initial R8.14 stability work
  - `c83ce851f00dcd0a454e951131881e72b8049374` — CI adjustment
  - `7b126fa68c88ff72ea4b02690a7b72028da6dac9` — remove unused DeviceStore helper / analyze fix
  - `3088c50c5d8c25c9a73752877652a71662ba7eee` — regression-test compatibility fixes
  - `4cdf60fde2cb77e01190830c6e662e5300f41618` — corrected communication-health expectation

## R8.14 scope already implemented

### ESP32 / RTC stability
- DS3231 transient transport-failure hysteresis.
- If the clock was previously verified, 1–2 transient transport misses retain the verified clock in degraded state.
- 3rd consecutive transport failure invalidates the clock fail-safe.
- RTC time/status committed coherently.
- DS3231 temperature read failure does not invalidate scheduler time.

### Flutter connection stability
- Removed automatic phone-time writes triggered by transient RTC degradation.
- Controller reachability is separated from clock/snapshot health.
- `/api/state` failure falls back to `/api/device` before counting a link failure.
- 3 reachability failures required before Offline.
- Relay/emergency command failure does not immediately mark controller Offline.
- Device Online indication follows controller reachability rather than RTC validity.

## Latest CI evidence

For commit `7b126fa68c88ff72ea4b02690a7b72028da6dac9`:
- ESP32-S3 compile: **PASS**
- Flutter analyze: **PASS**
- Flutter test: **FAIL — 12 passed / 5 failed**

The 5 failures were identified as test/baseline compatibility issues:
1. Widget test constructed `SharedPreferencesAsync` before a platform instance existed.
2. Farm health test expected old English alert text.
3. Farm health test used relay count 12 while current model is 8-channel.
4. Offline farm health test expected old English text.
5. Dashboard test expected old label `Smart Farm 5F`.

Fixes were committed in `3088c50...` and `4cdf60f...`.

**IMPORTANT:** At the time this handoff was written, a new CI result for `4cdf60f...` had not yet been observed. Therefore:
- Flutter test is **NOT YET CLAIMED PASS**.
- Full R8.14 CI is **NOT YET CLAIMED GREEN**.
- Hardware acceptance is **NOT YET CLAIMED PASS**.

## Required next action

1. Re-check GitHub Actions for the latest candidate head.
2. If CI is green, record exact run ID / jobs / conclusions here or in a new handoff revision.
3. If CI still fails, inspect the failing job log and fix only the candidate branch.
4. Do not merge to `main` until CI is green and hardware acceptance is completed.
5. After R8.14 stability gate closes, continue the fast demo plan below.

## Fast demo priority

The user needs a proposal/demo quickly. Do not follow the old slow calendar.

Priority:
1. R8.14 CI green
2. Android APK/demo build
3. Real ESP32-S3 + relay + DS3231 hardware verification
4. Branding to **FarmCart SmartGrow**
5. Crop Profile v1
6. Pump + mist irrigation logic
7. Remote Internet monitoring/control
8. ESP32-CAM snapshot/monitoring
9. Presentation polish / backup screenshots/video

Do not spend demo time first on nonessential cloud analytics, long-term graphs, or unrelated features.

## System architecture requirement

FarmCart SmartGrow is **Local-first + Internet Remote Control**, not Offline-only.

### Local operation
- ESP32-S3 is the source of truth.
- Controller must continue schedules / sensor automation / crop profile logic even if the phone or Internet is unavailable.
- The phone can connect locally to the controller Wi-Fi/AP for setup and control.

### Internet operation
- When Internet is available, the user must be able to monitor and control the system remotely.
- Cloud/remote path must not become the sole automation authority.
- Loss of cloud connectivity must not stop irrigation, schedule, safety, or sensor control.
- Remote commands must still pass controller-side validation and safety rules.

## Crop Profile requirement

Crop Profile is a major project differentiator.

Initial target crops:
- ผักบุ้งจีน
- ผักสลัด / ผักกาดหอม
- คะน้า
- กวางตุ้ง
- พริก
- มะเขือเทศ
- กะเพรา
- โหระพา
- แตงกวา
- ถั่วฝักยาว
- ผักชี
- Custom

Profile fields should support:
- temperature range
- humidity range
- soil moisture target based on **local sensor/soil calibration**
- irrigation start/stop threshold
- light schedule / low-light behavior
- watering strategy
- max pump runtime
- cooldown between irrigation cycles
- reference/source metadata
- user override/customization

Do **not** copy a generic Internet soil-moisture percentage directly into control logic. Capacitive soil sensor percentages must be calibrated against the actual sensor, soil/media, dry/wet points, or field-capacity reference.

## Irrigation hardware / logic

User plans to use:
- 12 V pump
- dual mist/fog nozzles

Treat irrigation and cooling/humidity as separate control intents even if they use the same pump:
- **Irrigation:** soil is dry -> run pump/mist -> stop at target/time/dose -> cooldown.
- **Cooling/Humidity:** high temperature or low RH -> short mist pulse -> wait -> re-read environment -> decide again.

Add pump calibration later:
- run pump for a known duration
- measure actual delivered mL
- derive mL/min
- use that value for dose estimation and safety limits

## Camera requirement

User owns an ESP32-CAM.

Preferred architecture:
- ESP32-CAM joins the SmartFarm Wi-Fi network.
- Flutter accesses JPEG snapshot / HTTP stream over Wi-Fi.
- ESP-NOW may be used for trigger/heartbeat/status if useful.
- **Do not transport live image/video over ESP-NOW.**
- Camera failure must not affect controller operation.

Demo camera v1:
- Camera Online status
- Snapshot
- Refresh/manual capture
- Flash toggle if supported
- Timelapse/growth history can come later

## Hardware baseline

ESP32-S3 N16R8, 44-pin.

RTC DS3231:
- SDA GPIO8
- SCL GPIO9

Relay ACTIVE HIGH:
- CH1 GPIO4
- CH2 GPIO5
- CH3 GPIO6
- CH4 GPIO7
- CH5 GPIO15
- CH6 GPIO16
- CH7 GPIO17
- CH8 GPIO18

Safety:
- outputs start OFF
- controller is source of truth
- preserve Emergency Stop behavior
- preserve max-runtime / safe-off principles
- do not restore stale deleted-device relay state from NVS

## Historical defects that must not regress

- Deleted device restoring old relay/profile from ESP32/NVS.
- New device inheriting stale relay state/rules.
- Schedule OFF disabling device / conflicting logic.
- Rapid relay taps lagging or dropping.
- Ghost relay re-ON after OFF.
- Multiple automation paths writing the same relay.
- Persisted relay state restored before automation reconciliation.
- RTC transient failures causing app Online/Offline flapping.
- One command failure marking controller Offline.
- Device edit Save button deadlock / invalid state.
- Unsafe delete without verified relay OFF.

## Work rules

- Always read the newest handoff + candidate branch head before editing.
- Inspect source and CI/log evidence read-only first.
- Continue from the latest verified baseline; do not recreate old solutions from memory.
- Keep `main` stable.
- Work on candidate branches / PRs.
- Never say Build PASS, Test PASS, Hardware PASS, Runtime PASS, or Deploy PASS without direct evidence.
- Separate SOURCE / STATIC / BUILD / TEST / FLASH / HARDWARE / RUNTIME status.
- Before flash, deploy, destructive storage mutation, or merge to main, require explicit approval unless already specifically authorized.
- When completing a meaningful step, update this handoff or create a dated handoff revision with:
  - date/time
  - branch
  - commit SHA
  - what changed
  - test evidence
  - what remains
  - exact next action

## Presentation positioning

Primary differentiator:
**Crop-aware, local-first smart farm controller with remote Internet access.**

Do not market it as merely:
`ESP32 + soil sensor + relay + app`.

Key points:
- Crop Profile adapts behavior to the selected crop.
- Controller continues locally without Internet.
- Remote monitoring/control works through Internet when available.
- 8-channel modular control.
- Pump + dual mist irrigation.
- Safety-aware automation.
- Camera module for observation.
- Educational/demo platform that can be reused with multiple crops.

## First instruction for a new chat

When opening a new chat, the correct starting instruction is:

**“อ่าน docs/handoff/FARMCART_SMARTGROW_CONTINUATION_HANDOFF_R8_14_20261107.md และตรวจ GitHub branch candidate/r8.14-stability-1 แบบ read-only ก่อน จากนั้นเช็ก CI ของ HEAD ล่าสุด แล้วทำต่อจาก Next Action ห้ามเริ่มใหม่หรือย้อนใช้ baseline เก่า”**
