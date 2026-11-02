# Smart Farm+ 5F R8.7 UI HARDENING HOTFIX

## Controller screen
- Removed the obsolete visible message `ยังไม่เปิดใช้งานใน 5F R4` / `Not enabled in 5F R4`.
- Replaced it with current local-network and ESP32-authoritative architecture guidance.
- Localized the diagnostics heading, protocol, failure count, client count, and event log title.

## Theme hardening
- Removed the nested ad-hoc theme from the controller pairing flow.
- Pairing now inherits the application `SFTheme`, so light, dark, and system modes stay consistent.
- `SFCard` now uses the active `ColorScheme` surface in both light and dark modes instead of forcing white.
- Automation readiness colors and controller status colors now derive from the active theme.

## Localization and roadmap wording
- Reworded Cloud/account items as future services and a remote-access roadmap.
- Clarified that current automation continues locally while the app is offline.
- Removed visible legacy version references from runtime UI.

## Dead-code cleanup
Removed 12 Dart files that were unreachable from `main.dart`, including the duplicate legacy sensor screen, old simulation/data-source stack, old relay widgets, and unused theme/widget files.

## Version metadata
- App version: `0.8.41+61`
- Edition: `5F R8.7 UI Hardening Hotfix`
