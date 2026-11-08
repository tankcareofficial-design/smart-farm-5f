# FarmCart SmartGrow — R8.14 Save / Safe Delete No-Load Acceptance

Date: 2026-11-08, Asia/Bangkok  
Branch: `candidate/r8.14-stability-1`  
Source HEAD at preparation: `ecab3667fe6bb2264cfa9a18dad45092032cc3c3`  
Status: **APPROVED, NOT YET RUN on physical controller**  
Run client: existing corrected Android app (E-Stop UI runtime PASS), not Windows RTL8188EU as sole authority.

## Approval and strict scope

User explicitly approved the proposed Save + Safe Delete no-load gate, including Preferences/NVS mutations **only for a new disposable test profile**, in the current conversation on 2026-11-08.

Allowed, once physical preconditions have been confirmed:
- Create and edit one disposable test device profile on an **unused** relay channel.
- Persist test-profile schedule/condition values using existing app/API.
- Momentarily switch that same test relay ON without external load power, then delete the test profile to verify Controller-initiated safe OFF.
- Inspect GET-only controller endpoints to collect evidence.

Not authorized by this approval: firmware flash, merge to main, RTC sync/write, Wi-Fi credential changes, factory reset, arbitrary changes/deletion of existing user profiles, connection to real pump/valve/actuator load power, deliberate power-cycle or reboot for retention testing, or R9 Remote.

## Hardware and identity preflight (mandatory; stop on any mismatch)

1. Physically disconnect **external power to pump, valve, actuator, and every real load**. Relay module/control-side power may remain connected. Do not infer disconnection from app UI.
2. Identify only the intended FarmCart ESP32-S3 N16R8. Known USB MAC `14:c1:9f:50:b9:64`. Do **not** operate other attached ESP32 boards.
3. From Android on the actual local network, use the controller IP shown in the app. With SoftAP this is commonly `192.168.4.1`; after provisioning, the station IP may differ. Open `GET /api/device` and verify:
   - `deviceId=sf-64B9509FC114`
   - `firmwareVersion=0.8.0-5f-r8.14-stability-1`
   - `hardwareProfile=smart_farm_8ch_v1`
   - `relayCount=8`
   - `emergencyLatched=false`
4. GET `/api/relays` and `/api/v3/snapshot`; confirm every channel is OFF, no unaccounted active automation, and choose a relay channel with **no existing assigned profile**. If no channel is unused, **stop**. Do not overwrite an existing profile.
5. Do not proceed if controller connection is unstable, identity is uncertain, loads are still powered, or E-Stop is latched.
6. Note the chosen free channel, actual Android controller URL, and baseline rules/revision. Do not log Wi-Fi credentials.

## A — Edit / Save schedule (NO RTC execution gate)

1. In Android app > Devices, add **one new temporary test device**, clearly named `FarmCart QA TEMP`, on the previously confirmed free channel; mode Manual. Confirm the app and `/api/v3/snapshot` show this new device. No other device is modified.
2. Edit that test device to Schedule: Monday–Sunday, 06:00–06:15 (any valid non-equal 15-minute window may be used only if it is not near the current RTC time). Press Save **once** and allow the save response to finish.
3. Reopen that same device; confirm Schedule mode, selected days, start/end times, and channel survive closing/reopening the dialog.
4. GET `/api/v3/snapshot`. Verify matching `deviceId`, `controlMode=schedule`, `trigger.schedule.enabled=true`, window times, and selected day mask. Confirm no unexpected relay ON.
5. **PASS A** requires app persistence and ESP32-snapshot persistence. Do not use RTC-dependent schedule execution as proof; RTC retention remains unresolved. If the clock is currently valid and the selected window might start, STOP and arrange a safe out-of-window schedule before saving.

## B — Edit / Save sensor condition (only if supported by actual installed sensor)

1. Check for an enabled, registered sensor inside the app. If no suitable sensor exists, record `B=BLOCKED_NO_ENABLED_SENSOR` and do not invent/add sensor readings.
2. On the same disposable device, switch to Automatic and configure a non-triggering condition using that sensor's actual metric and an appropriate threshold range. All real load power remains physically disconnected.
3. Save once, reopen, and compare sensor ID, comparison operator, start and stop thresholds.
4. GET `/api/v3/snapshot`; verify the matching `conditions` fields and `controlMode=automatic`. Confirm the relay remains OFF.
5. **PASS B** requires app persistence plus controller-snapshot persistence; no autonomous irrigation/cooling cycle is accepted here.

## C — Delete ON device (no load, safety-critical)

1. Edit the disposable test device back to Manual, Save, and verify its profile is still assigned to the chosen channel.
2. Confirm again that the external pump/valve/actuator/load power is still disconnected and no other channel is ON.
3. In Android, turn **only the temporary test relay** ON. Confirm the physical relay LED/click and `GET /api/relays` show ON for the selected channel.
4. Select Delete on **FarmCart QA TEMP** while its relay is ON and confirm the deletion once. **Do not send another relay command concurrently.**
5. Immediately verify the same physical relay turns OFF; confirm `GET /api/relays` reports OFF.
6. GET `/api/v3/snapshot`; confirm its rule/deviceId is absent and other profiles remain unchanged. Confirm the app no longer lists the test device.
7. Wait at least 5 seconds and query `/api/relays` and `/api/v3/snapshot` again to verify the relay stays OFF and the deleted rule remains absent.
8. **PASS C** requires physical OFF before the app profile disappears, controller relay OFF, rule absent, local UI absent, and OFF/no-rule stable after wait.
9. **Reboot/Power-loss ghost restoration is a separate gate** and is not tested under this approval.

## Failure / abort / containment

- If Save fails or times out, do **not** repeat an uncertain POST blindly; read back `/api/v3/snapshot` to establish whether it was persisted.
- If Delete fails and the relay is still ON, use the existing Android control to set that test relay OFF. Verify physical OFF before any other action. Do not remove or reassign other devices.
- If OFF cannot be verified, leave all external load power physically disconnected and report `SAFE_DELETE=FAIL_UNVERIFIED_OFF`; do not retry or reboot to clear it.
- If Android loses connectivity, do not infer OFF from a stale switch; inspect actual relay LED, reconnect, and verify GET responses.
- Do **not** use Emergency Stop or Release as an automatic cleanup because these mutate the separate emergency latch; the earlier E-Stop gate already passed and is outside this approval.
- A Windows RTL8188EU timeout by itself is not ESP32 safety-failure evidence. Use Android as the authoritative acceptance client.

## Evidence to return

Record: date/time Asia/Bangkok, active GitHub commit, physical controller ID, selected CH, external load disconnected confirmation, Android client version if visible, `/api/device` identity, before/after `/api/v3/snapshot` rules (do not include secrets), before/after `/api/relays` states, actual physical LED/click observation, Save/reopen screenshots, unexpected errors, and final all-relays-OFF confirmation.

Gate status at preparation:
```text
NOLOAD_SAVE_DELETE_APPROVAL=GRANTED_20261108
SAVE_SCHEDULE_APP_RUNTIME=NOT_TESTED
SAVE_CONDITION_APP_RUNTIME=NOT_TESTED
DELETE_ON_DEVICE_PHYSICAL_OFF=NOT_TESTED
DELETE_ON_DEVICE_SNAPSHOT_REMOVED=NOT_TESTED
DELETE_ON_DEVICE_POSTREBOOT_GHOST_CHECK=NOT_AUTHORIZED
RTC_RETENTION_AFTER_POWER_LOSS=FAIL_DEFERRED
REAL_LOAD_ACCEPTANCE=BLOCKED
MAIN=UNTOUCHED
```

**Never claim physical/runtime PASS from GitHub CI or unit-test mocks.** Record actual acceptance outcomes in a continuation Handoff after the Android and controller test.

---

## 2026-11-09 continuation — repeatable GET-only Schedule / Condition readback

Current accepted gate: **Safe Delete no-load physical ON -> immediate OFF, profile absent in Android, relay staying OFF, and subsequent controller HTTP GET with zero ON relays and no QA TEMP name among five remaining rules.** Evidence revision `669` recorded in Handoff section 24. No reboot retention claim.

Next *not-yet-accepted* gate: Save Schedule and Save Condition through the **existing Android interface**, verifying persistence on the actual ESP32. No firmware changes or re-running Safe Delete ON test needed.

Read-only reproducible checker, authored on candidate branch:
`tools/windows/VERIFY_FARMCART_R814_PROFILE_SAVE_READONLY.ps1`.
Modes: `-Stage Preflight`, `-Stage Schedule`, `-Stage Condition`, `-Stage Final`. Default endpoint `http://192.168.4.1`. If using the home LAN, pass the actual station IP from the app. Checker invokes only `GET /api/device`, `GET /api/relays`, and `GET /api/v3/snapshot`; expects exact FarmCart ID `sf-64B9509FC114` and firmware `0.8.0-5f-r8.14-stability-1`. It fails closed if any relay is ON, E-Stop latched, identity mismatched, or there are duplicate test-profile names. It prints occupied/free channel numbers as **1-based** (Flutter UI channels 1-8; API rule relayChannel 0-7).

Operator acceptance steps:
1. **Physically disconnect pump/valve/actuator load power.** Ensure no physical loads are energized.
2. Run `-Stage Preflight`. It must report `PREFLIGHT=PASS`, `RELAY_ON_COUNT=0`, and a nonempty `FREE_CHANNELS` list. If it warns of an active test window on the Controller clock, STOP and choose a different non-active schedule window before saving.
3. In Android create only one **new temporary device** named `FarmCart QA TEMP` on an actually unused channel; Manual first. **Do not edit or reassign the five existing devices.** Check that its relay stays OFF. Edit it to `Schedule`: daily 06:00-06:15 unless that interval is now active on the Controller clock. Save once. Reopen the form and confirm exact values.
4. Run `-Stage Schedule -StartTime 06:00 -EndTime 06:15` (or pass the actual safely chosen window). `SCHEDULE_SNAPSHOT_PERSISTENCE=PASS` plus Android reopen evidence are both required. If Save returns an uncertain error, inspect snapshot before retrying.
5. If an **actual configured sensor** is exposed in the Android device wizard, edit the same disposable device to `Automatic`, choose its supported sensor and configure a condition that is **not triggering**. Save once, reopen, and verify threshold/operator/stop threshold. Run `-Stage Condition`; cross-check echoed values with Android. If no actual usable sensor exists, record `CONDITION=BLOCKED_NO_SENSOR`; **do not fabricate data**.
6. Finally delete this disposable profile **while its relay is OFF** using Android. Run `-Stage Final` and confirm no test profile by name and all relays OFF. Deletion with relay ON already has its own PASS; don't repeat needlessly.
7. Send the read-only output and Android observations so Handoff can record independent Schedule/Condition PASS or an accurate blocked/failure state.

Limits: Checker is not a raw NVS dump; it reads Controller snapshot representing loaded stored rules. It cannot independently verify Android UI reopen, condition actually causing a real action, RTC execution, power-cycle restoration, or physical relay LED. **Do not permit real load, power cycle, RTC sync, flash, Wi-Fi re-provisioning, or main merge** under this gate.