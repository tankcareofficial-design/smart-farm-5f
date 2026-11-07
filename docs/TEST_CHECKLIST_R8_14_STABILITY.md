# R8.14 Stability 1 — Acceptance Checklist

## Static / build

- [x] `dart format --output=none lib test` audit executed in CI (non-blocking; pre-existing baseline format drift is not a stability gate)
- [x] `flutter analyze` = 0 issues
- [x] `flutter test` = PASS
- [x] ESP32-S3 N16R8 Arduino compile = PASS (`FlashMode=qio,FlashSize=16M,PartitionScheme=app3M_fat9M_16MB,PSRAM=opi`; CI #11)

## Connection

- [ ] Connect to `SmartFarm-xxxxxx` with one Connect action.
- [ ] Clock endpoint fails once while controller is reachable: stays Online.
- [ ] Snapshot endpoint fails once while controller is reachable: stays Online.
- [ ] `/api/state` fails but `/api/device` works: stays Online and reports degradation.
- [ ] Three consecutive reachability failures: becomes Offline.
- [ ] One successful reachability cycle: returns Online immediately.

## RTC / DS3231

- [ ] One I2C transport miss does not invalidate a previously valid RTC.
- [ ] Two consecutive transport misses keep the verified time with `quality=degraded`.
- [ ] Third consecutive transport miss invalidates RTC and blocks schedule.
- [ ] Next coherent RTC read restores `valid=true` and resets `readFailures`.
- [ ] `lost_power` remains invalid until explicit sync.
- [ ] No automatic phone-time write occurs from transient RTC failure.
- [ ] Observe RTC + Online state continuously for at least 10 minutes.

## Regression

- [ ] Manual relay ON/OFF still works.
- [ ] Rapid relay commands finish at the latest requested state.
- [ ] Edit schedule/condition Save still works.
- [ ] Delete an ON device: relay is OFF before profile disappears.
