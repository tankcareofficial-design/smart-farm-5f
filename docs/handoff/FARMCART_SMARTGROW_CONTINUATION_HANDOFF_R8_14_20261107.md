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


## Hardware preflash runner correction — 2026-11-07

Observed on reset Windows machine:
- restore/toolchain gate PASS
- embedded build PASS
- preflash runner stopped before device access with `ERROR=RUNTIME_SHA_MISSING_LOCALLY`

Root cause:
- the runtime SHA exists in GitHub and remains an ancestor of the candidate branch
- Windows CMD interpreted the caret in `%RUNTIME_SHA%^{commit}` as an escape character, causing the local ref check to be malformed
- this was a tooling-script defect only; no firmware/runtime source drift occurred

Correction:
- commit `0f34f2209d53fc64fa8622497b173cfef07829cb`
- changed the runtime object existence check to `git cat-file -e %RUNTIME_SHA%`
- no firmware/app runtime files changed
- `FLASH=NO`, `NVS_WRITE=NO`, `MERGE_MAIN=NO`

Exact next action:
1. pull the latest `candidate/r8.14-stability-1`
2. rerun `tools/windows/RUN_FARMCART_R814_HARDWARE_PREFLASH_READONLY.cmd`
3. review COM/chip/flash identity evidence before any flash approval


## Selectable COM preflash correction — 2026-11-07

Observed on reset Windows machine:
- Arduino CLI board discovery found the FarmCart ESP32 family device on `COM5`
- the preflash runner still hard-coded `COM3` and `COM4`
- the gate therefore failed before any device write even though the board was present

Correction:
- commit `2a82b4302b6600d822c98bcf21893249fe9cd3cf`
- preflash runner now accepts an explicit COM port argument, e.g.:
  `call tools\windows\RUN_FARMCART_R814_HARDWARE_PREFLASH_READONLY.cmd COM5`
- if no argument is supplied, the runner lists serial devices and asks interactively for the COM port
- selected port must match the Windows `COM<number>` form
- the selected port is then verified as ESP32-S3 before the gate continues
- `FLASH_WRITE=NO`, `FLASH_ERASE=NO`, `NVS_READ=NO`, `NVS_WRITE=NO`

Current observed FarmCart candidate port on the reset machine: `COM5`.


## R8.14 hardware preflash gate evidence — 2026-11-07

Observed on reset Windows machine with FarmCart ESP32-S3 connected:
- branch HEAD at probe: `3a81964d92f6c2d7370a28bc3973047a8e230e55`
- runtime source lock against accepted CI SHA `566cc4843a121dfefc9d7583f1398736b134c186`: PASS
- firmware version lock: `0.8.0-5f-r8.14-stability-1` PASS
- hardware mapping lock: PASS
  - relay GPIO: 4,5,6,7,15,16,17,18
  - relay polarity: active HIGH
  - RTC SDA GPIO8 / SCL GPIO9
- local preflash compile: PASS
- app binary bytes: `1052304`
- app binary SHA256 for this local build: `efcf68183523105e126150e1b159294f1e6dca81c521d7802c8e317dd862ebfd`
- selected USB port: `COM5`
- chip probe: PASS
  - ESP32-S3 QFN56 revision v0.2
  - embedded PSRAM 8MB
  - USB-Serial/JTAG mode
- flash ID probe: PASS
  - detected flash size: 16MB
  - quad mode
  - 3.3V
- no flash write, erase, NVS read/write, relay command or merge performed

Important pre-flash review:
- actual hardware is 16MB flash + 8MB PSRAM
- current CI/local compile FQBN is generic `esp32:esp32:esp32s3`
- before flashing, verify the effective Arduino board options (FlashSize / PartitionScheme / PSRAM / memory type) rather than assuming the generic defaults match N16R8 hardware

Added read-only audit runner:
- `tools/windows/RUN_FARMCART_R814_BOARD_CONFIG_AUDIT_READONLY.cmd`
- commit `3a321a18769fdaa1d37b5cdd911bcbbbd82e700f`

Exact next action:
1. pull latest candidate
2. run board configuration audit with `COM5`
3. review effective board options
4. only then prepare a flash command; flash remains approval-gated

## N16R8 board-profile correction and CI closure — 2026-11-07

Board configuration audit from the reset Windows machine proved that the generic `esp32:esp32:esp32s3` FQBN was not suitable for the actual FarmCart controller:
- generic effective flash size: 4MB
- generic partition scheme: `default`
- generic upload maximum size: 1,310,720 bytes
- physical controller probe: ESP32-S3 with 16MB flash and 8MB PSRAM

The physical hardware target is ESP32-S3 N16R8. Espressif documentation identifies N16R8 as QSPI flash + OPI PSRAM.

Canonical R8.14 board profile:
`esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi`

The selected 16MB partition table preserves OTA capability:
- NVS: 0x9000 / 0x5000
- OTA data: 0xE000 / 0x2000
- app0: 0x10000 / 0x300000
- app1: 0x310000 / 0x300000
- FFat: 0x610000 / 0x9E0000
- coredump: 0xFF0000 / 0x10000

Corrections:
- local restore/preflash/audit tooling pinned to the N16R8 profile
- CI pinned to ESP32 core `3.3.12`
- CI pinned to ArduinoJson `7.4.3`
- CI ESP32 job renamed `ESP32-S3 N16R8 compile`
- no controller source behavior was changed by this correction

CI evidence:
- source/config commit: `83b9f6118edef704640763a705f8080a4ede27d4`
- Smart Farm CI run: `42376419148` (#11)
- overall: SUCCESS
- Flutter analyze/test: SUCCESS
- ESP32-S3 N16R8 compile: SUCCESS
- Android demo APK: SUCCESS
- N16R8 compile: sketch 1,057,355 bytes / 3,145,728 bytes (33%)
- globals: 68,052 / 327,680 bytes (20%)
- APK artifact id: `13576415065`
- APK artifact digest: `sha256:af8a54a28def9c1de323dc0c36277a76d263e9953d18365f7945e4e5e4215916`

Gate status:
- SOURCE: PASS for R8.14 candidate scope
- STATIC/ANALYZE: PASS
- TEST: PASS
- ESP32 N16R8 BUILD: PASS
- ANDROID APK BUILD: PASS
- PREFLASH PHYSICAL CHIP/FLASH ID: PASS on COM5
- FLASH: NOT PERFORMED
- HARDWARE ACCEPTANCE: NOT YET PASS
- RUNTIME ACCEPTANCE: NOT YET PASS
- MERGE MAIN: BLOCKED

Exact next action:
1. pull latest candidate on the reset Windows machine
2. rerun the board-config audit and hardware preflash gate using COM5; both must show the canonical N16R8 profile
3. record the local canonical-profile binary SHA256
4. stop at the flash approval gate
5. only after explicit user approval, flash and begin the R8.14 physical runtime checklist

## Preflash FQBN line-break correction — 2026-11-07

Observed after the canonical N16R8 board-config audit passed on COM5:
- board-config audit: PASS
- effective flash size: 16MB
- effective memory type: `qio_opi`
- effective partition scheme: `app3M_fat9M_16MB`
- effective PSRAM type: `opi`
- physical ESP32-S3 / 16MB flash / 8MB PSRAM identity: PASS

The subsequent preflash runner stopped before flashing with:
- `FINDSTR: Cannot open FQBN=...`
- `ERROR=FW_VERSION_MISMATCH`

Root cause:
- tooling patch inserted the characters `\r\n` literally on the `EXPECTED_FW` / `FQBN` assignment line
- Windows CMD therefore parsed the line incorrectly
- this was a runner syntax defect only; it was not a firmware-version mismatch and no device write occurred

Correction:
- commit `8bf8a907ae421154032ed3ea7de2c808bd5ab3df`
- restored a real line break between `EXPECTED_FW` and `FQBN` assignments
- no runtime firmware source changed
- flash/erase/NVS writes remain disabled

Exact next action:
1. pull latest candidate
2. rerun only `RUN_FARMCART_R814_HARDWARE_PREFLASH_READONLY.cmd COM5`
3. review canonical-profile build SHA256 and device identity
4. stop at flash approval gate

## Local preflash generic-FQBN correction — 2026-11-07

Observed on reset Windows machine after the N16R8 board-config audit passed:
- physical ESP32-S3 identity on COM5: PASS
- physical flash ID: 16MB PASS
- board-config audit effective profile: 16MB / qio_opi / app3M_fat9M_16MB / OPI PSRAM PASS
- however local preflash compile still reported maximum app size 1,310,720 bytes, proving that compile was still using generic 4MB FQBN
- local preflash app SHA256 from that incorrect generic-profile build must NOT be used for flashing

Root cause:
- the preflash script defined canonical `FQBN`, but its actual compile command remained hard-coded as `esp32:esp32:esp32s3`
- no firmware runtime source regression and no device write occurred

Correction:
- commit `806ea0348c8d0283dcc80219f6d34dc9a062ff32`
- actual compile command now uses `--fqbn "%FQBN%"`
- added mandatory profile assertions before build:
  - `build.flash_size=16MB`
  - `build.memory_type=qio_opi`
  - `build.partitions=app3M_fat9M_16MB`
  - `build.psram_type=opi`
  - `upload.maximum_size=3145728`
- preflash aborts if any profile assertion mismatches
- flash/erase/NVS writes remain disabled

Exact next action:
1. pull latest candidate
2. rerun only `RUN_FARMCART_R814_HARDWARE_PREFLASH_READONLY.cmd COM5`
3. require `BOARD_PROFILE_LOCK=PASS` and maximum app size 3,145,728 bytes
4. record the new canonical N16R8 local app SHA256
5. stop at flash approval gate

## Canonical N16R8 final preflash PASS — 2026-11-07

Final local preflash evidence on reset Windows machine:
- branch HEAD at test: `ab73b22989891df2cc0f4c967478c6e0dc2245c1`
- runtime source lock against `566cc4843a121dfefc9d7583f1398736b134c186`: PASS
- firmware version: `0.8.0-5f-r8.14-stability-1`: PASS
- canonical board profile lock: PASS
  - FQBN: `esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi`
  - flash size: 16MB
  - memory type: qio_opi
  - partitions: app3M_fat9M_16MB
  - PSRAM: opi
  - app max: 3,145,728 bytes
- local canonical compile: PASS
  - sketch: 1,057,435 bytes (33%)
  - globals: 68,052 bytes (20%)
  - app binary bytes: 1,057,584
  - app SHA256: `8752283c9a1f2b125d2fc12ca05122e3ef046487ada524ede092d62409d1d904`
- physical controller:
  - COM5
  - ESP32-S3 QFN56 rev v0.2
  - embedded PSRAM 8MB
  - physical flash 16MB
  - flash type quad / 3.3V
- preflash port gate: PASS
- flash ID read: PASS
- no flash write, erase, NVS read/write, relay command or merge was performed

Important:
- earlier local app hashes from generic 4MB builds are invalid for flashing and must not be used
- canonical local preflash app hash for this gate is `8752283c9a1f2b125d2fc12ca05122e3ef046487ada524ede092d62409d1d904`
- CI #11 already passed with the same canonical N16R8 board profile

Current gate:
- PREFLASH: PASS
- FLASH: AWAITING EXPLICIT USER APPROVAL
- HARDWARE ACCEPTANCE: NOT STARTED
- RUNTIME ACCEPTANCE: NOT STARTED
- MERGE MAIN: BLOCKED

## Approval-gated N16R8 flash runner prepared — 2026-11-07

Prepared but NOT executed:
- `tools/windows/FLASH_FARMCART_R814_N16R8_APPROVAL_GATED.cmd`
- commit `e6b1797775f1956899da1b4467a4d50c2785e1a5`

Safety behavior:
- requires explicit approval token `FLASH_R814_N16R8`
- refuses to write if branch/worktree/runtime source/profile/device identity checks fail
- revalidates canonical N16R8 profile before flashing
- verifies target is ESP32-S3 with physical 16MB flash
- creates a full 16MB pre-flash readback backup and SHA256 before any write
- builds the canonical N16R8 image and records binary hashes
- uses Arduino CLI upload recipe for the canonical FQBN
- does NOT erase the full chip
- writes bootloader / partition table / OTA data / application as defined by Arduino-ESP32 3.3.12
- hardware/runtime acceptance remain NOT PASS after flashing until physical tests are completed

Current status:
- final preflash: PASS
- flash runner: READY
- flash: NOT PERFORMED
- explicit user approval required before execution

## First approved flash attempt stopped safely during backup — 2026-11-07

Explicit flash approval had been given by the user.

Attempt evidence:
- branch HEAD: `5d265bb46fb88316b7d30fb7eb645129e5a0c047`
- port: COM5
- canonical N16R8 profile lock: PASS
- device identity gate: PASS
- physical flash 16MB: PASS
- full 16MB pre-flash readback started before any write
- readback stopped around 1,069,056 / 16,777,216 bytes with `Packet content transfer stopped`
- runner exited with `ERROR=FULL_FLASH_BACKUP_FAILED`
- flash write stage was never reached
- therefore no bootloader, partition, OTA data, app, erase-all, or NVS write occurred in this attempt

Root cause class:
- serial/USB readback transfer interruption during one long 16MB esptool stub read
- not a source/profile/device identity failure

Correction:
- commit `2c595f8d49c615e65e1038fb8021db1397a9428d`
- backup now reads 32 chunks x 512KB at explicit 115200 baud
- each chunk retries up to 3 times
- every chunk must be exactly 524,288 bytes
- all 32 chunks are combined and the final backup must be exactly 16,777,216 bytes
- SHA256 is recorded before build/upload proceeds
- any backup failure still exits before flash write

Approval status:
- original explicit user approval remains for the same R8.14 N16R8 flash operation
- retry is allowed only with the corrected runner; scope is unchanged

## Chunk #2 stub-read fallback correction — 2026-11-07

Second approved flash attempt again stopped before any write during the pre-flash backup stage.

Evidence:
- chunked backup mode: 32 x 512KB at 115200 baud
- chunks 0 and 1: PASS
- chunk 2 (offset 0x100000): default stub read failed three times
- each failure stopped around address 0x105000 with `Packet content transfer stopped`
- chunks 3 through 31: PASS
- runner ended with `ERROR=CHUNKED_FLASH_BACKUP_FAILED`
- no flash write stage was reached
- therefore bootloader / partition / OTA data / app / erase-all / NVS remained untouched

Interpretation:
- failure is localized to the stub-based read path for chunk 2 rather than a general USB/flash failure
- all later 512KB regions were readable using the same link and baud

Correction:
- commit `fa4d3f9916639989325a2fe35872f266ca44791a`
- normal backup path still tries the esptool stub up to 3 times per chunk
- any chunk that still fails automatically falls back to ESP32-S3 ROM bootloader read using `--no-stub`
- no-stub fallback explicitly supplies 16MB flash size and 115200 baud
- no-stub fallback retries up to 3 times and still requires exactly 524,288 bytes
- any unresolved chunk failure still exits before flash write

Approval status:
- the user's explicit R8.14 N16R8 flash approval remains in scope
- only backup transport strategy changed; firmware/profile/target/write scope did not change

## R8.14 N16R8 flash PASS — 2026-11-07

Explicitly approved flash operation completed successfully.

Flash evidence:
- target port: COM5
- canonical FQBN: `esp32:esp32:esp32s3:FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi`
- flash status: PASS
- application SHA256: `306e3b4be82b9cbb794e76975c968ca146689ee63192e5fa81383473f8177f9f`
- pre-flash full 16MB backup SHA256: `a3e74d26160e9b738cdb7d015edf1244dccb3143f90c0f12ad62b8dfb6f64802`
- backup directory: `D:\FarmCart\backups\farmcart_r814_preflash_COM5_20261107_220605` (normalized from runner path)
- erase-all: NO
- full backup completed before flash write
- canonical board/profile/device gates passed before flash

Important post-flash source behavior:
- `DEVELOPMENT_CLEAR_WIFI_ON_FIRMWARE_CHANGE = true`
- `WIFI_PROVISIONING_VERSION = 81202`
- if persisted `wifiBuild` differs from 81202, first boot clears Wi-Fi credentials only; this does not imply controller failure
- WiFiTransport always starts `SmartFarm-*` AP in AP+STA mode
- relay initialization starts hardware outputs safe OFF before any later persisted-state reconciliation

Gate status after write:
- FLASH: PASS
- HARDWARE ACCEPTANCE: NOT YET PASS
- RUNTIME ACCEPTANCE: NOT YET PASS
- RELAY/LOAD POWER: MUST REMAIN DISCONNECTED until post-flash smoke and relay-state inspection pass
- MERGE MAIN: BLOCKED

## Post-flash smoke gate prepared — 2026-11-07

Prepared read-only post-flash smoke tooling:
- `tools/windows/RUN_FARMCART_R814_POSTFLASH_SERIAL_CAPTURE_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_POSTFLASH_SMOKE_READONLY.cmd`

Purpose:
- confirm ESP32-S3 still responds on the selected COM port
- trigger a controlled reset via read-only chip probe
- capture boot/runtime serial output when available
- look for firmware version, Device ID, AP start and RTC status
- passively scan Windows Wi-Fi networks for `SmartFarm-*` AP
- perform no relay command, Wi-Fi configuration write, HTTP write, flash write or NVS write

Safety:
- relay/pump/load power must remain disconnected during this gate
- hardware/runtime acceptance still remain NOT PASS until post-flash evidence is reviewed

## Post-flash smoke partial PASS and AP HTTP gate — 2026-11-07

Observed post-flash smoke summary:
- DEVICE_PRESENCE=PASS
- SMARTFARM_AP_SCAN=PASS
- FW_RUNTIME=NOT_SEEN
- AP_SERIAL=NOT_SEEN
- relay load/pump power remained disconnected
- no relay command, Wi-Fi config write, HTTP write, flash write or NVS write occurred

Interpretation:
- controller is alive after flash and Windows can see the SmartFarm AP
- missing firmware/AP serial strings are not classified as runtime failure because the first smoke runner reset the controller before opening the serial capture and the boot banner is emitted only during setup
- source confirms WiFiTransport always starts AP+STA and exposes read-only GET endpoints `/api/device`, `/api/state`, `/api/relays`, `/api/v3/clock`
- source also confirms manual persisted relay state may be restored after initial safe-OFF initialization; actual relay state must therefore be read before reconnecting any load

Prepared read-only AP HTTP runtime gate:
- `tools/windows/RUN_FARMCART_R814_AP_HTTP_RUNTIME_SMOKE_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_AP_HTTP_RUNTIME_SMOKE_READONLY.cmd`
- requires Windows to be connected to the visible `SmartFarm-*` AP
- AP password from firmware configuration: `smartfarm123`
- expected AP IP: `192.168.4.1`
- GET-only verification of firmware version, hardware profile, device ID, relay count, all relay states, provisioning/station status and RTC status
- relay/load power must remain disconnected until all 8 relay states are confirmed OFF

Gate status:
- FLASH=PASS
- DEVICE_PRESENCE=PASS
- AP_VISIBILITY=PASS
- AP_HTTP_RUNTIME=NOT_YET_TESTED
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- RUNTIME_ACCEPTANCE=NOT_YET_PASS
- MERGE_MAIN=BLOCKED

## AP HTTP runtime smoke PASS — 2026-11-07

Observed through GET-only AP HTTP smoke while Windows was connected to the controller AP:
- branch HEAD at test: `88bf5abb581e699c91485539917fb18248554a46`
- controller AP: `SmartFarm-9FC114` / `192.168.4.1`
- firmware runtime: `0.8.0-5f-r8.14-stability-1` PASS
- hardware profile: `smart_farm_8ch_v1` PASS
- device ID: `sf-64B9509FC114` PASS
- relay count: 8 PASS
- all 8 relay runtime states: OFF PASS
- all manual overrides: inactive
- emergency latched: false
- provisioning configured: false
- station connected: false
- AP HTTP smoke: PASS
- sensors currently report not_installed / null metrics

RTC evidence:
- `/api/v3/clock` reachable
- available=false
- valid=false
- quality=unavailable
- errorCode=device_not_found
- I2C address=104 / 0x68
- SDA=GPIO8
- SCL=GPIO9
- readFailures observed: 736
- RTC acceptance is blocked until DS3231 is physically detected

Safety decision:
- relay software state is verified OFF for all 8 channels
- relay module/control wiring may be reconnected for no-load physical testing
- pump / actuator / 12V load power must remain disconnected until relay hardware behavior is verified
- Wi-Fi station credentials are expected to be absent because the firmware-change provisioning gate cleared Wi-Fi only

Gate status:
- FLASH=PASS
- DEVICE_PRESENCE=PASS
- AP_VISIBILITY=PASS
- AP_HTTP_RUNTIME=PASS
- RELAY_SAFE_STATE=PASS
- RTC_PHYSICAL=BLOCKED_DEVICE_NOT_FOUND
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- RUNTIME_ACCEPTANCE=NOT_YET_PASS
- MERGE_MAIN=BLOCKED

## AP HTTP transient timeout hardening — 2026-11-08

Observed during AP HTTP smoke:
- Windows remained connected to `SmartFarm-*` AP
- browser root `http://192.168.4.1` remained reachable
- smoke script timed out specifically on `GET /api/relays`
- because the root page was still served, this was not classified as controller/AP loss
- the run did not reach `/api/v3/clock`; no RTC conclusion is valid from this failed attempt

Tooling correction:
- commit `f3187247d4d3ceb678a16f65781171932015c315`
- each GET now uses `-DisableKeepAlive`
- each endpoint retries up to 3 times
- 350 ms spacing after success and 700 ms backoff after a failed attempt
- still GET-only; no relay/Wi-Fi/NVS/flash write

Gate status remains:
- FLASH=PASS
- prior AP_HTTP_RUNTIME=PASS evidence remains valid
- new RTC state after physical connection: NOT YET VERIFIED
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- RUNTIME_ACCEPTANCE=NOT_YET_PASS

## DS3231 physical detection and lost-power fail-safe PASS — 2026-11-08

Runtime evidence from GET-only AP HTTP smoke after physically connecting DS3231:
- all four GET endpoints passed on first try: `/api/device`, `/api/state`, `/api/relays`, `/api/v3/clock`
- firmware runtime: `0.8.0-5f-r8.14-stability-1` PASS
- hardware profile: `smart_farm_8ch_v1` PASS
- all 8 relays remained OFF PASS
- DS3231 detection: PASS
  - available=true
  - source=ds3231
  - chipTemperatureC=28.75
  - readFailures=0
  - I2C address=0x68
  - SDA=GPIO8 / SCL=GPIO9
- RTC state: valid=false, quality=lost_power, lostPower=true, synchronized=false
- RTC retained/default time observed as 2000-01-01, so this is correctly rejected as valid schedule time

Acceptance interpretation:
- RTC physical transport/detection is now PASS
- `lost_power` fail-safe behavior is PASS: clock remains invalid until explicit time synchronization
- no RTC time write has been performed yet
- next mutation, if approved, is explicit POST `/api/v3/clock/sync` with local time payload
- pump/actuator load power remains disconnected until relay hardware acceptance

## RTC sync approved and runner prepared — 2026-11-08

User explicitly approved RTC synchronization.

Prepared tooling:
- `tools/windows/SYNC_FARMCART_R814_RTC_APPROVAL_GATED.ps1`
- `tools/windows/SYNC_FARMCART_R814_RTC_APPROVAL_GATED.cmd`
- runner approval token: `SYNC_RTC_R814`

Mutation scope:
- writes DS3231 date/time only through POST `/api/v3/clock/sync`
- flash write: NO
- NVS write: NO
- relay command: NO
- Wi-Fi configuration write: NO
- merge main: NO

Safety/validation:
- confirms candidate branch and runtime source lock
- requires controller firmware/hardware profile match
- requires DS3231 available before write
- requires Windows local UTC offset exactly +07:00
- day-of-week convention matches Flutter `DateTime.weekday`: Monday=1 ... Sunday=7
- performs one POST only; no automatic POST retry after uncertain response
- verifies RTC afterward by GET
- PASS requires available=true, source=ds3231, valid=true, lostPower=false, synchronized=true, readFailures=0, errorCode=none and RTC time within 5 seconds of Windows local time

Current status:
- RTC_SYNC_APPROVAL=GRANTED
- RTC_SYNC_EXECUTION=NOT_YET_PERFORMED
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- RUNTIME_ACCEPTANCE=NOT_YET_PASS

## RTC sync semantic PASS; accuracy verifier prepared — 2026-11-08

Observed approved RTC sync execution:
- source lock and approval gate: PASS
- Windows local time source at sync: 2026-11-08 08:32:57 +07:00
- sync payload used dayOfWeek=7 (Sunday), matching Flutter Monday=1..Sunday=7 convention
- POST `/api/v3/clock/sync` response timed out; no automatic POST retry was performed
- subsequent GET `/api/v3/clock` proved the mutation succeeded:
  - available=true
  - valid=true
  - source=ds3231
  - quality=synchronized
  - lostPower=false
  - synchronized=true
  - readFailures=0
  - errorCode=none
  - RTC time returned 2026-11-08 08:33:01

Interpretation:
- RTC sync semantic result = PASS
- the runner's final `RTC_SYNC=FAIL` was caused only by its <=5 s PC-delta check being evaluated after an 8 s POST timeout + verification delay
- the 11.1 s delta is not accepted as an accuracy result because that measurement method included request timeout latency
- no second POST/resync has been performed

Prepared read-only verifier:
- `tools/windows/RUN_FARMCART_R814_RTC_VERIFY_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_RTC_VERIFY_READONLY.cmd`
- samples RTC 5 times using GET only
- compares each RTC sample against the midpoint of the HTTP request, not against a delayed post-timeout timestamp
- verifies available/valid/source/lostPower/readFailures/errorCode, <=5 s absolute time delta and monotonic RTC progression

Gate status:
- RTC_SYNC_SEMANTIC=PASS
- RTC_ACCURACY_CONTINUITY=NOT_YET_VERIFIED
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- RUNTIME_ACCEPTANCE=NOT_YET_PASS

## RTC retention failure after successful sync — 2026-11-08

Read-only RTC verifier after the earlier successful sync produced a real retention failure:
- five GET-only samples were collected
- RTC remained physically available and I2C transport succeeded
- every sample returned `valid=false`, `quality=lost_power`, `lostPower=true`, `readFailures=0`, `errorCode=lost_power`
- date/time had reverted to 2000-01-01 and continued advancing from that reset value
- RTC remained monotonic while currently powered
- therefore the failure is not an I2C transport miss and not HTTP cache

Source confirmation:
- `GET /api/v3/clock` calls `ClockService::update()` before returning the snapshot, so each request reads the DS3231 again
- `ClockService::setLocalTime()` had previously cleared OSF/lost-power and the subsequent GET proved `valid=true`, `quality=synchronized`, `lostPower=false`, `readFailures=0`, `errorCode=none`
- later reappearance of `lostPower=true` together with reset date/time indicates the DS3231 lost effective timekeeping power after that successful sync
- `synchronized` is a RAM flag set by `setLocalTime()` and is not cleared by a later lost-power read; therefore `synchronized=true + lostPower=true` is a diagnostic-state inconsistency, not proof that RTC is still synchronized

Likely physical causes to verify before another RTC write:
- RTC backup cell absent / depleted / ineffective
- RTC VCC or GND intermittent / disconnected
- module or connector contact issue
- if the ESP32/RTC supply was intentionally power-cycled, loss of time is expected when backup power is not functioning

Do NOT patch firmware or resync repeatedly yet.
Next gate:
1. verify DS3231 power wiring and backup-power condition
2. after physical correction, perform one approved RTC sync
3. verify valid synchronized time
4. intentionally remove/reapply controller VCC only after confirming the RTC module's backup-power design is safe and functional
5. verify RTC retained time and `lostPower=false` after reboot

Gate status:
- RTC_PHYSICAL_I2C=PASS
- RTC_SYNC_SEMANTIC=PASS previously
- RTC_RETENTION=FAIL
- RTC_ACCURACY=BLOCKED_BY_RETENTION_FAILURE
- HARDWARE_ACCEPTANCE=BLOCKED
- RUNTIME_ACCEPTANCE=BLOCKED
- MERGE_MAIN=BLOCKED

## RTC retention deferred by user — 2026-11-08

User chose to defer RTC retention investigation for now.

Current RTC interpretation:
- DS3231 physical I2C detection: PASS
- explicit sync write: PASS semantically
- retention after power interruption: FAIL
- suspected physical cause: backup cell depleted / ineffective (not yet verified)
- no further RTC write/resync will be performed until the hardware/battery is revisited

Scope impact:
- RTC-dependent schedule/clock acceptance remains BLOCKED/DEFERRED
- non-RTC acceptance may continue: AP/HTTP reachability, relay hardware no-load checks, manual relay ON/OFF, rapid command behavior, emergency-stop behavior, device edit/delete safe-off where they do not require valid RTC
- overall R8.14 hardware/runtime acceptance and main merge remain blocked until the deferred RTC gate is resolved or explicitly waived later

## Relay no-load precondition recheck PASS — 2026-11-08

Read-only AP HTTP smoke was rerun before physical relay testing.

Observed:
- `/api/device`: first attempt timed out, second attempt PASS
- `/api/state`: first attempt timed out, second attempt PASS
- `/api/relays`: first attempt PASS
- `/api/v3/clock`: first attempt PASS
- firmware runtime: PASS
- hardware profile runtime: PASS
- relay count: 8 PASS
- all relay states CH1..CH8: OFF
- all relay overrides: inactive
- emergency latched: false
- AP HTTP smoke: PASS

RTC remains deferred:
- DS3231 detected
- valid=false
- quality=lost_power
- readFailures=0
- retention issue still suspected to be backup-battery/power related

Safety decision:
- software relay safe-state is PASS
- no-load physical relay acceptance may proceed
- pump / actuator / external load power must remain disconnected until no-load relay switching and emergency-stop checks pass

## Relay no-load test approved and runner prepared — 2026-11-08

User explicitly approved relay hardware testing with no external load connected.

Prepared tooling:
- `tools/windows/TEST_FARMCART_R814_RELAYS_NOLOAD_APPROVAL_GATED.ps1`
- `tools/windows/TEST_FARMCART_R814_RELAYS_NOLOAD_APPROVAL_GATED.cmd`
- approval token: `TEST_RELAYS_NOLOAD_R814`

Test scope:
- preflight requires all 8 relays OFF and GPIO map exactly CH1..CH8 = 4,5,6,7,15,16,17,18
- CH1 through CH8 are tested sequentially
- each channel: POST ON -> GET verify ON -> short hold -> POST OFF -> GET verify OFF
- final GET requires all relays OFF and all manual overrides cleared
- no pump/valve/actuator/load power may be connected
- no flash, RTC write, Wi-Fi config write, or main merge

Fail-safe:
- if any channel fails verification, runner attempts Emergency Stop
- on failure Emergency Stop remains latched for review; do not release automatically

Physical acceptance still requires user observation that each matching relay LED/click occurred in CH1..CH8 order.

Current status:
- RELAY_NOLOAD_APPROVAL=GRANTED
- RELAY_NOLOAD_EXECUTION=NOT_YET_PERFORMED
- HARDWARE_ACCEPTANCE=NOT_YET_PASS

## Relay no-load CH2 false-fail diagnosis and harness fix — 2026-11-08

Observed first relay no-load execution:
- CH1 GPIO4: ON API PASS, OFF API PASS
- CH2 GPIO5: POST response timed out, subsequent GET found relay OFF
- runner then triggered Emergency Stop as designed
- emergency latch became true and all relay channels were confirmed OFF

Root cause in test harness:
- HTTP POST timeout = 6 seconds
- CH ON manual override window = 4 seconds
- if the POST was accepted by ESP32 but the HTTP response timed out, the 4-second override could expire before GET verification
- therefore CH2 OFF after the timeout is not valid evidence that CH2/GPIO5 failed to switch

Fix:
- commit `f859785ac903d7124d9315d4a4a2e401a1aea1de`
- CH ON verification window increased to 45 seconds
- still explicitly commands OFF immediately after ON verification
- if Emergency Stop is latched from the previous failed attempt, approved no-load retest now releases it, re-reads `/api/relays`, and requires all channels OFF before continuing
- failure path still attempts Emergency Stop and leaves it latched for review

Current interpretation:
- CH1 software/API switching: PASS
- CH1 physical LED/click: user observation still required
- CH2 software/API switching: NOT YET VERIFIED; previous FAIL was invalidated by harness timing defect
- CH3..CH8: NOT YET TESTED
- all relays safe OFF after fail-safe: PASS
- relay hardware overall acceptance: NOT YET PASS

## Relay CH3 HTTP loss diagnosis + NVS metadata correction — 2026-11-08

Second no-load relay execution:
- CH1 GPIO4: ON PASS, OFF PASS
- CH2 GPIO5: ON PASS, OFF PASS
- CH3 GPIO6: POST response timed out; immediate GET showed CH3 still OFF
- because ON override window was already 45 seconds, this is evidence the POST command was not applied, not evidence of override expiry
- fail-safe Emergency Stop POST also timed out; subsequent GET showed all relays OFF and emergencyLatched=false
- therefore the emergency-stop request was also likely not applied; the safe OFF result came from relay state, not a latched emergency stop

Interpretation:
- CH1 software/API switching PASS
- CH2 software/API switching PASS
- CH3 hardware/software switching NOT YET VERIFIED; failure attributed to transient HTTP POST delivery/processing
- CH4..CH8 NOT YET TESTED
- all relays OFF after failed run PASS

Important metadata correction:
- `RelayManager::set()` persists relay state to Preferences/NVS when restore-after-power-loss is enabled
- Emergency Stop/Release also writes the emergency latch to Preferences/NVS
- previous runner labels claiming `NVS_WRITE=NO` were incorrect
- relay test approval did cause relay-state persistence writes and one Emergency Stop/Release sequence in earlier runs
- final verified relay state after each completed/failed run was OFF on all channels

Tooling correction:
- `959b26d28fc76e2d932f4b82fbefba9b14edb631`: state-aware idempotent relay command retry, no automatic Emergency Stop/Release, fail-safe commands all channels OFF
- `dba3cba70345bfbed26463f19a2194ee8fbacea7`: wrapper now declares `NVS_WRITE=YES_RELAY_STATE_PERSISTENCE`
- a future run must not auto-release an emergency latch; if latch is present, explicit NVS-affecting release approval is required

Gate status:
- RELAY_CH1_API=PASS
- RELAY_CH2_API=PASS
- RELAY_CH3_API=NOT_YET_VERIFIED
- RELAY_CH4_TO_CH8=NOT_YET_TESTED
- RELAY_FINAL_SAFE_OFF=PASS
- RELAY_NOLOAD_OVERALL=NOT_YET_PASS
- HARDWARE_ACCEPTANCE=NOT_YET_PASS

## NVS relay-state write approval granted — 2026-11-08

User explicitly approved continuing the relay no-load test with the firmware's real NVS side effect:
- relay ON/OFF commands may persist relay state through `RelayManager::set()`
- final safe target remains all relays OFF
- automatic Emergency Stop/Release remains disabled in the test harness to avoid emergency-latch Preferences writes

Approved scope:
- CH1..CH8 no-load relay switching only
- state-aware retry after HTTP POST uncertainty
- GET verification after each desired state
- fail-safe = command all relay channels OFF and verify
- pump / valve / actuator / external load power remains disconnected
- FLASH_WRITE=NO
- RTC_WRITE=NO
- WIFI_CONFIG_WRITE=NO
- MERGE_MAIN=NO

Approval status:
- NVS_RELAY_STATE_WRITE=APPROVED
- RELAY_NOLOAD_RETEST=APPROVED
- EXECUTION=NOT_YET_PERFORMED

## Relay no-load API sequence PASS — 2026-11-08

Approved NVS-aware relay no-load retest completed successfully at API/state level.

Observed sequence:
- preflight: all relays OFF PASS
- GPIO map PASS: CH1..CH8 = 4,5,6,7,15,16,17,18
- CH1 ON/OFF PASS
- CH2 ON/OFF PASS
- CH3 ON/OFF PASS
- CH4 ON/OFF PASS
- CH5 ON/OFF PASS after one state-aware retry on ON
- CH6 ON/OFF PASS
- CH7 ON/OFF PASS
- CH8 ON PASS after two state-aware retries; OFF PASS after one retry

Final state:
- `RELAY_NOLOAD_API_SEQUENCE=PASS`
- `ALL_RELAYS_OFF_FINAL=PASS`
- `ALL_OVERRIDES_CLEARED_FINAL=PASS`
- `FINAL_ON_CHANNEL_COUNT=0`
- `FINAL_ACTIVE_OVERRIDE_COUNT=0`
- `FINAL_EMERGENCY_LATCHED=False`
- NVS relay-state persistence was explicitly approved for this run

Important remaining evidence:
- physical LED/click observation is still required from the user for CH1..CH8 in order
- therefore relay no-load software/API gate = PASS
- physical relay hardware gate = PENDING USER OBSERVATION

Network observation:
- intermittent HTTP GET/POST timeouts still occurred
- state-aware retry recovered all commands and final state safely
- this remains a runtime transport-quality issue to investigate separately before load/pump acceptance

Current status:
- RELAY_NOLOAD_API=PASS
- RELAY_NOLOAD_PHYSICAL=PENDING_USER_CONFIRMATION
- RELAY_FINAL_SAFE_OFF=PASS
- HARDWARE_ACCEPTANCE=NOT_YET_PASS
- PUMP_LOAD_POWER=KEEP_DISCONNECTED

## Relay no-load physical hardware PASS — 2026-11-08

User physically confirmed that the relay board LED/click matched CH1 through CH8 in the expected order during the completed no-load test.

Evidence combined:
- API/state ON/OFF verification: PASS for CH1..CH8
- physical channel correspondence: PASS for CH1..CH8
- GPIO mapping verified: CH1..CH8 = 4,5,6,7,15,16,17,18
- final relay state: all OFF
- final active manual overrides: 0
- final emergency latch: false
- external pump/valve/actuator/load power was not connected for this gate

Gate result:
- RELAY_NOLOAD_API=PASS
- RELAY_NOLOAD_PHYSICAL=PASS
- RELAY_NOLOAD_HARDWARE=PASS
- MANUAL_RELAY_ON_OFF_REGRESSION=PASS

Remaining blockers before load acceptance:
- intermittent AP HTTP GET/POST timeouts remain a transport-quality issue
- RTC retention remains deferred pending backup-battery/power investigation
- rapid-command latest-state regression still not tested
- load/pump power must remain disconnected until the next approved gate

## AP HTTP transport stability diagnostic prepared — 2026-11-08

Prepared read-only transport diagnostic:
- `tools/windows/RUN_FARMCART_R814_AP_HTTP_TRANSPORT_STABILITY_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_AP_HTTP_TRANSPORT_STABILITY_READONLY.cmd`
- 12 cycles x 5 endpoints = 60 raw GET requests
- endpoints: `/`, `/api/device`, `/api/state`, `/api/relays`, `/api/v3/clock`
- no hidden retry inside the measurement loop; each request is counted as PASS or FAIL
- per-endpoint pass/fail counts and RTT min/avg/max are reported
- HTTP keep-alive disabled per request to reduce client connection-reuse ambiguity
- read-only: no relay, RTC, Wi-Fi, NVS or flash writes

Purpose:
- determine whether intermittent timeouts are distributed across the whole AP/WebServer transport or concentrated in a specific handler
- no firmware patch should be made until this pattern is measured

Current gate:
- RELAY_NOLOAD_HARDWARE=PASS
- AP_HTTP_TRANSPORT_STABILITY=NOT_YET_TESTED
- PUMP_LOAD_POWER=KEEP_DISCONNECTED

## AP HTTP transport stability FAIL; link-vs-HTTP diagnostic prepared — 2026-11-08

Read-only transport stability result:
- 12 cycles x 5 endpoints = 60 GET requests
- total PASS=38, FAIL=22, overall pass rate=63.3%
- `/` root: 8/12 PASS (66.7%)
- `/api/device`: 6/12 PASS (50.0%)
- `/api/state`: 9/12 PASS (75.0%)
- `/api/relays`: 5/12 PASS (41.7%)
- `/api/v3/clock`: 10/12 PASS (83.3%)
- successful requests also showed very high RTT outliers into multi-second range
- failures are distributed across the root and all handlers, so evidence does not support an endpoint-specific handler defect

Source review before patching:
- `WiFiTransport::poll()` services `_server.handleClient()` each loop
- station reconnect path is not active while station SSID is empty
- `Protocol::poll()` is non-blocking over available serial bytes
- `StateManager` sensor sampling cadence is 3 seconds; SHT31 conversion delay is 16 ms
- `ClockService::update()` is throttled to 500 ms
- no single reviewed handler explains 3–9 second latency

Interpretation:
- AP_HTTP_TRANSPORT_STABILITY=FAIL
- current suspect class: AP/RF link instability OR WebServer/main-loop service starvation
- do not patch firmware until link-layer evidence separates these classes

Prepared diagnostic:
- `tools/windows/RUN_FARMCART_R814_AP_LINK_VS_HTTP_DIAGNOSTIC_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_AP_LINK_VS_HTTP_DIAGNOSTIC_READONLY.cmd`
- captures WLAN interface/link details
- 30 ICMP ping checks to 192.168.4.1
- 20 direct `curl.exe --noproxy *` root HTTP checks with connect/TTFB/total timing
- read-only; no ESP/NVS/relay/RTC/Wi-Fi/flash writes

Decision rule:
- ping loss => AP/RF/client link issue first
- ping stable but curl HTTP loss => ESP32 WebServer/main-loop issue
- both stable => compare PowerShell HTTP-client behavior before firmware changes

Load/pump power remains disconnected.

## AP/RF link instability confirmed; Windows WLAN/RF survey prepared — 2026-11-08

AP link-vs-HTTP diagnostic result:
- Windows adapter: Realtek RTL8188EU 802.11n USB 2.0
- connected to `SmartFarm-9FC114`, channel 1, reported signal 100%
- ping: 14/30 PASS, 16/30 FAIL
- curl root: 4/20 PASS, 16/20 FAIL
- many curl failures were TCP connection timeouts before HTTP response
- classification: `AP_OR_RF_LINK_UNSTABLE`

Interpretation:
- failure exists below the HTTP handler layer; ICMP itself is unreliable
- do not patch individual WebServer routes yet
- current candidate classes: ESP32 SoftAP RF/channel behavior, local 2.4 GHz interference, Windows RTL8188EU driver/power-management/client compatibility

Source context:
- firmware uses `WiFi.mode(WIFI_AP_STA)`
- Wi-Fi sleep is disabled with `WiFi.setSleep(false)`
- `WiFi.softAP(ssid,password)` does not explicitly set a channel; runtime currently shows channel 1

Prepared read-only Windows/RF survey:
- `tools/windows/RUN_FARMCART_R814_WINDOWS_WLAN_RF_SURVEY_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_WINDOWS_WLAN_RF_SURVEY_READONLY.cmd`
- captures WLAN driver details, adapter power-management, advanced properties, surrounding BSSIDs/channels, ARP/route and a short ping recheck
- no ESP/NVS/relay/RTC/Wi-Fi/flash writes

Decision after survey:
- if channel 1 is congested, test a fixed cleaner SoftAP channel in a candidate firmware only after approval
- if RTL8188EU power/driver settings look suspicious, A/B test another client/adapter before firmware changes
- pump/load remains disconnected

## Windows WLAN/RF survey confirms severe link loss — 2026-11-08

Read-only Windows WLAN/RF survey:
- adapter: Realtek RTL8188EU Wireless LAN 802.11n USB 2.0
- driver version: 1030.52.1216.2025
- connected to SmartFarm-9FC114
- channel 1
- signal reported 100%
- link speed 150 Mbps
- only one visible WLAN in scan: SmartFarm-9FC114
- advanced properties exposed: Bandwidth 20_40MHz, QoS enabled, Wireless Mode 802.11b/g/n
- power-management details were not returned by the cmdlet

Ping recheck:
- sent 20, received 11, lost 9 = 45% packet loss
- RTT min 10 ms, max 572 ms, avg 264 ms

Interpretation:
- channel congestion is not supported by current scan evidence
- signal strength alone is not the issue (100% reported)
- severe packet loss exists below HTTP
- remaining main candidate classes: ESP32 SoftAP/power integrity vs RTL8188EU client compatibility/driver behavior

Next isolation step:
- power down ESP32
- physically disconnect relay board/control/power wiring from ESP32
- power ESP32 controller alone
- reconnect Windows to SmartFarm AP
- rerun the existing AP link-vs-HTTP diagnostic read-only
- compare packet loss and HTTP success against the relay-connected baseline

Safety:
- external pump/valve/load power remains disconnected
- no firmware patch yet

## Relay-disconnected A/B still shows severe AP link loss — 2026-11-08

Relay-isolation A/B was run with ESP32 controller alone and relay board physically disconnected.

Baseline with relay connected:
- ping PASS 14/30, FAIL 16/30
- HTTP root PASS 4/20, FAIL 16/20

ESP32-alone result:
- ping PASS 18/30, FAIL 12/30
- HTTP root PASS 6/20, FAIL 14/20
- ping wall-time max 474.5 ms
- successful HTTP total-time max 857.4 ms
- classification remained `AP_OR_RF_LINK_UNSTABLE`

Interpretation:
- disconnecting relay board produced only a small improvement and did not remove severe loss
- relay board/power interaction is therefore not supported as the primary root cause
- remaining main candidate classes: Windows Realtek RTL8188EU client/driver compatibility vs ESP32 SoftAP behavior
- no endpoint-specific or relay-specific firmware patch is justified yet

Next preferred isolation:
- A/B test the same SmartFarm AP from a second Wi-Fi client/device before changing firmware
- if second client is stable, focus on RTL8188EU/Windows adapter
- if second client is similarly unstable, focus on ESP32 SoftAP firmware/radio configuration

Pump/load power remains disconnected.

## Cross-client A/B: mobile stable, RTL8188EU path implicated — 2026-11-08

Cross-client A/B evidence from user:
- ESP32 controller remained standalone (relay/load still disconnected)
- Android phone connected directly to `SmartFarm-9FC114`
- browser `/api/device` remained responsive during repeated refreshes
- FarmCart app Controller/Advanced pages remained connected during repeated refreshes
- app reported consecutive failures = 0
- app showed controller firmware `0.8.0-5f-r8.14-stability-1` and IP `192.168.4.1`
- observed controller response time in app approximately 1042 ms
- `/api/device` showed `wifiClientCount=2` during the observation

Interpretation:
- severe loss previously reproduced specifically through Windows Realtek RTL8188EU path
- same ESP32 SoftAP was qualitatively stable from Android phone
- evidence now supports `WINDOWS_RTL8188EU_CLIENT_PATH_UNSTABLE` rather than a global ESP32 SoftAP failure
- do not patch ESP32 SoftAP channel/WebServer based on the Windows-only failure

Important observation from app diagnostics screenshot:
- app log displayed `RTC invalid (lost_power); syncing from phone`
- app log also displayed two `POST /api/relay CH=3 ON=false` entries
- these actions must be treated separately from the read-only browser A/B; they may mutate RTC and relay-state persistence depending on the actual request path
- do not infer a hardware relay defect from these log entries

Current transport classification:
- MOBILE_DIRECT_AP_QUALITATIVE=PASS
- WINDOWS_RTL8188EU_AP_LINK=FAIL
- ESP32_GLOBAL_AP_FAILURE=NOT_SUPPORTED_BY_CURRENT_EVIDENCE
- HTTP_ENDPOINT_HANDLER_DEFECT=NOT_SUPPORTED_BY_CURRENT_EVIDENCE

Next:
- treat RTL8188EU/Windows as a host-side debug compatibility issue
- continue product acceptance primarily on the mobile app path
- separately verify/contain automatic RTC sync and unexpected relay-OFF requests before load/pump testing
- pump/load remains disconnected

## Mobile direct-link stable; scan semantics + stale APK identified — 2026-11-08

User clarified the Android controller connection was restored from previously saved controller data / URL rather than rediscovered by scan.

Observed mobile evidence:
- browser access to `http://192.168.4.1/api/device` remained stable during repeated refreshes
- installed FarmCart app also remained connected via saved controller data
- this still supports stable direct-IP AP transport from Android, but does NOT prove controller-discovery / Wi-Fi-scan behavior

Installed app version mismatch:
- screenshot shows app `0.8.41 • 5F R8.7 UI Hardening Hotfix`
- current candidate Flutter source is version `0.8.14+137`
- current R8.14 controller source does not auto-sync an invalid RTC during connect; it logs manual sync required
- therefore screenshot log `RTC invalid (lost_power); syncing from phone` originates from stale installed APK behavior and is not evidence of current R8.14 app behavior

Wi-Fi scan semantics/source:
- Flutter `scanWifi()` calls controller endpoint `GET /api/wifi/scan`
- this endpoint scans Wi-Fi networks that the ESP32 controller could join as STA; it is not the mechanism for finding the controller AP itself
- controller reconnection from saved data uses the saved base URL/AP path
- ESP32 `handleWifiScan()` currently calls `WiFi.scanNetworks(false, true)` synchronously inside the HTTP handler
- this can stall SoftAP HTTP servicing during the scan window and must be treated as a separate scan-path defect/risk

Next verification:
- use Android browser direct to `http://192.168.4.1/api/wifi/scan` exactly once
- capture returned JSON / behavior and avoid repeated scan refreshes
- keep relay/load disconnected
- after scan-path evidence, validate with current R8.14 APK before final mobile-app acceptance

## Reset recovers AP; Wi-Fi scan returns empty — 2026-11-08

User performed a short reset/restart of the ESP32 controller.

Observed after reset:
- SmartFarm AP returned
- Android browser direct `http://192.168.4.1/api/device` responded successfully
- direct `http://192.168.4.1/api/wifi/scan` responded successfully at HTTP/API level but returned `{"ok":true,"networks":[]}`

Interpretation:
- reset recovers SoftAP availability after prior disappearance
- Wi-Fi scan endpoint is alive but discovers zero candidate STA networks
- ESP32-S3 is 2.4 GHz-only; a 5 GHz-only home SSID would not appear
- current firmware uses synchronous `WiFi.scanNetworks(false, true)` inside the HTTP handler, which can temporarily block AP HTTP servicing and is a scan-path robustness concern

Next read-only band isolation:
- use Windows Realtek RTL8188EU (2.4 GHz b/g/n-only) to scan while disconnected from SmartFarm
- if `Ratthaphum` is visible there, it proves a 2.4 GHz BSSID exists and ESP32 zero-result scan is a firmware/radio-path defect
- if `Ratthaphum` is absent there, likely 5 GHz-only from the current location/config and ESP32 zero-result is expected

No firmware patch/flash yet.

## 2.4 GHz confirmed; async Wi-Fi scan fix prepared — 2026-11-08

User confirmed `Ratthaphum` is a 2.4 GHz network.

Root cause in current scan handler:
- current firmware called synchronous `WiFi.scanNetworks(false, true)` inside the HTTP request handler
- Arduino-ESP32 scan API may return negative status values such as `WIFI_SCAN_RUNNING` or `WIFI_SCAN_FAILED`
- previous handler did not distinguish negative scan status from a legitimate zero-network result and could incorrectly reply `ok=true, networks=[]`
- synchronous scanning can also block SoftAP HTTP servicing for the scan duration

Candidate source fix:
- firmware commit `7d78acd51977e2835f68768ad211638840db367d`
- `GET /api/wifi/scan` now starts an asynchronous scan when no result is ready
- response exposes `scanning` / `scanState`
- true scan-start failure returns HTTP 503 `wifi_scan_failed`
- completed scan returns `count`, SSID, RSSI, security and channel
- scan result storage is deleted only after completed results are serialized

Flutter compatibility fix:
- app commit `30ab9bbadcc601b4978d416efb985af84ba9145e`
- `scanWifi()` polls asynchronous scan state up to 30 times at 350 ms intervals
- legacy firmware responses without `scanning=true` still parse normally
- timeout is surfaced as `wifi_scan_timeout`

Verification status:
- Smart Farm CI run #13 / ID 42441352416 started on head `30ab9bba...`
- Flutter analyze + test = PASS
- ESP32 N16R8 compile = still in progress at last check
- Android demo APK = still in progress at last check
- FLASH=NOT_PERFORMED
- MAIN=UNTOUCHED

## Scan-fix CI PASS + dedicated flash gate prepared — 2026-11-08

Smart Farm CI #13 / run ID 42441352416 completed successfully for source head `30ab9bbadcc601b4978d416efb985af84ba9145e`:
- ESP32-S3 N16R8 compile = SUCCESS
- Flutter analyze + test = SUCCESS
- Android demo APK = SUCCESS

APK artifact:
- artifact ID `13602000738`
- name `farmcart-smartgrow-r8.14-demo-apk`
- digest `sha256:4745b9e18959236596569398d160955db30f17e4f23b63133164298702d6491c`

Flash gating:
- legacy R8.14 flash runner still locks old runtime SHA and must not be used for scan-fix
- dedicated runner: `tools/windows/FLASH_FARMCART_R814_SCANFIX_N16R8_APPROVAL_GATED.cmd`
- runtime source lock: `30ab9bbadcc601b4978d416efb985af84ba9145e`
- approval token: `FLASH_R814_SCANFIX_N16R8`
- branch: `candidate/r8.14-stability-1`
- canonical N16R8 FQBN preserved
- full pre-flash backup remains enabled in the dedicated runner
- FLASH=NOT_YET_APPROVED
- MAIN=UNTOUCHED

## Scan-fix flash approval granted — 2026-11-08

User explicitly approved flashing the R8.14 Wi-Fi scan-fix candidate.

Approved flash scope:
- dedicated runner: `tools/windows/FLASH_FARMCART_R814_SCANFIX_N16R8_APPROVAL_GATED.cmd`
- approval token: `FLASH_R814_SCANFIX_N16R8`
- source lock: `30ab9bbadcc601b4978d416efb985af84ba9145e`
- branch: `candidate/r8.14-stability-1`
- target: physical ESP32-S3 N16R8 on COM5
- canonical FQBN preserved: 16MB flash / OPI PSRAM / app3M_fat9M_16MB
- full 16MB pre-flash backup required before write
- relay board / pump / actuator / external load remain disconnected
- MAIN=UNTOUCHED

Approval status:
- FLASH_R814_SCANFIX_N16R8=APPROVED
- FLASH_EXECUTION=NOT_YET_PERFORMED

## Scan-fix flash attempt blocked at stub upload; no write performed — 2026-11-08

Approved scan-fix flash attempt stopped before any backup/build/write stage.

Observed:
- branch/source/FW/profile locks PASS
- COM5 connected and chip identified as ESP32-S3 QFN56 rev0.2
- PSRAM reported 8MB
- stub flasher upload failed with pySerial `Write timeout`
- subsequent `flash-id` also failed to communicate
- runner then emitted `ERROR=FLASH_SIZE_NOT_16MB` because flash-id output was unavailable; this is not evidence of an actual flash-size mismatch

Safety interpretation:
- FLASH_WRITE=NOT_PERFORMED
- ERASE=NOT_PERFORMED
- BACKUP_STAGE=NOT_REACHED
- firmware on device remains the previous image

Next:
- run dedicated read-only ROM-loader identity gate with `--no-stub`
- if ROM chip/flash identity passes, harden scan-fix flash runner with no-stub fallback before retrying approved flash

Read-only tooling:
- `tools/windows/RUN_FARMCART_R814_SCANFIX_ROM_IDENTITY_READONLY.ps1`
- `tools/windows/RUN_FARMCART_R814_SCANFIX_ROM_IDENTITY_READONLY.cmd`

## Reused proven no-stub flash recovery method — 2026-11-08

User explicitly requested review of prior working history after the ROM identity helper failed.

Historical working method confirmed:
- previous R8.14 flash backup failure was localized to esptool stub reads
- commit `fa4d3f9916639989325a2fe35872f266ca44791a` added direct-CMD ROM fallback:
  `python -m esptool --chip esp32s3 --port %PORT% -b 115200 --no-stub read-flash --flash-size 16MB ...`
- backup mode became `32x512KB_STUB_RETRY3_THEN_NO_STUB_RETRY3_BAUD115200`
- that workflow later completed full 16MB backup and successful flash
- recorded successful flash Handoff commit: `98df4b182a4dd41563a544b9e39694c4c097a617`

Current failure explanation:
- newly created PowerShell ROM identity helper printed esptool global help instead of executing chip-id
- therefore `ROM_CHIP_ID=FAIL` was a test-runner defect, not hardware evidence
- the PowerShell wrapper method is discarded for this gate

Corrections:
- `5fd22d21b4f28d80d8cd6ccbcc13f836eb0c329e`: scan-fix flash runner identity stage now retries with direct-CMD no-stub at 115200 when stub identity/flash-id fails
- existing full-backup section already retained the proven per-chunk stub->no-stub fallback
- `31bb65d5e3d71687a9c180ce01569e4340a1b1a0`: ROM identity read-only wrapper now invokes esptool directly from CMD rather than through the faulty PowerShell function

Approval:
- original user approval `FLASH_R814_SCANFIX_N16R8` remains in scope
- only the transport/recovery strategy of the same approved operation changed
- no new firmware source, partition profile, target port, or write scope was added
- FLASH_WRITE remains not yet performed for scan-fix

## Historical flash-method correction after memory review — 2026-11-08

Memory/history review after current `--no-stub chip-id` also failed with pySerial `Write timeout`:

Confirmed prior successful FarmCart R8.14 path:
- target COM5
- esptool v5.3.1 standard connection/stub path successfully identified ESP32-S3
- flash-id successfully reported 16MB
- esptool output included hard reset via RTS
- backup strategy used 32 x 512KB chunks at 115200 with retries
- `--no-stub` was introduced as a fallback for failed flash-read chunks, not as the original initial-connect method
- final historical flash completed with full 16MB backup and `FLASH_STATUS=PASS`

Important correction:
- no retrieved historical evidence shows manual BOOT/RESET was required for the successful flash
- therefore manual BOOT should not be treated as the known prior solution

Current interpretation:
- current failure occurs before flash read/write: both stub and direct ROM no-stub attempts encounter serial `Write timeout` while connecting
- this points to current COM5/USB serial transport or port state rather than firmware source, flash size, or scan-fix code
- next step should first restore the normal USB/COM connection state that previously allowed esptool stub connection, then rerun read-only identity
- no flash write has occurred in the current scan-fix attempt

## COM5 confirmed; advance to manual ROM download-mode probe — 2026-11-08

User explicitly confirmed FarmCart controller is COM5. COM4 must not be used for FarmCart.

Current Windows evidence:
- COM4 and COM5 both enumerate as Espressif USB VID_303A PID_1001 interfaces, but user confirms FarmCart target is COM5
- COM4 probe failed with Windows device/permission error and is out of scope
- COM5 standard esptool `chip-id` and `flash-id` both fail at `Connecting...` with pySerial `Write timeout`
- unplug/replug did not restore the previously working automatic esptool connection

Interpretation:
- failure is before flash read/write and before scan-fix firmware transfer
- current evidence supports an auto-download/serial transport state issue, not flash-size mismatch or firmware-source defect
- no scan-fix flash write has occurred

Next recovery step:
- manually enter ESP32-S3 ROM download mode using BOOT(GPIO0) + EN/RST
- after manual bootloader entry, run read-only esptool probe with `--before no-reset --after no-reset` on COM5 so esptool does not disturb the manually selected boot mode
- only after chip-id and flash-id PASS should the approved flash operation resume

## FarmCart re-enumerated on COM7; physical identity re-confirmed — 2026-11-08

User probed COM7 after COM5 repeatedly failed with pySerial `Write timeout`.

COM7 physical identity evidence:
- esptool v5.3.1 connected successfully using normal stub path
- chip: ESP32-S3 QFN56 rev0.2
- embedded PSRAM: 8MB
- MAC: `14:c1:9f:50:b9:64`
- MAC exactly matches the previously established FarmCart controller identity
- `flash-id` PASS
- detected flash size: 16MB
- flash manufacturer/device: c2 / 2018
- flash bus: quad
- flash voltage: 3.3V
- esptool stub flasher ran successfully
- `Hard resetting via RTS pin` completed normally

Interpretation:
- FarmCart controller has re-enumerated from historical COM5 to COM7
- prior COM5 `Write timeout` was a host/USB/port enumeration state issue, not a controller identity or flash-capacity defect
- COM7 is now the verified physical target for the already-approved R8.14 scan-fix flash

Approval scope:
- existing user approval `FLASH_R814_SCANFIX_N16R8` remains valid because the physical target is proven identical by MAC
- firmware source, board profile, partition scheme and write scope are unchanged
- MAIN remains untouched
- relay/pump/load power must remain disconnected during flash

## COM7 full-backup attempt is pathological; abort before write — 2026-11-08

User reported the approved scan-fix runner was taking excessively long.

Uploaded log evidence:
- device identity gate PASS on COM7
- MAC `14:c1:9f:50:b9:64`, PSRAM 8MB, flash 16MB
- runner entered `FULL 16MB PRE-FLASH BACKUP: CHUNKED READ`
- backup mode was 32 x 512KB, stub retry3 then no-stub retry3 at 115200
- repeated errors included corrupt data, invalid packet heads, packet transfer stopped, write timeout, busy/non-functioning port, failed baud set and eventually repeated `No serial data received`
- by uploaded log tail the runner had reached chunk 20/31
- no `BACKUP_CHUNK_PASS=` or `BACKUP_CHUNK_PASS_NO_STUB=` was present in the uploaded log
- no `FULL_FLASH_BACKUP=PASS` was present
- no `FLASH WRITE START` was present

Decision:
- user may abort current runner with Ctrl+C immediately
- abort is safe because write stage was never reached
- do not repeat full 16MB backup under the same transport parameters

Next diagnostic:
- new read-only 4KB flash-read transport probe tests stub and no-stub at 115200/57600/38400/19200
- only a path/baud that can complete an exact 4096-byte read should be considered for further backup work
- firmware flash approval remains granted but execution stays blocked until a reliable pre-write read strategy is demonstrated

## Correction: FarmCart transport remains locked to 115200 only — 2026-11-08

User corrected an invalid diagnostic change: FarmCart serial/esptool transport is project-locked to 115200 baud.

Correction:
- remove experimental 57600/38400/19200 probe paths
- all flash read/backup/recovery diagnostics remain at 115200 only
- existing historical successful backup method remains 32 x 512KB at 115200 with stub retry then no-stub fallback
- no change to firmware source, FQBN, partition layout, board profile or approval scope

Current physical target:
- ESP32-S3 N16R8
- Flash 16MB
- PSRAM 8MB
- MAC `14:c1:9f:50:b9:64`
- currently enumerated as COM7
- esptool 5.3.1
- Arduino-ESP32 3.3.12
- BAUD_LOCK=115200_ONLY

## COM7 4KB transport probe failed; move to manual ROM download mode — 2026-11-08

Read-only 4KB transport probe executed on verified FarmCart COM7 with BAUD_LOCK=115200_ONLY.

Evidence:
- stub read 0x8000 + 0x1000: FAIL at `Connecting...` with `No serial data received`
- no-stub read 0x8000 + 0x1000: FAIL at `Connecting...` with `No serial data received`
- no flash write, erase or NVS write occurred

Interpretation:
- failure occurs before flash-read transport begins
- verified physical target remains COM7 / MAC `14:c1:9f:50:b9:64`
- source/FQBN/flash-size are not implicated by this failure
- automatic reset/download entry is not currently yielding a responsive ROM handshake

Next:
- manually enter ESP32-S3 ROM download mode using BOOT(GPIO0)+EN/RST
- probe COM7 at 115200 only
- use esptool `--before no-reset --after no-reset` so the manual ROM state is preserved during the read-only probe
- resume approved scan-fix flash only after manual-ROM chip-id and flash-id pass

## Manual BOOT+EN no-reset probe still no response; switch to BOOT-at-power-on ROM entry — 2026-11-08

Manual BOOT+EN/RST attempt followed by esptool `--before no-reset --after no-reset` on COM7 at 115200 still failed for both chip-id and flash-id with `No serial data received`.

Interpretation:
- COM7 was previously proven as the same FarmCart controller by MAC and 16MB flash
- current failure means the attempted reset sequence did not leave a responsive ROM loader on COM7
- no flash/erase/NVS write occurred

Next recovery method:
- use BOOT held LOW from power-on / USB insertion rather than relying on the EN reset sequence
- after enumeration, release BOOT and discover the actual COM port Windows assigns in ROM mode
- keep esptool baud locked at 115200
- perform read-only chip-id/flash-id before any write

## BOOT-held power-on changed COM7 enumeration to Unknown — 2026-11-08

User performed BOOT-held USB power-on recovery as instructed.

Observed enumeration:
- `arduino-cli board list`: COM7 remains present but Board Name changed to `Unknown`
- COM4 remains an ESP32 Family Device and is out of FarmCart scope
- Win32_SerialPort query for VID_303A only returned COM4; COM7 is not exposed through that query in this state

Interpretation:
- COM7 descriptor/state changed after BOOT-held power-on
- this is consistent with a ROM/bootloader enumeration change and is preferable to the prior nonresponsive application-mode state
- no flash/erase/NVS write occurred

Next:
- keep COM7 as the FarmCart target
- at BAUD_LOCK=115200_ONLY run esptool chip-id and flash-id with `--before no-reset --after no-reset` while leaving the board in this state
- do not reset or reconnect before the probe

## COM7 manual power-on ROM entry PASS — 2026-11-08

BOOT-held USB power-on recovery succeeded on the verified FarmCart controller.

Read-only evidence at BAUD_LOCK=115200_ONLY:
- esptool v5.3.1
- COM7
- `--before no-reset --after no-reset`
- chip-id PASS
- ESP32-S3 QFN56 rev0.2
- PSRAM 8MB
- MAC `14:c1:9f:50:b9:64`
- stub flasher running
- flash-id PASS
- manufacturer c2 / device 2018
- detected flash size 16MB
- quad flash, 3.3V
- esptool reported `Staying in bootloader` after both commands

Interpretation:
- ROM bootloader entry is now proven stable when BOOT is held during USB power-on
- previous failures were caused by connection/reset state, not board identity, flash size, or scan-fix source
- current device is intentionally left in bootloader state

Next:
- perform a 4KB read at 115200 using `--before no-reset --after no-reset`
- if exact 4096-byte read passes, adapt the approved flash runner to preserve this no-reset bootloader state during backup/write
- do not use the old reset-per-command behavior again

## Scan-fix recovery pivot: APP0-only ROM flash, no full-flash backup loop — 2026-11-08

Root-cause/workflow correction after repeated read-path failures:
- full 16MB readback is abandoned for this scan-fix attempt; it is not a prerequisite for an application-only patch
- scan-fix ESP32 source delta from baseline runtime lock `566cc4843...` to scan-fix source lock `30ab9bb...` is exactly one firmware application file: `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- no OTA runtime implementation was found in the firmware entrypoint or WiFi transport source
- canonical partition layout remains app0 0x10000 / 0x300000 and app1 0x310000 / 0x300000
- previous full Arduino upload established the baseline boot layout; no later OTA slot switch is recorded

New approved-write strategy:
- dedicated runner: `tools/windows/FLASH_FARMCART_R814_SCANFIX_APP0_ROM_APPROVAL_GATED.cmd`
- existing approval token remains `FLASH_R814_SCANFIX_N16R8`
- BAUD_LOCK=115200_ONLY
- manual BOOT-held power-on ROM download mode required
- esptool stub disabled with `--no-stub`
- compression disabled with `--no-compress`
- esptool reset toggling disabled before and after operation
- only application partition APP0 at 0x10000 is written
- NVS untouched
- OTA data untouched
- partition table untouched
- bootloader untouched
- erase-all NO
- app binary size must remain below 0x300000
- MAC must match `14:c1:9f:50:b9:64` and flash must report 16MB before write
- esptool v5 automatic post-write verification is relied upon when technically feasible
- device remains in bootloader after successful write; user performs one EN/RST after PASS

Why this is safer here:
- avoids the proven-pathological 16MB device-to-host read stream
- avoids unnecessary rewrites of bootloader/partition/OTADATA for a one-file application source change
- preserves persisted NVS and the established partition/boot metadata

## APP0 runner source-scope gate false negative fixed — 2026-11-08

First APP0-only runner attempt stopped before build/device access/write.

Observed:
- printed ESP32 scan-fix diff path was exactly `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- runner nevertheless emitted `ERROR=EXPECTED_SCANFIX_FILE_MISSING`
- root cause was the Windows CMD `findstr /X` path-match gate, not source drift
- no flash/erase/NVS/OTADATA/partition/bootloader write occurred

Correction:
- commit `6c855afb1e5694998e2443201a865f5e3799715e`
- diff scope check now parses the diff list directly
- it requires exactly one ESP32 changed file
- that one path must equal `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- all other APP0-only safety locks remain unchanged

## APP0 scan-fix partial write failure — recovery required — 2026-11-08

User executed `FLASH_FARMCART_R814_SCANFIX_APP0_ROM_APPROVAL_GATED.cmd COM7 FLASH_R814_SCANFIX_N16R8` at HEAD `e5bad623643e21521d6ec4b0dad144b820d0c564`.

Passed gates:
- source lock PASS
- exact ESP32 diff scope PASS, only `WiFiTransport.cpp`
- canonical 16MB/8MB N16R8 profile PASS
- build PASS: APP_BYTES=1058368, APP_SHA256=`6422a5a129be823cb707a14e3af17682c8687517ea3c218d391c3c8f97b71fd0`
- ROM chip ID, MAC `14:c1:9f:50:b9:64`, flash-id 16MB PASS on COM7 at 115200, no-stub/no-reset

Actual flash failure (THIS ATTEMPT WROTE/ERASED APP0):
- targeted APP0 only at `0x10000`
- `esptool` reported erasing from 0x10000 through 0x112fff
- write progressed to 11.9% (125952/1058368 bytes) before connection loss
- automatic retry re-erased the same range, then progressed 5.9% (62464/1058368 bytes)
- pySerial `Write timeout` terminated the operation
- runner output `APP0_FLASH_STATUS=FAIL`
- **APP0 MUST BE TREATED AS PARTIALLY ERASED/PROGRAMMED; BOOTABILITY NOT VERIFIED**
- no full 16MB backup was made in this attempt
- runner did not target NVS/OTADATA/partition table/bootloader or issue erase-all

Safety state and required recovery:
- external relay/pump/load must remain disconnected
- do not treat current application as runnable; do not enter regular firmware tests yet
- avoid repeatedly using the same unstable USB serial data path
- first verify USB data cable, direct host port, host-side serial driver and power stability (esptool docs associate corrupted packets/timeouts with USB link and supply issues)
- keep 115200 baud per project lock
- if possible keep board in manual ROM download mode; otherwise reenter with BOOT held while USB power is applied
- do not rely on `chip-id`/`flash-id` success as proof long transfers are stable
- only attempt recovery APP0 write after transport issue is addressed, then require complete write+verify and reboot smoke before declaring recovery
- if alternate direct cable/port does not stabilize transfers, evaluate separate hardware UART programmer instead of more loops

Last confirmed previous full 16MB backup (before baseline R8.14 flash):
- path `D:\FarmCart\backups\farmcart_r814_preflash_COM5_20261107_220605`
- SHA256 `a3e74d26160e9b738cdb7d015edf1244dccb3143f90c0f12ad62b8dfb6f64802`
- do not overwrite or erase this historical backup

Current acceptance:
- SCANFIX_FLASH=FAIL_PARTIAL_APP0
- APP0_BOOT=UNVERIFIED
- DEVICE_RUNTIME=BLOCKED
- MAIN=UNTOUCHED

## Recovery blocker: 64KB ROM read fails at 1KB; stop USB-Serial/JTAG retries — 2026-11-08

Latest user evidence after APP0 partial-write incident:
- COM7 (manual BOOT-held ROM download mode), `--before no-reset --after no-reset --no-stub`, BAUD=115200
- chip-id PASS, ESP32-S3 rev0.2, PSRAM 8MB, MAC `14:c1:9f:50:b9:64`
- attempted read only: `read-flash --flash-size 16MB 0x10000 0x10000` (64KB)
- read progressed only to `0x00010400`, 1,024/65,536 bytes (1.6%)
- esptool failed: `Invalid head of packet (0x6F): Possible serial noise or corruption`
- no valid 64KB recovery backup was produced; no write occurred in this probe

Evidence-based diagnosis:
- ROM connectivity and physical identity work, but sustained transfer across current native USB-Serial/JTAG interface is unreliable
- earlier attempts failed identically for stub and ROM no-stub flash reads; APP0 write failed after partial erase/program
- likely areas for investigation per Espressif esptool troubleshooting: USB data cable, native USB interface/host driver, physical connection, power stability, attached circuit interference
- root cause not yet isolated; do not claim flash chip defective or firmware regression causes this serial framing error

Immediate safety & recovery policy:
- STOP repeated esptool flash-read / write attempts through this unstable COM7 USB path
- retain prior full backup: `D:\FarmCart\backups\farmcart_r814_preflash_COM5_20261107_220605` (historical 16MB, SHA256 a3e74d26160e9b738cdb7d015edf1244dccb3143f90c0f12ad62b8dfb6f64802)
- retain newly compiled APP image: SHA256 `6422a5a129be823cb707a14e3af17682c8687517ea3c218d391c3c8f97b71fd0`, 1,058,368 bytes
- do not erase NVS / OTADATA / partition table / bootloader or use erase-all
- physical relay/pump/load stays disconnected
- APP0 remains partially erased/programmed and is not considered bootable
- troubleshoot hardware connection / 3.3V power and isolate board from external wiring first; no more blind retry loops
- if USB Serial/JTAG transport remains unreliable, use a verified dedicated USB-to-UART TTL (3.3V logic) via UART0, default ESP32-S3 GPIO43 TX0 / GPIO44 RX0, with common ground, BOOT-held manual ROM entry, and 115200 baud
- do not wire or energize unverified board pinouts; confirm actual board labels/photo before using external UART
- next flash must be a single bounded APP0-only recovery with verified target identity and full completion + verification; preserve other partitions

References checked: Espressif esptool ESP32-S3 Troubleshooting (Invalid head of packet, writing fails part-way, USB-Serial/JTAG transport/driver/power).

## R8.13 REBASE 2 ZIP source audit; do not blame GPIO peripherals without evidence — 2026-11-08

User supplied `SmartFarm_ESP32_5F_R8_13_REBASE_2(1).zip`; direct content inspection (103 files, no precompiled `.bin`/`.elf`, no `.cmd`/`.bat`/`.ps1`) completed.
ZIP SHA256: `0e9333922da7895f6ce2d13042d01ea5c2eb1953bc72993aca31d638f9b39583`.

Source-based facts:
- `RELEASE_R8_13_REBASE_2.md`: prior version `0.8.0-5f-r8.13-rebase-2`, N16R8, Active HIGH, relays GPIO4/5/6/7/15/16/17/18, DS3231 SDA GPIO8 SCL GPIO9
- `Config.h`: `SERIAL_BAUD = 115200`, `FACTORY_RESET_PIN=0`, WiFi provisioning marker 81202, AP port 80
- `.ino`: `Serial.begin(SERIAL_BAUD)`; 115200 here refers to application serial/Serial Monitor, not an esptool upload-baud specification
- `README_5E_TH.txt`: Arduino IDE board ESP32S3 Dev Module, Flash 16MB, OPI PSRAM, USB CDC On Boot Enabled; this is a historical checkpoint, not an exact current flash recipe
- `WiFiTransport.cpp` R8.13 synchronous `WiFi.scanNetworks(false, true)`; R8.14 scan-fix code uses asynchronous scan status, unrelated to ROM flash transfer protocol
- archive source does not assign GPIO19 or GPIO20 to relay/RTC/accessories; USB Serial/JTAG uses those pins on ESP32-S3 (per Espressif reference)
- archive has no original compiled binary and no original flashing script/command; do not pretend the archive proves which transport/baud was used by historical successful upload

Corrected diagnosis:
- historical baseline R8.14 full flash PASS is documented, and this board ROM MAC/flash identity later passed
- after multiple interrupted transfers, APP0 write is partially completed and recovery is necessary
- observed failures happen inside ROM flash-read/write, before user application is running, so blaming current Wi-Fi scan-fix or RTC/relay GPIO wiring directly is not supported by available evidence
- external wiring can matter indirectly via shared power/ground/USB/SPI interference, but the current log does not establish that as cause
- keep user-established 115200 esptool diagnostic policy without conflating it with source `SERIAL_BAUD` constant
- note Windows previously enumerated COM7 as Unknown while COM4 had Espressif VID_303A/PID_1001; exact COM7 USB VID/PID/driver remains unverified: inspect Windows USB descriptor before further invasive hardware actions
- next action: **host-only** COM7 serial device VID/PID/hwid/driver inspection, with no esptool access, flash writes or retry loops
- do not run the old approved flash runners until transport reliability is demonstrated

## COM7 CH343 USB-UART positively identified; test native USB alternative — 2026-11-08

NEW VERIFIED Windows USB evidence:
- `COM7 USB-Enhanced-SERIAL CH343`, VID:PID `1A86:55D3`, serial `5C82118392`, WCH manufacturer `wch.cn`, Windows service `CH343SER_A64`, PnP status `OK`
- `COM4 USB Serial Device`, VID:PID `303A:1001`, serial `E8:F6:0A:B8:B7:0C`, Microsoft provider; an Espressif native USB interface
- earlier COM7 esptool chip ID matched controller MAC `14:c1:9f:50:b9:64`, proving COM7 -> actual FarmCart MCU
- earlier assumption that COM7 was ESP32-S3 native USB Serial/JTAG was WRONG; it is a CH343 USB-to-UART bridge
- Windows CH343 driver VERSION is not yet known; `CH343SER_A64` is a service name, not a driver version

Relevant sourced hardware possibility (UNCONFIRMED for FarmCart):
- Waveshare ESP32-S3-DEV-KIT-N16R8 family FAQ documents CH334 USB hub that can enumerate a CH343 USB-to-UART COM port and an ESP32-S3 native USB COM port from the same physical USB cable
- therefore COM4 and COM7 *might* belong to the same physical board; they must NOT be assumed same or different without a physically observed unplug enumeration comparison

Prioritize safe diagnostics:
- with external relay/pump/load power isolated, unplug ONLY the FarmCart USB cable and run `arduino-cli board list` to see whether COM4 disappears alongside COM7
- reconnect with BOOT held to restore ROM mode, then re-enumerate
- if COM4 also disappeared/reappeared, it is likely the same board's native Espressif USB and could provide an alternate recovery transport, but confirm ESP32 MAC on that port before any write
- if COM4 remained, it belongs to a separate device; stop probing it as FarmCart
- if COM7 remains the only FarmCart path, inspect signed CH343 driver version using Win32_PnPSignedDriver and consider official WCH CH343SER driver update after review
- official WCH `CH343SER.EXE` supports Windows 10; source: https://www.wch.cn/downloads/CH343SER_EXE.html
- separate ESP32 application SERIAL_BAUD=115200 from physical CH343 driver selection; honor 115200-only esptool project diagnostics as directed
- no esptool read/write retry on current corrupt CH343 path until physical transport investigation yields evidence

Recovery safety: APP0 remains partially erased/programmed; no reset into normal firmware as a verification substitute; bootloader ROM is independent; NVS/OTADATA/bootloader/partition preservation remains required.

## Verified native USB target COM5 distinct from CH343 COM7 — 2026-11-08

Latest Windows serial enumeration (user supplied):
- COM3 CH343, USB VID:PID `1A86:55D3`, SER `5C94153873`, separate CH343 device
- COM4 Espressif native USB `303A:1001`, SER `E8:F6:0A:B8:B7:0C`: user confirms this is their OTHER Waveshare ESP32-S3, not FarmCart
- COM5 Espressif native USB Serial/JTAG `303A:1001`, SER `14:C1:9F:50:B9:64`: this is FarmCart's own native USB interface and MAC
- previous COM7 CH343 `1A86:55D3`, SER `5C82118392`, accessed an ESP32-S3 with the SAME MAC `14:c1:9f:50:b9:64`; this was another access path into the FarmCart MCU

COM5 read-only results:
- standard `chip-id`: pySerial Windows `PermissionError(13)` device not functioning
- standard `flash-id`: established ESP32-S3 QFN56 rev0.2, PSRAM 8MB, `USB mode: USB-Serial/JTAG`, MAC `14:c1:9f:50:b9:64`
- esptool stub upload then failed with `Write timeout`, so flash-id did NOT complete
- COM5 native USB should not be conflated with previously unstable COM7 CH343 UART path

Action / interpretation:
- no flash write occurred in this COM5 attempt
- APP0 remains partially erased/programmed from previous COM7 write failure
- avoid CH343 COM7 read/write retry loops; do not touch independent Waveshare COM4
- attempt a single bounded recovery probe on FarmCart **native USB COM5**, not the CH343 path
- manually enter ROM download mode while powering/reconnecting the physical USB interface associated with COM5 (BOOT held while USB is plugged in), then identify current VID/PID/serial/MAC
- run `--chip esp32s3 -b 115200 --before no-reset --after no-reset --no-stub` only after ROM enumeration
- first bound native USB flash-read to 64KB without any write; success does not alone certify 1MB write reliability
- no erase-all or bootloader/NVS/OTADATA mutation permitted; APP0-only recovery remains required

Reference: Espressif ESP32-S3 esptool troubleshooting on USB-Serial/JTAG, manual download and packet errors: https://docs.espressif.com/projects/esptool/en/latest/esp32s3/troubleshooting.html

## Correct native COM5 recovery reset mode: esptool usb-reset — 2026-11-08

After user supplied exact COM enumeration and R8.13 ZIP audit, correct transport distinction is now:
- COM5 = FarmCart ESP32-S3 native USB Serial/JTAG, VID:PID 303A:1001, serial `14:C1:9F:50:B9:64`
- COM7 = external WCH CH343 UART path into the same FarmCart ESP32-S3
- COM4 = separate Waveshare ESP32-S3 owned by user; out of scope

Important esptool correction:
- previous COM5 recovery probes used `--before no-reset`, which is not the dedicated reset mode for native USB Serial/JTAG
- esptool documents `--before usb-reset` specifically for USB-JTAG-Serial connections; normally autodetected, but explicit use is appropriate for this recovery state
- R8.13 supplied source documentation confirms `USB CDC On Boot: Enabled` for ESP32-S3 N16R8; source `SERIAL_BAUD=115200` refers application/monitor serial, not proof of historical upload speed
- user requires current diagnostics/recovery to remain at 115200; honor BAUD_LOCK=115200

Next bounded recovery check:
- no flash write yet
- target COM5 only
- use `--before usb-reset --after no-reset` at 115200 for chip-id and flash-id
- if native USB identity/flash-id complete cleanly, perform one bounded native-USB transfer test before APP0 recovery; do not return to CH343 COM7 loops
- APP0 remains partially programmed from prior COM7 write failure; NVS/OTADATA/partition/bootloader remain protected

References: esptool ESP32-S3 Advanced Options (`usb-reset`) and Arduino-ESP32 USB CDC flashing docs.
## COM5 usb-reset reaches ROM identity but stub upload still times out — 2026-11-08

Latest COM5 native USB-Serial/JTAG evidence:
- `--before usb-reset --after no-reset chip-id`: esptool reported Connected to ESP32-S3 on COM5, then Windows pySerial `PermissionError(13, device attached is not functioning, error 31)` while configuring/reopening the native USB serial endpoint
- `--before usb-reset --after no-reset flash-id`: ROM identity completed (ESP32-S3 QFN56 rev0.2, PSRAM 8MB, USB mode USB-Serial/JTAG, MAC 14:c1:9f:50:b9:64), then esptool attempted `Uploading stub flasher...` and failed with `Write timeout`
- no flash write occurred in either command

Interpretation:
- COM5 target identity is conclusively FarmCart
- usb-reset improves ROM entry/identity but does not make stub upload reliable on this Windows USB path
- Espressif documents that USB-Serial/JTAG is valid for firmware download, that pySerial exceptions generally indicate host/driver/disconnection issues, and that `--no-stub` bypasses the RAM stub upload entirely
- the next bounded diagnostic should therefore be ROM-only on COM5: `--before usb-reset --after no-reset --no-stub flash-id`
- if ROM-only flash-id succeeds, use ROM-loader write path for the already-partial APP0 recovery; avoid stub and CH343 COM7
- APP0 remains partially programmed; runtime tests blocked; main untouched

## Native USB ROM no-stub flash-id PASS; APP0 recovery path unlocked — 2026-11-08

User executed on FarmCart native USB COM5:
`python -m esptool --chip esp32s3 --port COM5 -b 115200 --before usb-reset --after no-reset --no-stub flash-id`

Result: PASS.
- ESP32-S3 QFN56 rev0.2
- PSRAM 8MB
- USB mode: USB-Serial/JTAG
- MAC: `14:c1:9f:50:b9:64`
- flash manufacturer `c2`, device `2018`
- detected flash size `16MB`
- quad 4-line, 3.3V
- command ended `Staying in bootloader.`
- no stub upload was attempted and no timeout occurred

Conclusion:
- native COM5 ROM loader path is viable when using `usb-reset` plus `--no-stub` at project-locked 115200
- prior COM5 failures were associated with port reconfiguration/stub upload; prior COM7 CH343 path had sustained-transfer corruption
- proceed with one bounded APP0-only recovery write through COM5 native USB ROM loader; no full-flash backup/read loop

Dedicated runner:
- `tools/windows/FLASH_FARMCART_R814_SCANFIX_APP0_NATIVE_USB_RECOVERY.cmd`
- single flash-id identity gate (no redundant chip-id)
- expected MAC `14:c1:9f:50:b9:64`
- native USB Serial/JTAG mode required
- flash 16MB required
- source and one-file scan-fix diff locks preserved
- APP0 only at 0x10000
- no stub, no compression, no erase-all
- NVS/OTADATA/partition table/bootloader untouched
- existing user approval `FLASH_R814_SCANFIX_N16R8` remains in scope for this recovery of the same scan-fix firmware

## APP0 native USB ROM recovery flash PASS — 2026-11-08

Physical recovery flash completed successfully on FarmCart native USB COM5.

Verified preflight:
- transport: ESP32-S3 native USB Serial/JTAG
- reset mode: `usb-reset`
- esptool 5.3.1
- baud: 115200
- stub disabled
- MAC: `14:c1:9f:50:b9:64`
- flash size: 16MB
- source lock PASS
- scan-fix diff scope PASS: only `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp`
- canonical N16R8 profile PASS

Build:
- APP bytes: 1,058,368
- APP SHA256: `44a6acaf638003458ee5272f339b15edf64ffc0e5a6fa26d38f1002e8f52402f`

Write result:
- APP0 offset: `0x10000`
- wrote 1,058,368 / 1,058,368 bytes
- transfer time: 16.4 seconds
- throughput: 516.7 kbit/s
- esptool: `Verifying written data...`
- esptool: `Hash of data verified.`
- `APP0_RECOVERY_WRITE=PASS`
- device remained in bootloader after write

Preservation:
- NVS preserved
- OTADATA preserved
- partition table preserved
- bootloader preserved
- erase-all NO

Current gate status:
- SCANFIX_FLASH=PASS
- APP0_RECOVERY=PASS
- FLASH_VERIFY=PASS
- POSTWRITE_RUNTIME=NOT_YET_TESTED
- WIFI_SCAN_RUNTIME=NOT_YET_TESTED
- MAIN=UNTOUCHED

Next:
- leave external relay/pump/load power disconnected
- exit bootloader with one EN/RST press
- verify firmware boot and SmartFarm AP/runtime
- then test `/api/wifi/scan` behavior and Flutter polling compatibility before reconnecting load hardware

## Scan-fix postflash smoke runner corrected after APP0 recovery PASS — 2026-11-08

Created `tools/windows/RUN_FARMCART_R814_SCANFIX_POSTFLASH_SMOKE_READONLY.cmd` at commit `3d61bb178264853c7b35aa817d490e57ff3774e6`.

Purpose:
- post-flash smoke for scan-fix source lock `30ab9bbadcc601b4978d416efb985af84ba9145e`
- no esptool access
- no reset automation
- no flash/NVS/WiFi config/relay writes
- serial runtime capture on COM5 for 20s
- passive Windows WLAN scan for `SmartFarm-*`
- user performs exactly one physical EN/RST before runner
- external relay/pump/load remains disconnected

Reason:
- legacy R8.14 postflash smoke runner was stale: it locked pre-scanfix runtime SHA `566cc4843...` and invoked generic esptool chip-id, which could reintroduce the transport/stub problem and false-fail the new scan-fix build.

## Post-recovery reboot: SmartFarm AP not seen in Windows passive scan — 2026-11-08

After verified APP0 native USB ROM recovery PASS, user performed the instructed post-write reboot and then ran:
`netsh wlan show networks mode=bssid | findstr /I "SmartFarm-"`

Observed:
- command returned no `SmartFarm-*` SSID lines
- therefore SmartFarm AP presence is NOT confirmed after reboot
- do not regress or reflash yet: APP0 write + esptool hash verification already PASS
- next gate is non-invasive serial runtime capture using `RUN_FARMCART_R814_SCANFIX_POSTFLASH_SMOKE_READONLY.cmd COM5`
- runner performs no esptool access, no flash/NVS/relay/WiFi writes
- objective: determine whether firmware boot banner/version/AP-start is present or whether runtime is failing before SoftAP starts

## Multi-ESP32 USB contention confirmed by user observation — 2026-11-08

User confirmed an important environmental factor:
- two ESP32-class boards were connected to the same Windows host during troubleshooting
- COM4 belongs to a separate Waveshare ESP32-S3
- FarmCart native USB has serial/MAC-derived identifier `14:C1:9F:50:B9:64`
- user reports the same kind of USB/COM instability has occurred during WQMS work when multiple ESP32 devices were connected
- when the extra ESP32 device was unplugged, the problem disappeared

Interpretation:
- multi-device USB enumeration / COM re-enumeration is now the leading environmental cause of the confusing transport failures and port switching
- this does not prove the two MCUs electrically interfere with each other; the likely issue is host-side port identity/reset/re-enumeration ambiguity while multiple Espressif USB devices are present
- therefore FarmCart recovery/runtime verification must be performed with only the FarmCart ESP32-S3 connected
- do not reflash: APP0 recovery write and hash verification already PASS
- next gate is runtime/AP verification with the second ESP32 disconnected

## Postboot enumeration: native COM5 absent, FarmCart CH343 COM7 remains — 2026-11-08

After verified APP0 recovery flash and physical EN/RST, the auto-port smoke runner found no FarmCart native USB serial matching `14:C1:9F:50:B9:64`.

Current Windows ports:
- COM1 standard serial
- COM7 `USB-Enhanced-SERIAL CH343`, VID:PID 1A86:55D3, serial 5C82118392
- no Espressif native USB COM for FarmCart is currently enumerated

Interpretation:
- do NOT equate missing COM5 after reset with failed firmware boot; native USB enumeration can differ between ROM and application runtime
- COM7 CH343 remains the persistent FarmCart UART bridge and is the correct next passive runtime-log path
- no reflash is warranted: APP0 write and esptool hash verification already PASS
- next diagnostic: open CH343 COM7 at 115200 with DTR/RTS disabled, then press EN/RST once while capture is already active to catch setup boot banner
- no esptool, no flash/NVS/relay/WiFi writes during this gate

## Postflash runtime: SmartFarm AP PASS; proceed to Wi-Fi scan-fix acceptance — 2026-11-08

Latest postflash smoke after verified APP0 recovery:
- auto-port correctly identified FarmCart native USB COM5 by serial `14:C1:9F:50:B9:64`
- ROM boot log seen: `rst:0x15 (USB_UART_CHIP_RESET), boot:0x28 (SPI_FAST_FLASH_BOOT)` and application entry `0x403c88b8`
- application `Serial` banner/version was NOT seen on COM5 during capture
- Windows passive Wi-Fi scan returned `SMARTFARM_AP_SCAN=PASS`

Interpretation:
- APP0 is booting far enough for SmartFarm SoftAP to be present; runtime is alive
- absence of app Serial banner on COM5 is not currently a blocker for Wi-Fi scan-fix acceptance
- do not reflash; FLASH/VERIFY already PASS

Created dedicated read-only scan-fix runtime acceptance:
- PowerShell: `tools/windows/RUN_FARMCART_R814_WIFI_SCANFIX_RUNTIME_READONLY.ps1` commit `b2a02dcbebd8dd6d92d49daa7bbfdd0daac4efb4`
- wrapper: `tools/windows/RUN_FARMCART_R814_WIFI_SCANFIX_RUNTIME_READONLY.cmd` commit `d343c01161f8e98dcf1a664e04e20423b6ec67a1`
- requires Windows connected to SmartFarm-* AP at 192.168.4.1
- GET-only; no ESP/NVS/relay/Wi-Fi config/flash writes
- validates `/api/device`
- polls `/api/wifi/scan` up to 30 times at 350ms, matching Flutter compatibility behavior
- while `scanState=scanning`, also GETs `/api/device` to prove HTTP remains responsive
- requires eventual `scanState=complete` and post-scan `/api/device` PASS
- emits final network list and `WIFI_SCANFIX_RUNTIME=PASS` only on full acceptance

Next: connect Windows to visible SmartFarm-* (password `smartfarm123`) and run the dedicated scan-fix runtime wrapper. Keep relay/pump/load power disconnected.

## First scan-fix runtime acceptance blocked by pre-existing Windows HTTP latency — 2026-11-08

User ran `RUN_FARMCART_R814_WIFI_SCANFIX_RUNTIME_READONLY.cmd` while Windows was connected to SmartFarm AP.

Observed before scan:
- `/api/device` HTTP 200 PASS
- firmware `0.8.0-5f-r8.14-stability-1` confirmed at runtime
- device ID `sf-64B9509FC114` confirmed
- `/api/device` RTT was extremely high: 12,767.1 ms

First `/api/wifi/scan` request:
- client timeout at 3,011.4 ms
- runner emitted `WIFI_SCANFIX_RUNTIME=FAIL_HTTP`

Interpretation:
- this run does NOT isolate the Wi-Fi scan-fix because HTTP transport was already severely slow before `/api/wifi/scan` was invoked
- historical evidence in this Handoff already showed Windows AP HTTP instability: 38/60 GET PASS (63.3%) on the prior transport test, while Android direct-IP access to the same SmartFarm AP was qualitatively stable
- historical leading classification: Windows Realtek RTL8188EU client path instability rather than global ESP32 SoftAP failure
- current firmware also contains STA reconnect maintenance, but do not mutate/clear NVS yet because client-path instability is already established and must be separated first

Next gate:
- reuse existing read-only `RUN_FARMCART_R814_AP_LINK_VS_HTTP_DIAGNOSTIC_READONLY.cmd`
- it measures WLAN interface/route, 30 ICMP pings and 20 `curl.exe --noproxy *` root HTTP requests
- no ESP/NVS/relay/RTC/Wi-Fi/flash writes
- do not reflash; scan-fix firmware flash/verify/runtime version gates remain PASS

## Windows RTL8188EU link instability reconfirmed after scan-fix flash — 2026-11-08

Read-only AP link-vs-HTTP diagnostic after verified scan-fix flash:
- Windows Wi-Fi adapter: Realtek RTL8188EU Wireless LAN 802.11n USB 2.0
- connected SSID: `SmartFarm-9FC114`
- BSSID: `16:c1:9f:50:b9:64`
- channel 1, reported signal 100%, RX/TX 150 Mbps
- ping: 13 PASS / 17 FAIL out of 30; average successful wall time 227.1 ms, max 486.5 ms
- curl root HTTP: 6 PASS / 14 FAIL out of 20
- successful HTTP total avg 1305.1 ms, max 2276 ms
- classification from existing diagnostic: `AP_OR_RF_LINK_UNSTABLE`

Interpretation:
- this diagnostic did NOT invoke `/api/wifi/scan`, so the severe packet/HTTP loss exists independently of the scan-fix handler
- this reproduces the historical Windows RTL8188EU client-path instability already documented before the scan-fix
- do not patch or reflash scan-fix firmware based on this Windows result
- Windows RTL8188EU is unsuitable as the acceptance client for the scan-fix

Next acceptance client:
- use Android phone connected directly to `SmartFarm-9FC114` (password `smartfarm123`)
- first confirm `http://192.168.4.1/api/device` returns firmware `0.8.0-5f-r8.14-stability-1`
- then call `http://192.168.4.1/api/wifi/scan`; first response may be async `scanState=scanning`
- refresh/poll the same URL until `scanState=complete` and inspect `networks`
- acceptance requires AP remains connected/responsive and network list is returned without the prior AP-disappearance behavior
- keep relay/pump/load power disconnected

## Android isolates real async-scan start failure; stale STA CONNECTING fix prepared — 2026-11-08

Android direct-to-controller evidence after verified APP0 scan-fix flash:
- phone connected directly to `SmartFarm-9FC114`; phone UI correctly reports no Internet, which is expected for local controller AP
- `GET http://192.168.4.1/api/device` returned `ok=true`
- runtime firmware confirmed: `0.8.0-5f-r8.14-stability-1`
- device ID: `sf-64B9509FC114`
- AP SSID field: `SmartFarm-9FC114`
- AP IP: `192.168.4.1`
- hardware profile: `smart_farm_8ch_v1`
- stationConnected=false
- then `GET http://192.168.4.1/api/wifi/scan` returned `ok=false`, `error=wifi_scan_failed`, message `Unable to start Wi-Fi scan.`

This Android evidence removes the previously-known Windows RTL8188EU client instability from the scan-start failure and proves the scan start itself is failing in firmware.

Root-cause evidence:
- ESP-IDF documents that `esp_wifi_scan_start()` fails immediately with `ESP_ERR_WIFI_STATE` while STA is connecting
- Arduino-ESP32 converts that failure to `WIFI_SCAN_FAILED (-2)`
- Espressif Arduino issue #8916 reproduces the same AP+STA symptom after a failed STA connection and records collaborator-confirmed recovery by calling `WiFi.disconnect(false)` after the failed connection
- current FarmCart `connectStation()` previously timed out and returned false without explicitly aborting the STA connecting state

Source correction:
- commit `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- after `connectStation()` timeout/failure, call `WiFi.disconnect(false, false)` and delay 100ms before returning
- in `handleWifiScan()`, if async start still returns `WIFI_SCAN_FAILED` and STA is not actually connected, perform one non-erasing disconnect + 100ms delay + one scan retry
- established STA connection is not disconnected by scan recovery
- SoftAP remains enabled
- no NVS/credential erase added
- API contract remains the async `scanning/scanState` contract from the first scan-fix

Verification:
- Smart Farm CI run #14 / ID `42456112148` for source head `ed7168c8...`
- Flutter analyze/test: PASS
- ESP32-S3 N16R8 compile: PASS
- Android APK build: still in progress at latest check; Flutter source itself is unchanged by this firmware-only fix

Prepared flash gate (NOT YET APPROVED):
- `tools/windows/FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd`
- tool commit `74ee41b1d4e58d22c63582d328c2032eebbabd88`
- source lock `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- delta baseline `30ab9bbadcc601b4978d416efb985af84ba9145e`
- exact ESP32 delta must remain one file: `WiFiTransport.cpp`
- APP0 only at 0x10000
- COM5 native USB Serial/JTAG expected by physical MAC `14:c1:9f:50:b9:64`
- 115200, usb-reset, no-stub, no-compress
- NVS/OTADATA/partition table/bootloader untouched
- erase-all NO
- new approval token: `FLASH_R814_SCANFIX2_STA_STATE`
- previous flash approval does NOT automatically authorize this new source SHA

Current gates:
- SCANFIX1_FLASH_VERIFY=PASS
- ANDROID_DEVICE_API=PASS
- SCANFIX1_ASYNC_SCAN_START=FAIL
- ROOT_CAUSE_CLASS=STA_CONNECTING_STATE_BLOCKS_SCAN
- SCANFIX2_SOURCE=PREPARED
- SCANFIX2_ESP32_COMPILE=PASS
- SCANFIX2_FLASH=NOT_APPROVED
- MAIN=UNTOUCHED

## Scan-fix2 STA-state flash approval granted — 2026-11-08

User explicitly approved flashing the second R8.14 Wi-Fi scan correction after Android reproduced the firmware-level `wifi_scan_failed` condition.

Approved source:
- commit `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- change scope: `esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp` only relative to prior scan-fix baseline `30ab9bbadcc601b4978d416efb985af84ba9145e`
- purpose: clear stale STA CONNECTING state after failed STA connection and retry async scan once only when STA is not connected

Verification before approval:
- Smart Farm CI #14 / run ID `42456112148` = SUCCESS
- head SHA `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- ESP32-S3 N16R8 compile = PASS
- Flutter analyze/test = PASS
- Android demo APK job/workflow = PASS

Approved flash runner:
- `tools/windows/FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd`
- runner/tool commit `74ee41b1d4e58d22c63582d328c2032eebbabd88`
- approval token `FLASH_R814_SCANFIX2_STA_STATE`

Approved write scope:
- physical FarmCart ESP32-S3 N16R8
- MAC `14:c1:9f:50:b9:64`
- expected native USB target COM5 when enumerated
- 115200 only
- `usb-reset`
- `--no-stub`
- `--no-compress`
- APP0 only at `0x10000`
- NVS untouched
- OTADATA untouched
- partition table untouched
- bootloader untouched
- erase-all NO
- relay/pump/load power remains disconnected

Approval status:
- `FLASH_R814_SCANFIX2_STA_STATE=APPROVED`
- `FLASH_EXECUTION=NOT_YET_PERFORMED`
- MAIN=UNTOUCHED

Continuation policy reaffirmed by user:
- record material actions/results in GitHub Handoff
- continue from latest branch/source/runtime evidence; never restart from stale baseline
- preserve exact transport and safety constraints
- if chat context rolls over, start next chat from this Handoff and latest GitHub state

## Scan-fix2 STA-state APP0 flash PASS — 2026-11-08

User executed the approved scan-fix2 APP0 native USB ROM flash.

Result:
- `APP0_RECOVERY_WRITE=PASS`
- APP SHA256: `479002f5592a621723181b03b82f8677a4b8a7571b2bbe654801fc77b156edb8`
- APP bytes: `1058448`
- port: `COM5`
- evidence dir: `D:\FarmCart\smart-farm-5f\tools\windows\\..\..\..\backups\farmcart_r814_scanfix2_sta_state_COM5_20261108_140539`
- NVS preserved: YES
- OTADATA preserved: YES
- partition table preserved: YES
- bootloader preserved: YES
- erase-all: NO
- post-write runtime: NOT YET TESTED

Interpretation:
- SCANFIX2_SOURCE=ed7168c8b9b318c684412ad9e0baa6291ce1534d
- SCANFIX2_FLASH=PASS
- APP0_WRITE=PASS
- runtime acceptance remains pending
- do not reflash

Next exact runtime gate:
1. keep relay/pump/load power disconnected
2. press EN/RST exactly once; do not press BOOT
3. connect Android to `SmartFarm-9FC114` / password `smartfarm123`
4. open `http://192.168.4.1/api/device` and confirm runtime firmware/version/device
5. open `http://192.168.4.1/api/wifi/scan`
6. expected first response may be `scanning=true`, `scanState=scanning`
7. refresh/poll same URL until `scanning=false`, `scanState=complete` with `networks`
8. AP must remain reachable throughout

Current gates:
- SCANFIX2_CI=PASS
- SCANFIX2_FLASH=PASS
- SCANFIX2_RUNTIME=NOT_YET_TESTED
- WIFI_SCANFIX_RUNTIME=NOT_YET_PASS
- MAIN=UNTOUCHED

## Scan-fix2 runtime acceptance PASS on Android — 2026-11-08

Android runtime acceptance after scan-fix2 APP0 flash:
- phone remained connected to FarmCart local SoftAP (no Internet indication expected)
- endpoint tested: `http://192.168.4.1/api/wifi/scan`
- response observed: `ok=true`
- `scanning=false`
- `scanState=complete`
- `count=1`
- discovered network: SSID `Ratthaphum`, RSSI `-70`, secure `true`, channel `7`

Interpretation:
- async Wi-Fi scan now starts and completes successfully
- prior `wifi_scan_failed / Unable to start Wi-Fi scan` defect is resolved on the physical ESP32-S3 controller
- SoftAP remained reachable through scan completion because the Android browser received the final completed response while still connected to the controller AP
- network discovery is functional and returns the expected 2.4 GHz SSID

Acceptance:
- SCANFIX2_FLASH=PASS
- SCANFIX2_RUNTIME=PASS
- WIFI_SCAN_ASYNC_START=PASS
- WIFI_SCAN_COMPLETE=PASS
- WIFI_NETWORK_DISCOVERY=PASS
- WIFI_SCANFIX_RUNTIME=PASS
- DEFECT_WIFI_SCAN_FAILED=CLOSED
- MAIN=UNTOUCHED

Safety / next:
- relay/pump/load power should remain disconnected until the broader hardware/load acceptance gate is explicitly resumed
- no further scan-fix flash is required
- continue from current candidate branch and latest continuation snapshot

## Next gate: Android rapid latest-state regression prepared — 2026-11-08

After Wi-Fi scan defect closure, next non-RTC acceptance gate is rapid relay latest-state behavior with external load still disconnected.

Existing source behavior:
- Flutter `DeviceStore` already coalesces rapid per-device requests through `_DeviceCommandState.latestDesiredState` and `_drainOutputCommands()`.
- while one command is active, later desired states overwrite the queued desired state; after the active request completes, the latest queued state is sent.
- automated tests in `flutter/test/stores/device_store_command_queue_test.dart` cover rapid ON->OFF and command-arrival-at-completion boundary.
- Smart Farm CI #14 PASS includes these tests.

Runtime client selection:
- Windows Realtek RTL8188EU path is independently unstable and must not be authoritative for rapid command acceptance.
- use current Android APK against SmartFarm AP.

Current APK:
- CI #14 artifact ID `13608036389`
- artifact ZIP digest `sha256:37baee1186501babba125ecbbb148036b05c8a16f16b958186fab3ae58352f60`
- extracted APK SHA256 `cb48246560af90fdc17f34d9145a0eff60a742ea36997a3270abb8744e79b930`

Safety:
- relay control wiring may remain connected
- external pump/valve/actuator/load power remains disconnected
- rapid test should end with all relays OFF
- Emergency Stop is NOT part of this gate because it writes `emergency` latch state to Preferences/NVS and requires separate explicit approval
- MAIN remains untouched

Current gates:
- WIFI_SCANFIX_RUNTIME=PASS
- RELAY_NOLOAD_HARDWARE=PASS
- RAPID_LATEST_STATE_RUNTIME=NOT_YET_TESTED
- EMERGENCY_STOP_RUNTIME=NOT_YET_ACCEPTED
- LOAD_ACCEPTANCE=BLOCKED

## Android provisioning to home Wi-Fi + post-provision relay control PASS — 2026-11-08

User performed an end-to-end Android app provisioning flow on the physical controller after scan-fix2 runtime PASS.

Observed sequence:
- Android app scanned available Wi-Fi networks successfully
- user selected the home Wi-Fi network and provisioned the controller
- provisioning completed
- controller data returned in the app after the network transition
- relay ON/OFF control from the app worked normally after provisioning

Acceptance interpretation:
- WIFI_SCAN_IN_APP=PASS
- WIFI_PROVISIONING_TO_HOME_STA=PASS
- POST_PROVISION_CONTROLLER_DATA_RETURN=PASS
- POST_PROVISION_RELAY_CONTROL=PASS
- LOCAL_TO_STA_TRANSITION=PASS
- prior `wifi_scan_failed` regression remains CLOSED

Important scope note:
- this does NOT yet close `RAPID_LATEST_STATE_RUNTIME` because the user reported normal ON/OFF operation, not the defined rapid ON->OFF->ON->OFF latest-intent sequence
- external pump/valve/actuator/load power remains disconnected until remaining no-load safety gates are closed
- Emergency Stop remains a separate NVS-affecting runtime gate
- MAIN=UNTOUCHED

## Android rapid latest-state runtime PASS — 2026-11-08

User completed the defined rapid relay latest-state runtime regression on the current Android app and physical FarmCart controller after home-Wi-Fi provisioning.

Defined sequence:
- rapid relay intent: ON -> OFF -> ON -> OFF
- final expected intent: OFF

User result: PASS.

Acceptance:
- `RAPID_LATEST_STATE_RUNTIME=PASS`
- final relay state followed the latest user intent (OFF)
- no stale earlier command reasserted after the sequence
- controller remained usable after the rapid sequence
- this runtime result aligns with existing `DeviceStore.latestDesiredState` coalescing logic and CI tests

Current non-RTC gate status:
- WIFI_SCANFIX_RUNTIME=PASS
- WIFI_PROVISIONING_TO_HOME_STA=PASS
- POST_PROVISION_RELAY_CONTROL=PASS
- RELAY_NOLOAD_HARDWARE=PASS
- RAPID_LATEST_STATE_RUNTIME=PASS
- EMERGENCY_STOP_RUNTIME=NOT_YET_ACCEPTED
- LOAD_ACCEPTANCE=BLOCKED
- MAIN=UNTOUCHED

## Emergency Stop no-load gate source preflight — 2026-11-08

Source preflight completed after RAPID_LATEST_STATE_RUNTIME=PASS.

Current emergency-stop implementation in `WiFiTransport.cpp`:
- `POST /api/emergency-stop` loops through all relay channels and calls `setManualRelay(channel, false, 0, ...)`
- `overrideSeconds=0` creates a non-expiring manual OFF override, preventing automation from reopening outputs
- after all relay-off operations succeed, firmware sets `_emergencyLatched=true`
- latch is persisted to Preferences namespace `sf-wifi` key `emergency=true`
- while latched, relay ON requests return HTTP 423 `emergency_latched`
- at boot, persisted emergency latch is loaded and all relay channels are again forced OFF
- `POST /api/emergency-release` clears all manual overrides and persists `emergency=false`

Safety/test implications:
- Emergency Stop no-load is an NVS-affecting mutation gate and requires explicit user approval before execution
- external pump/valve/actuator/load power must remain disconnected
- runtime acceptance should confirm all relays OFF, emergency latch active, ON command blocked while latched, and safe release behavior
- MAIN remains untouched

Status:
- EMERGENCY_STOP_SOURCE_PREFLIGHT=PASS
- EMERGENCY_STOP_RUNTIME=AWAITING_EXPLICIT_APPROVAL
- LOAD_ACCEPTANCE=BLOCKED

## Emergency Stop no-load runtime approval granted — 2026-11-08

User explicitly approved the Emergency Stop no-load runtime gate.

Approved mutation scope:
- `POST /api/emergency-stop` may force CH1..CH8 OFF
- emergency latch may be persisted to Preferences/NVS (`sf-wifi/emergency=true`)
- reboot while latched is allowed for persistence verification
- `POST /api/emergency-release` is approved at the end of the gate to clear overrides and persist `emergency=false`
- existing relay no-load/NVS relay-state approval remains applicable for a temporary no-load CH1 ON precondition if needed

Safety constraints:
- external pump / valve / actuator / load power MUST remain disconnected
- relay control board may remain connected
- final state after the gate must be CH1..CH8 OFF
- if release fails or latch state is uncertain, do not reconnect loads
- no flash, RTC write, Wi-Fi config write, or main merge

Acceptance sequence:
1. Verify emergency is currently not latched and all loads are disconnected.
2. Turn one no-load relay (prefer CH1) ON to create an observable active output.
3. Trigger Emergency Stop from Android app.
4. Require all relay LEDs/physical relays OFF and app/controller report emergency latched.
5. Attempt to turn a relay ON while latched; command must be rejected / relay must remain OFF.
6. Reboot controller once while latch remains active; after reconnect, emergency latch must still be active and all relays must remain OFF.
7. Release Emergency Stop from app.
8. Require emergency latch false, all relays still OFF, controller usable.

Approval status:
- `EMERGENCY_STOP_NOLOAD=APPROVED`
- `EMERGENCY_STOP_NVS_WRITE=APPROVED`
- `EMERGENCY_RELEASE_NVS_WRITE=APPROVED`
- `EMERGENCY_STOP_RUNTIME=NOT_YET_TESTED`
- `LOAD_ACCEPTANCE=BLOCKED`
- `MAIN=UNTOUCHED`

## E-stop physical safety PASS; Android switch-state sync defect found and fixed — 2026-11-08

Physical runtime observation after approved no-load E-stop test:
- user confirms relay physically turns OFF under Emergency Stop
- controller E-stop safety action is therefore physically effective for the observed relay
- however Android output switch remained visually ON while E-stop was active
- user had to toggle the app control OFF before it could be turned ON again after release

Root cause in app state:
- `OutputDeviceCard` switch value is `commandPending ? requestedOn : requestedOn || active`
- `DeviceStore.emergencyStopAllOutputs()` previously set only `isOn=false`
- stale `requestedOn=true` therefore kept the UI switch visually ON even though the physical relay and controller relay state were OFF
- `_syncFromController()` also previously reconciled only `isOn`, so the same stale requested state could survive reconnect/reboot while emergency latch remained active

Classification:
- this is NOT intended product behavior
- E-stop hardware/controller behavior = safety action PASS
- Android E-stop switch-state synchronization = DEFECT

App source fixes:
- `1ac3e20d8c7fdcfe0ece1e0a939c0fca425940d3`: clear requested output state immediately when E-stop is requested
- `c98065d99cb7960d95557acd5f712b2871777ea5`: while controller is emergency-latched, reconcile every output to `isOn=false`, `requestedOn=false`, `runtimeState=off`, clear waiting state/timer, and discard queued latest desired state
- no ESP32 firmware source changed for this UI fix

Regression tests:
- `64c85cb328233d9853cfcd43a3eea59726459991`: add tests for immediate E-stop stale requested-state clearing and reconnect while emergency latch is active
- Smart Farm CI #17 / run ID `42476190591` started for this head
- Flutter analyze/test = PASS at latest check
- full workflow/APK completion still pending at latest check

Current gate status:
- EMERGENCY_STOP_PHYSICAL_OFF=PASS
- EMERGENCY_STOP_CONTROLLER_LATCH_BEHAVIOR=PARTIALLY_ACCEPTED_FROM_RUNTIME
- EMERGENCY_STOP_APP_UI_SYNC=FIX_PREPARED_TEST_PASS
- EMERGENCY_STOP_UI_RUNTIME_RETEST=NOT_YET_TESTED
- ESP32_REFLASH_REQUIRED=NO
- MAIN=UNTOUCHED

## E-stop Android UI behavior correction completed in source — 2026-11-08

Follow-up UX correction after identifying stale requested-state behavior:
- desired design is now explicit: E-stop forces all output switches visually OFF and disables them while emergency latch is active; after release all outputs remain OFF and switches become enabled again
- user should NOT need to press OFF first after releasing E-stop

Source commits:
- `c73e4e2cc0dbad2c200d2a8b631c2cff170dd8d7`: add `emergencyLocked` to `OutputDeviceCard` and disable switch while latched
- `24fbabe33521290bfc59762f77c4d5011d4ab131`: pass `DeviceStore.emergencyLatched` into output controls
- `7db8340affe8964560004386966800eea8b9319b`: widget regression tests verify switch disabled during latch and re-enabled after release

Combined app fix also includes:
- stale `requestedOn` clearing on E-stop
- reconnect/reboot reconciliation while emergency latch persists
- queued latest desired state invalidation during emergency latch

Verification status:
- CI #20 / run ID `42476651695` started on head `7db8340affe8964560004386966800eea8b9319b`
- full CI result pending at latest check
- ESP32 reflash required: NO
- new Android APK required for runtime UI retest: YES
- MAIN untouched
