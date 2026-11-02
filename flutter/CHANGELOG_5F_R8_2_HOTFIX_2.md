# Smart Farm 5F R8.2 HOTFIX 2

## Fixed
- Fixed a runtime Dashboard layout exception caused by `Spacer` inside an unbounded-height sensor card.
- Sensor cards now use fixed vertical spacing rather than a flex child, allowing them to render safely inside `ListView -> Wrap`.
- Primary sensor cards remain visible even when no sensor is connected and continue to show `ไม่มีข้อมูล`.

## Unchanged
- FarmState, SmartFarmController, FarmHealthEngine, REST API, protocol and ESP32 firmware.
