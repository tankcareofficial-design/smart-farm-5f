# Smart Farm 5F R8.1 HOTFIX 2

## Fixed
- Removed fixed-height sensor-card layout that caused BOTTOM OVERFLOW.
- Farm Health no longer reports 100 when no live sensor data exists.
- Added an explicit unassessable/waiting state without removing existing health APIs.
- Updated tests for real-data health evaluation.

## Compatibility
- Existing FarmHealthResult constructor calls remain valid through the default `isAssessable` value.
- Existing temperature, humidity, soilMoisture getters remain unchanged.
- Protocol Version remains 1 and API Version remains 2.
