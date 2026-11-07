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


## R8.14 CI closure — 2026-11-07

### Branch / source
- Branch: `candidate/r8.14-stability-1`
- Source SHA that closed the CI gate: `3c83f31bdd894121f60b52d3a45c4dc816d325de`
- CI-fix commits after the original handoff:
  - `e81ccdb3711f31ddf50ce4d9fc0dc3994b0f337a` — first lint-suppression attempt; CI still failed because the diagnostic was emitted on the initializer line.
  - `3c83f31bdd894121f60b52d3a45c4dc816d325de` — moved the suppression to the exact initializer diagnostic while preserving the public `preferences:` constructor API.

### CI evidence
- GitHub Actions workflow: **Smart Farm CI**
- Run ID: **42324520907**
- Run number: **8**
- Overall conclusion: **SUCCESS**
- Job `Flutter analyze and test`: **SUCCESS**
  - `flutter analyze`: **SUCCESS**
  - `flutter test`: **SUCCESS**
- Job `ESP32-S3 compile`: **SUCCESS**
  - controller firmware compile: **SUCCESS**

Therefore the **R8.14 CI gate is GREEN** for source SHA `3c83f31bdd894121f60b52d3a45c4dc816d325de`.

### Status separation
- SOURCE: **PASS for R8.14 candidate scope at `3c83f31bdd894121f60b52d3a45c4dc816d325de`**
- STATIC / ANALYZE: **PASS**
- TEST: **PASS**
- ESP32 BUILD: **PASS**
- ANDROID APK BUILD: **NOT YET VERIFIED**
- FLASH: **NOT PERFORMED in this gate**
- HARDWARE: **NOT YET ACCEPTED**
- RUNTIME ON REAL CONTROLLER / DS3231: **NOT YET ACCEPTED**
- MERGE TO `main`: **BLOCKED until hardware acceptance is completed**

### Exact next action
1. Build the **Android APK/demo** from the current R8.14 candidate without changing the accepted stability behavior.
2. Record exact APK build evidence/artifact.
3. Then perform real ESP32-S3 + relay + DS3231 hardware verification using the existing hardware acceptance checklist.
4. Keep `main` unchanged until the hardware gate passes.
5. After the stability/hardware gate closes, continue Branding → **FarmCart SmartGrow** → Crop Profile v1.


## Android demo APK build closure — 2026-11-07

### Build source
- Branch: `candidate/r8.14-stability-1`
- Workflow/source SHA: `566cc4843a121dfefc9d7583f1398736b134c186`
- Change: added an isolated `Android demo APK` CI job only; no FarmCart/ESP32 runtime behavior was changed.

### CI / APK evidence
- Workflow: **Smart Farm CI**
- Run ID: **42324779679**
- Run number: **10**
- Overall conclusion: **SUCCESS**
- `Flutter analyze and test`: **SUCCESS**
- `ESP32-S3 compile`: **SUCCESS**
- `Android demo APK`: **SUCCESS**
  - `Build debug APK`: **SUCCESS**
  - `Upload demo APK`: **SUCCESS**

### Artifact
- Artifact ID: **13555126834**
- Name: `farmcart-smartgrow-r8.14-demo-apk`
- Size: **74,778,477 bytes**
- Digest: `sha256:88deabab0e3defd2130eb3a25a017efb4b3a94ea8fe919f66c630a21a0bcd18a`
- Created: **2026-11-07T01:39:26Z**
- Expires: **2026-11-21T01:39:21Z**
- Artifact source SHA: `566cc4843a121dfefc9d7583f1398736b134c186`

### Status separation after APK gate
- SOURCE: **PASS for current R8.14 runtime source**
- STATIC / ANALYZE: **PASS**
- TEST: **PASS**
- ESP32 BUILD: **PASS**
- ANDROID APK BUILD: **PASS**
- APK ARTIFACT: **PRESENT / VERIFIED**
- FLASH: **NOT PERFORMED**
- HARDWARE: **NOT YET ACCEPTED**
- RUNTIME ON REAL ESP32-S3 / relay / DS3231: **NOT YET ACCEPTED**
- MERGE TO `main`: **BLOCKED**

### Exact next action
Perform the existing **R8.14 real-hardware acceptance** on ESP32-S3 + relay + DS3231. Do not merge to `main` until that hardware/runtime evidence passes. Flashing remains approval-gated under the project work rules.


## Master implementation roadmap — FarmCart SmartGrow — 2026-11-07

This roadmap is the project-level continuation plan. New chats must use it together with the latest branch/HEAD/CI evidence. Do not skip back to an older phase unless a regression requires it.

### Phase 0 — Close R8.14 hardware/runtime acceptance [CURRENT]

Goal: prove the already-built stability candidate on the real ESP32-S3 + relay + DS3231 before adding new feature scope.

Required evidence:
- flash the accepted R8.14 controller image only after explicit approval
- controller reachable and Online state stable
- `/api/state` failure falls back to `/api/device` as designed
- reachability hysteresis: do not declare Offline on the first transient miss
- DS3231 transport miss #1 and #2 stay degraded/usable after a previously verified clock
- DS3231 transport miss #3 triggers fail-safe invalidation
- RTC recovery returns to valid state
- `lost_power` remains distinguishable from transport/read error
- verify there is no unwanted automatic phone-time write during transient RTC degradation
- observe RTC + controller Online state continuously for at least 10 minutes
- regression test relay ON/OFF, rapid commands, Emergency Stop, schedule Save, manual override, device edit, and delete-device safe-off

Gate:
- FLASH / HARDWARE / RUNTIME remain NOT PASS until physical evidence exists.
- `main` remains unchanged until explicit merge approval after the gate passes.

### Phase 1 — Freeze R8.14 and create the FarmCart SmartGrow demo line

After Phase 0 passes:
- record hardware/runtime evidence in this handoff
- request explicit approval before merge to `main`
- after accepted merge, create a new candidate branch for demo/product work; recommended naming:
  `candidate/r8.15-farmcart-smartgrow-demo`
- preserve R8.14 as the rollback baseline

Do not mix major Crop Profile / Cloud / Camera work into the R8.14 stability PR.

### Phase 2 — Product branding / presentation identity

Goal: make the current app visibly become **FarmCart SmartGrow** without changing controller safety behavior.

Scope:
- app display title: FarmCart SmartGrow
- splash / home / dashboard branding
- remove obsolete user-facing `Smart Farm 5F` / `Smart Farm+` branding where appropriate
- keep internal package/repository identifiers unchanged unless changing them is necessary
- update release/version labels for the demo line
- prepare a simple project identity block for proposal/presentation

Acceptance:
- Flutter analyze PASS
- Flutter test PASS
- Android APK build PASS
- no controller/relay regression

### Phase 3 — Crop Profile v1 [PRIMARY DIFFERENTIATOR]

Goal: user selects a crop and the system loads a curated starting profile while still allowing calibration and manual customization.

Initial crop set:
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

Implementation steps:
1. inspect current Flutter data models, DeviceStore, automation models, controller API, NVS schema, and scheduling code read-only
2. define versioned `CropProfile` schema
3. research agronomic starting ranges from authoritative agricultural/university sources
4. store curated profiles offline in the app with source/reference metadata
5. create Crop Profile selection UI
6. allow user override/customization
7. resolve the selected profile into concrete controller thresholds/schedule values
8. persist only validated resolved settings on ESP32
9. controller continues using the last valid profile even when phone/Internet is unavailable

Safety/data rule:
- do not treat generic Internet soil-moisture percentages as directly valid sensor thresholds
- actual soil moisture control must use the user's calibrated sensor/media dry/wet or field-capacity reference

Demo acceptance:
- select crop -> preview settings -> apply -> controller receives validated profile -> disconnect phone -> controller continues locally

### Phase 4 — Sensor calibration and real environmental inputs

Target sensor groups:
- soil moisture
- temperature / humidity
- light
- water level
- INA226 power/current monitoring

Steps:
- confirm which physical sensors are actually available before coding hardware-specific assumptions
- create sensor calibration/status UI
- distinguish LIVE / STALE / ERROR / NOT INSTALLED
- never invent sensor values
- if simulated values are used for the proposal demo, label them clearly as DEMO/SIMULATION
- make Crop Profile use calibrated sensor data, not raw ADC numbers

### Phase 5 — Pump + dual mist/fog nozzle control

Hardware intent:
- 12 V pump
- two mist/fog nozzles

Control intents must remain separate even if they share the same pump:
- **Irrigation:** soil/media is too dry -> run -> stop at target/time/dose -> cooldown
- **Cooling/Humidity:** temperature high or RH low -> short pulse -> wait -> re-read -> decide again

Required safety:
- maximum continuous pump runtime
- minimum cooldown
- low-water lockout when water-level sensing is available
- Emergency Stop override
- fail-safe OFF on invalid control state
- no ghost re-ON from stale NVS/schedule state

Pump calibration:
- run pump for a known duration
- measure actual delivered mL through the real two-nozzle assembly
- calculate mL/min
- use calibrated flow for dose estimate and daily water total

Demo acceptance:
- Manual Pump/Mist ON/OFF
- calibrated flow shown
- automated soil-triggered cycle
- safety timeout verified

### Phase 6 — Internet remote monitoring/control

Architecture rule:
**Local-first + Internet Remote Control. ESP32 remains the automation authority.**

Before implementation:
- inspect existing Wi-Fi/provisioning/API architecture
- choose the smallest secure cloud transport compatible with the current codebase
- do not make remote/cloud logic bypass controller-side validation

Required capabilities:
- view controller Online/Offline remotely
- view sensor state remotely
- remote relay/manual command
- remote Crop Profile/config sync
- command acknowledgement/state reconciliation
- last-seen / connection state
- Internet loss does not stop local schedules, irrigation, safety, or Crop Profile

Security baseline:
- per-device credential
- authenticated commands
- TLS where supported
- no hard-coded shared production secret in app/source
- no direct public exposure of ESP32 HTTP port

Demo acceptance:
- phone leaves SmartFarm local Wi-Fi
- uses Internet/mobile data
- app still shows current controller state
- remote command reaches controller and confirmed state returns
- disconnect Internet -> local automation continues

### Phase 7 — ESP32-CAM module

Local v1:
- ESP32-CAM joins SmartFarm Wi-Fi
- Camera Online status
- JPEG snapshot
- manual refresh / capture
- flash control when supported

Architecture rules:
- do not send live image/video payload over ESP-NOW
- ESP-NOW may be used only for small trigger/heartbeat/status messages if needed
- camera failure must never block controller operation

Remote evolution:
- prefer controlled snapshot upload / cloud relay for remote viewing
- avoid unsafe router port-forwarding as the normal design
- timelapse/growth history can be added after the proposal demo

### Phase 8 — Demo/presentation package

Prepare a 1–2 minute reliable demonstration:
1. open FarmCart SmartGrow app
2. controller Online
3. select a crop profile
4. show real sensor/calibration data
5. manually trigger Pump/Mist
6. show automatic rule/schedule
7. Emergency Stop -> outputs OFF
8. show remote Internet state/control if ready
9. show camera snapshot if ready

Presentation assets:
- architecture diagram
- block diagram / wiring overview
- Crop Profile explanation
- local-first vs cloud explanation
- safety features
- comparison against a generic ESP32 + Blynk + soil sensor project
- backup screenshots
- backup demo video in case live network/hardware fails

### Phase 9 — Post-proposal hardening

After the proposal/demo is secured:
- historical graphs / telemetry retention
- alerts/notifications
- camera timelapse
- OTA/update strategy
- stronger cloud auth/device provisioning
- fault/event history
- irrigation statistics
- enclosure/fuse/E-stop physical build
- long-duration reliability test
- documentation / BOM / wiring / final report

## Fast-track order for the next proposal demo

If time is constrained, prioritize only:
1. R8.14 Hardware Acceptance
2. FarmCart SmartGrow branding
3. Crop Profile v1
4. Pump + dual-mist manual + safe automatic cycle
5. Android APK
6. remote Internet control
7. camera snapshot
8. presentation + backup video

Cloud analytics, advanced graphs, AI, timelapse, and nonessential polish must not block the core demo.

## New-chat continuation rule

A new chat must determine the current phase from **actual branch HEAD + CI/hardware evidence**, not from the calendar.

At startup:
1. read this handoff
2. inspect `candidate/r8.14-stability-1` or the newer candidate named in this handoff
3. verify HEAD and PR state
4. inspect latest CI
5. identify the first incomplete roadmap phase
6. continue there without redoing already-passed gates


## Reset-machine recovery tooling — 2026-11-07

The development PC was reset and the local environment must be restored from GitHub source truth before hardware acceptance continues.

Added:
- `tools/windows/RESTORE_FARMCART_R814_ENV_READONLY.cmd`
- commit `cedbbd01b534885cd2878d3e139de5e8ef473992`

Behavior:
- clones/fetches `tankcareofficial-design/smart-farm-5f`
- checks out `candidate/r8.14-stability-1`
- refuses to reset/switch if local changes exist
- prints candidate HEAD and `origin/main`
- inventories Git / Flutter / Dart / Arduino CLI / Java / ADB / Python
- lists serial ports read-only
- verifies Handoff and R8.14 checklist are present
- `FLASH=NO`, `DEVICE_WRITE=NO`, `NVS_WRITE=NO`, `MERGE_MAIN=NO`

Exact next action:
1. Run the restore/preflight on the reset Windows machine.
2. Return the complete output.
3. Install or repair only the missing toolchain components.
4. Re-run preflight until the environment is ready.
5. Then proceed to the R8.14 hardware preflash gate; flashing still requires explicit approval.
