# FarmCart SmartGrow — Continuation Snapshot 2026-11-08

## Working policy
- Continue from latest verified state; do not restart or use stale baseline.
- GitHub Handoff/source/commit/runtime evidence are source of truth.
- Do not claim PASS without evidence; distinguish source/build/flash/runtime/hardware.
- main remains untouched.
- Record material actions/results in GitHub Handoff.
- Relay/pump/load power stays disconnected during flash/runtime acceptance until explicitly cleared.
- Project flash/diagnostic baud lock: 115200 only.
- Never blindly choose COM numbers; verify physical identity by MAC/USB serial.

## Repository / branch
- Repo: tankcareofficial-design/smart-farm-5f
- Branch: candidate/r8.14-stability-1
- Main stable baseline remains untouched.
- Canonical Handoff: docs/handoff/FARMCART_SMARTGROW_CONTINUATION_HANDOFF_R8_14_20261107.md

## Physical FarmCart controller
- ESP32-S3 N16R8
- MAC: 14:c1:9f:50:b9:64
- Flash: 16MB
- PSRAM: 8MB
- Native USB Serial/JTAG identifies as Espressif 303A:1001 and MAC-derived USB serial 14:C1:9F:50:B9:64
- CH343 UART path also exists and has previously enumerated as COM7
- When multiple ESP32-S3 boards are connected, Windows COM/USB re-enumeration becomes confusing; test FarmCart with other ESP32 boards disconnected when practical.

## Proven flash transport
Stable recovery/write path proven on this physical board:
- Native USB Serial/JTAG
- commonly COM5 when enumerated
- 115200
- esptool 5.3.1
- --before usb-reset
- --after no-reset
- --no-stub
- --no-compress for write
- APP0 write only at 0x10000
- no erase-all
- do not touch NVS, OTADATA, partition table, bootloader

## First scan-fix flash
First async scan fix baseline:
- source SHA: 30ab9bbadcc601b4978d416efb985af84ba9145e
- firmware version remained 0.8.0-5f-r8.14-stability-1
- APP0 recovery/write eventually PASS through native USB ROM path
- app binary SHA256 from successful write: 44a6acaf638003458ee5272f339b15edf64ffc0e5a6fa26d38f1002e8f52402f
- APP bytes: 1,058,368
- esptool completed 100% and reported Hash of data verified.
- NVS/OTADATA/partition table/bootloader preserved.

## Runtime after first scan-fix
- SmartFarm-9FC114 AP visible.
- Android direct /api/device PASS.
- Runtime firmware: 0.8.0-5f-r8.14-stability-1
- Device ID: sf-64B9509FC114
- AP IP: 192.168.4.1
- hardwareProfile: smart_farm_8ch_v1
- stationConnected=false
- Windows Realtek RTL8188EU path is independently unstable and should NOT be used as authoritative scan acceptance client.
- Windows diagnostic after flash: ping 13/30 PASS, curl root 6/20 PASS despite 100% reported signal; classified AP_OR_RF_LINK_UNSTABLE.
- Android direct client is preferred for scan acceptance.

## Android-proven remaining scan defect
Android browser:
- GET /api/device => PASS
- GET /api/wifi/scan => {"ok":false,"error":"wifi_scan_failed","message":"Unable to start Wi-Fi scan."}
This proved firmware scan start failure independent of Windows client instability.

## Root cause / second fix
Root cause class:
- STA may remain internally in CONNECTING state after failed connection attempt.
- ESP-IDF refuses esp_wifi_scan_start() with ESP_ERR_WIFI_STATE while STA is connecting.
- Arduino maps this to WIFI_SCAN_FAILED (-2).

Second source correction:
- source commit: ed7168c8b9b318c684412ad9e0baa6291ce1534d
- file: esp32/SmartFarm_ESP32_5F/WiFiTransport.cpp
- after connectStation() timeout/failure: WiFi.disconnect(false,false); delay(100)
- if async scan start still fails and WiFi.status()!=WL_CONNECTED: one non-erasing disconnect + delay + retry
- established STA connection is not deliberately disconnected by scan recovery
- SoftAP remains enabled
- no NVS/credential erase added

## CI for second fix
Smart Farm CI #14:
- run ID 42456112148
- head SHA ed7168c8b9b318c684412ad9e0baa6291ce1534d
- overall conclusion SUCCESS
- ESP32-S3 N16R8 compile PASS
- Flutter analyze/test PASS
- Android demo APK PASS

## Scan-fix2 approved flash
User explicitly approved scan-fix2 flash on 2026-11-08.

Runner:
tools/windows/FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd

Runner/tool commit:
74ee41b1d4e58d22c63582d328c2032eebbabd88

Approval token:
FLASH_R814_SCANFIX2_STA_STATE

Approved scope:
- source lock ed7168c8b9b318c684412ad9e0baa6291ce1534d
- delta baseline 30ab9bbadcc601b4978d416efb985af84ba9145e
- APP0 only at 0x10000
- 115200 only
- native USB
- usb-reset
- no-stub
- no-compress
- NVS untouched
- OTADATA untouched
- partition table untouched
- bootloader untouched
- erase-all NO
- relay/pump/load power disconnected
- main untouched

Current status at snapshot creation:
- SCANFIX2_SOURCE=READY
- SCANFIX2_CI=PASS
- SCANFIX2_FLASH=APPROVED
- SCANFIX2_FLASH_EXECUTION=NOT_YET_PERFORMED

## Next exact action
On Windows, with only FarmCart ESP32 connected if practical and relay/pump/load power disconnected:

cd /d D:\FarmCart\smart-farm-5f
git fetch --prune origin
git pull --ff-only origin candidate/r8.14-stability-1
call tools\windows\FLASH_FARMCART_R814_SCANFIX2_STA_STATE_APP0_NATIVE_USB_APPROVAL_GATED.cmd COM5 FLASH_R814_SCANFIX2_STA_STATE

Return the complete output before reset/runtime testing.

After successful APP0 flash + hash verification:
1. press EN/RST once
2. connect Android to SmartFarm-9FC114
3. verify /api/device
4. call /api/wifi/scan
5. expected first state may be scanning=true/scanState=scanning
6. refresh/poll until scanning=false/scanState=complete and inspect networks
7. AP must remain reachable throughout

## Latest update: scan-fix2 APP0 flash PASS
- Approved scan-fix2 source: `ed7168c8b9b318c684412ad9e0baa6291ce1534d`
- Physical flash executed successfully on COM5 native USB.
- `APP0_RECOVERY_WRITE=PASS`
- APP SHA256: `479002f5592a621723181b03b82f8677a4b8a7571b2bbe654801fc77b156edb8`
- APP bytes: `1058448`
- evidence dir: `D:\FarmCart\smart-farm-5f\tools\windows\\..\..\..\backups\farmcart_r814_scanfix2_sta_state_COM5_20261108_140539`
- NVS / OTADATA / partition table / bootloader preserved.
- erase-all NO.
- Do NOT reflash.
- Runtime scan acceptance remains pending.

### Immediate next action
1. Press EN/RST exactly once; do not press BOOT.
2. Keep relay/pump/load power disconnected.
3. Connect Android to `SmartFarm-9FC114` using `smartfarm123`.
4. Verify `http://192.168.4.1/api/device`.
5. Test `http://192.168.4.1/api/wifi/scan`.
6. PASS requires async transition `scanning` -> `complete`, returned networks, and AP remains reachable.

Current: `SCANFIX2_FLASH=PASS`, `WIFI_SCANFIX_RUNTIME=NOT_YET_PASS`, `MAIN=UNTOUCHED`.

## Latest update: Wi-Fi scan defect closed
- Scan-fix2 source `ed7168c8b9b318c684412ad9e0baa6291ce1534d` is physically flashed and runtime accepted.
- APP0 flash PASS, SHA256 `479002f5592a621723181b03b82f8677a4b8a7571b2bbe654801fc77b156edb8`, 1,058,448 bytes.
- Android `GET http://192.168.4.1/api/wifi/scan` returned:
  - `ok=true`
  - `scanning=false`
  - `scanState=complete`
  - `count=1`
  - network `Ratthaphum`, RSSI -70, secure true, channel 7
- This closes the prior physical-runtime defect `wifi_scan_failed / Unable to start Wi-Fi scan`.
- `WIFI_SCANFIX_RUNTIME=PASS`
- `DEFECT_WIFI_SCAN_FAILED=CLOSED`
- No more scan-fix flash is required.
- Windows Realtek RTL8188EU path remains independently unstable and should not be used as authoritative controller/AP acceptance client.
- MAIN remains untouched.
- Keep relay/pump/load disconnected until broader hardware/load acceptance resumes.

## Next gate prepared: Android rapid latest-state regression
- Relay no-load API/physical gate was already PASS for CH1-CH8; all final states OFF.
- Remaining non-RTC blocker before load acceptance includes rapid-command latest-state runtime regression.
- Windows RTL8188EU AP path is unreliable and must not be authoritative for this gate.
- Flutter `DeviceStore` already implements per-device command coalescing via `_DeviceCommandState.latestDesiredState` and `_drainOutputCommands()`.
- Existing automated tests `flutter/test/stores/device_store_command_queue_test.dart` cover rapid ON->OFF and boundary-arrival commands; CI #14 PASS includes these tests.
- Current Android APK artifact from CI #14: artifact ID `13608036389`, ZIP digest `sha256:37baee1186501babba125ecbbb148036b05c8a16f16b958186fab3ae58352f60`.
- Extracted APK SHA256: `cb48246560af90fdc17f34d9145a0eff60a742ea36997a3270abb8744e79b930`.
- Runtime rapid test must be no-load only; relay/pump/valve/actuator external power remains disconnected.
- Emergency Stop is a separate gate because `/api/emergency-stop` writes the emergency latch to Preferences/NVS; do not combine it with rapid test without explicit approval.
- MAIN remains untouched.

## Latest update: home Wi-Fi provisioning and relay control PASS
- Android app Wi-Fi scan PASS on physical controller.
- User selected home Wi-Fi and completed controller provisioning.
- Controller data returned in the app after transition from SmartFarm AP provisioning to home Wi-Fi station operation.
- Normal relay ON/OFF from the app worked after provisioning.
- `WIFI_PROVISIONING_TO_HOME_STA=PASS`
- `POST_PROVISION_CONTROLLER_DATA_RETURN=PASS`
- `POST_PROVISION_RELAY_CONTROL=PASS`
- `RAPID_LATEST_STATE_RUNTIME=NOT_YET_TESTED` (normal ON/OFF does not close the defined rapid sequence gate).
- Emergency Stop remains separate because it writes the emergency latch to NVS.
- MAIN remains untouched.
