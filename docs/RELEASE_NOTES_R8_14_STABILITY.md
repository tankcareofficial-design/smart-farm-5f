# R8.14 Stability 1 — RTC & Link Health

Candidate based on `main` R8.13 Rebase 3.

## Changes

- DS3231 transport failures are tolerated for up to 2 consecutive reads when a verified clock already exists.
- The third consecutive RTC transport failure invalidates the clock and keeps schedule execution fail-safe.
- RTC time/status registers are committed as one coherent snapshot.
- DS3231 temperature-register failure no longer invalidates scheduler time.
- Flutter no longer writes phone time automatically when RTC health degrades; sync remains an explicit user action.
- Controller reachability is separated from clock and snapshot health.
- If `/api/state` fails, Flutter probes `/api/device` before counting a link failure.
- Three consecutive reachability failures are still required before Offline.
- Relay/emergency command failure no longer immediately marks the controller Offline.
- Device-screen Online presentation follows controller reachability, not RTC validity.

## Versions

- ESP32: `0.8.0-5f-r8.14-stability-1`
- Flutter: `0.8.14+137`

## Gates not yet claimed

- Flutter analyze/test PASS
- ESP32 compile PASS
- Hardware acceptance PASS

These must be verified by CI or a developer machine before merge.
