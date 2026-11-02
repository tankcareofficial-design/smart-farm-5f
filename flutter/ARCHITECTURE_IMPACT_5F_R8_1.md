# Architecture Impact — 5F R8.1

## Decision
Use additive stability changes only. Do not replace state management, HTTP routing, stores, controller coordination, or dashboard rendering responsibilities.

## Dependency impact
- No new Flutter package.
- No new ESP32 library.
- No circular dependency introduced.
- `FarmState` already depended on `SmartFarmController`; stable event data follows the same direction.

## Null safety
Nullable diagnostics remain optional. Existing constructors remain source compatible because new constructor fields are optional. Explicit clear flags remove ambiguity without changing old calls.

## Performance and memory
- Controller stores at most 100 structured log entries in parallel with the existing 100 text logs.
- Dashboard event conversion remains capped at 20 entries.
- No new network request and no new polling timer.
- Lists exposed by state remain unmodifiable.

## Rebuild impact
No new `notifyListeners()` call was added. Event IDs now remain stable across snapshots, reducing false identity changes in timeline widgets.

## Protocol impact
Protocol Version stays at 1. Firmware response changes are additive only.
