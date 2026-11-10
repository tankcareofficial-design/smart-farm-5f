# Smartfarm+ R8.16 — Optional Irrigation Zones / Continuation Handoff
Date: 2026-11-10 (ICT)
Status: phone-only preview, not approved for live Controller integration

## Locked user intent
The user is building a real-world demonstration and may plant only water spinach (ผักบุ้งจีน) in one zone. The software must nonetheless be useful to other users who may later want two or more independent zones, or only a valve without any pump. It must not require all eight relay channels, and general-purpose Manual devices (lamps/fans/etc.) remain separate and usable without a crop profile.

## Optional layouts
1. Direct pump, one irrigation zone; requires one pump channel only and does not require a solenoid valve.
2. Valves only: uses an existing pressure source. Each zone requires its own valve; no pump relay is allocated. Can use up to 8 relay channels if all are free.
3. Shared pump + one separately controlled normally-closed valve per zone; one pump channel + up to 7 valve channels.

WARNING: Pump-direct Zone 1 and valved Zone 2 on the same tee cannot independently turn Zone 1 off while Zone 2 sprays. Do not silently treat this as two independent zones. Shared-pump systems require a per-zone valve and validated pressure/flow. Zone demands should be arbitrated sequentially unless water system capacity is verified.

## Delivered candidate source
- Model: flutter/lib/models/irrigation_zone_plan.dart
- Local repository: flutter/lib/services/irrigation_zone_repository.dart
- Flutter UX: flutter/lib/screens/irrigation_zones_screen.dart
- Dashboard entry: flutter/lib/screens/dashboard_screen.dart
- Pure host tests: flutter/test/models/irrigation_zone_plan_test.dart
- Widget UX tests: flutter/test/screens/irrigation_zones_screen_test.dart

First use starts with one water-spinach zone (or an already selected crop reference), a direct pump layout and no allocated channel. Users can choose a different crop, choose a different layout, add/remove zones, and indicate Manual, future Schedule, or future soil-moisture control. A second zone automatically changes a direct-pump layout proposal to a shared-pump valve proposal. The user need not acquire or declare uninstalled accessories.

Inputs are PLAN ONLY, saved in a new phone-local preferences key. They do not modify previous crop drafts, existing DeviceStore profiles, firmware, NVS or relay state. The Apply/Start Automation button remains disabled. A channel shown in this screen is a proposal, NOT a reservation or a Controller write.

## Validation and real-hardware gates
- Check CH1–CH8 bounds, uniqueness across pump and valve channels, and conflict with existing general device channels.
- Require separate valves for independent zones when a pump is shared.
- Soil-based automation requires an assigned real sensor, media-specific calibration, separately validated start/stop threshold band, measurement freshness, and failure handling.
- Scheduled operation requires a verified clock and schedule.
- Actual controller integration additionally needs explicit device ownership, current Controller state readback and acknowledgments, state-machine arbitration, valve-before-pump sequencing and pump-before-last-valve shutdown, max-runtime and pump cooldown, emergency stop, no unintended restart after reboot, flow/pressure protection as available, and safe no-load acceptance.
- Preview moisture logic is deterministic hysteresis only, not actuating hardware. Neither AI nor cloud should independently issue relay ON commands.
- Offline phone plan is editable without Internet or Controller; actual device writes remain blocked if Controller is offline.
- Do not merge to main, flash/reboot hardware or deploy cloud resources without explicit approval.

## Next acceptance
1. Flutter analyze + unit/widget tests and APK CI for exact R8.16 candidate commit.
2. User tests UX with first-use single zone and optional second zone while offline.
3. Read-only controller binding study and source audit before proposing firmware control integration.
4. Physical acceptance is NOT YET PASS.
