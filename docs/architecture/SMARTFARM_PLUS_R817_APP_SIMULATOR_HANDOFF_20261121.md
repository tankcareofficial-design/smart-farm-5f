# FarmCart SmartGrow / Smartfarm+ — R8.17 App-Only Continuation
Date: 2026-11-21 (ICT)
Status: Candidate; source/CI pending verification. DO NOT claim physical control acceptance.

## Branch ancestry / protected baselines
- main: `609abfe22c14d42e27639909efcd9ffe040144a0` — untouched.
- Stable R8.14: `afb42353e81278a30eb3d1b5ab7dd3b2f9d22af8`.
- Crop recommendations R8.15: `6d53695d6c61694632085cf955e65e6490f0c136`.
- Irrigation zones R8.16: `db58d5d0f1fa20872169bb28c95952972b431048`, CI #73 SUCCESS (Flutter analyze/test, ESP32 compile, Android debug APK).
- This R8.17 branch derives from exact R8.16 HEAD; no merge to main, no ESP32, NVS, RTC, Wi-Fi provisioning, controller commands, or hardware flash.

## User-approved requirements
- Smartfarm+ app is a **general-purpose** 8-channel IoT device controller; Manual lights/fans/pumps never require a crop.
- Optional crop guides are called **ชุดค่าแนะนำการปลูก**. User can customize fields, with `(มีการปรับแต่ง)` label, and reset recommendations.
- Optional irrigation starts with ONE real water spinach plot, can expand later to two or more independently valved zones; two zones can have the same crop.
- Three architectures: direct pump for one zone; valve-only from an already-pressurized source; shared pump plus one NC valve per independently controlled zone. Never treat direct-split zone 1 and valve-only zone 2 as truly independent.
- Consumer UI uses **กล่องควบคุม**, not ESP32. Offline controller disallows device/sensor mutations; phone-local planning remains available.
- Future Cloudflare Workers + Supabase Auth/Postgres/RLS, NOT implemented in this branch.

## R8.17 scope: explain the decision logic without false device control
- `flutter/lib/models/irrigation_simulation.dart`: pure simulated hysteresis (illustrative 45% start / 55% stop, NOT a real crop-specific recommendation); shared pump selects one zone at a time; previous active demand retains its turn until stop; missing/invalid reading or simulated emergency stop fail closed. Valve-only never requests a pump.
- `flutter/lib/screens/irrigation_simulation_screen.dart`: offline simulation screen with per-zone mock-moisture sliders, try-dry scenario, emergency-stop simulation, status labels; no relay, Wi-Fi, backend, GPIO or controller imports.
- `flutter/lib/screens/irrigation_zones_screen.dart`: simulation entry from existing planner, custom names for zones, and displaying locally customized crop labels and water guidance, without changing crop draft storage.
- Automated tests: `flutter/test/models/irrigation_simulation_test.dart` and `flutter/test/screens/irrigation_simulation_screen_test.dart`.
- Current R8.16 planner remains the source of the saved phone-only plan under key `irrigation_zone_plan_preview_v1`. Simulation state is *not* persisted, and cannot be confused with actual sensor readings.
- ALL real device control buttons in crop/zone feature remain disabled until separate safety acceptance.

## Next work after source/CI gate
1. User may test zone planner + simulator in a debug APK, initially just one water-spinach zone. Test two zones with shared pump, emergency simulation and customized crop label.
2. Begin real sensor procurement/ADC electrical verification, media calibration and per-zone sensor mapping. Current firmware has `SOIL_SENSOR_ADC_PIN=-1` (soil sensor disabled).
3. Design new controller-local guarded state machine with safe valve/pump sequencing, moisture reading freshness, pulse+soak, cooldown, max runtime, lost sensor fail-off, E-Stop latch, NO auto restart after reboot, owner/channel reservation, and physical acknowledgements. Review R8.14 RTC retention and relay restore state before real load.
4. Host simulation -> Flutter source/unit/widget gates -> ESP32 compile -> no-load device acceptance -> explicitly approved pump/valve water test. Source/CI tests are NEVER actual hardware PASS.
5. Avoid wasting GitHub Actions minutes: batch changes into a single candidate CI run; only issue APK once exact HEAD passes. Do not overwrite old installed phone data to install debug APK.

## Warnings
- 45/55% is ONLY simulated Hysteresis; real soil moisture percentages require calibrated sensors and substrate, not web-retrieved arbitrary crop numbers.
- `Smartfarm+` is the canonical product name, irrespective of any historic screenshots showing Smart Farm+.
