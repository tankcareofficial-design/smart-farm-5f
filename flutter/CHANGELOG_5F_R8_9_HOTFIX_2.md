# Smart Farm 5F R8.9 HOTFIX 2

## UI
- Restored the detailed, card-based Add Device wizard inspired by R8.7 UI Hardening.
- Kept schedule page, weekday selection, real installed sensor selection, and start/stop thresholds.
- Sensor mode remains unavailable when no sensor has been added.

## Controller clock
- Fetches `/api/v3/clock` during initial connection and every normal state refresh.
- Updates DeviceStore baseline so the clock continues ticking locally between polls.
- Shows `เวลาจากคอนโทรลเลอร์`, HH:mm:ss, Thai weekday, and DD/MM/YYYY.
- Supports both `dateTimeLocal` and component fields (`year`, `month`, `day`, `hour`, `minute`, `second`).

## Verification note
- ZIP structure and source-level checks completed.
- Flutter SDK is unavailable in this environment, so `flutter analyze` and compilation were not executed here.
