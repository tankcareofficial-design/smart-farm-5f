# Smart Farm 5F R8.9

- Manual and sensor-only devices no longer require a valid DS3231 clock.
- Schedule-enabled devices still fail safely with `clock_invalid`.
- Added API v3 clock aliases.
- Flutter device wizard only offers sensors actually added and enabled.
- Removed fake/default sensor IDs.
- Added Thai, elder-friendly start/stop rule flow.
- Added start/stop threshold data for hysteresis-ready migration.
