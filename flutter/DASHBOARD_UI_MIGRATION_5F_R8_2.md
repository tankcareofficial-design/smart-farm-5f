# Dashboard UI Migration — 5F R8.2

## Source of truth
R8.2 uses the current R8.1 HOTFIX 2 architecture and data flow:

`SmartFarmController -> FarmState -> Dashboard widgets`

Release 0.7.6 is used only as a visual reference. Its `SimulationService`, simulated streams, fixed percentages, and legacy business logic are not copied.

## Presentation changes
- Compact product-style farm header
- Two-column environmental sensor cards
- Combined Battery/Solar presentation
- Relay activity summary and preview
- Farm Health remains calculated by `FarmHealthEngine`

## Data rules
- `null` means no data and is displayed explicitly.
- Numeric `0` remains a valid reading.
- Widgets never call HTTP directly.
- Sensor cards read Generic `SensorReading` values from `FarmState`.
- Battery/Solar placeholders remain visible while hardware is not installed.

## Architecture impact
Presentation layer only. Controller, state model, stores, API, firmware, protocol and other application pages remain unchanged.
