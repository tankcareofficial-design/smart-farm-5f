# Smart Farm 5F R8.3 — Plug & Play Foundation

## Flutter
- Added `AccessoryManifest` for role-based accessories: ambient, soil, battery and solar.
- The app reads `accessories` from the existing `/api/device` and `/api/state` responses.
- Added a simple Dashboard card showing “พร้อมใช้งาน” or “ยังไม่ได้เสียบ”; technical names are hidden.
- Added Farm Readiness Engine 2.0 using weighted evidence, confidence and assessable factors.
- Optional accessories that are not installed do not reduce the score.
- Installed accessories without live data reduce readiness.
- Farm status is shown as words first: ready, partial, waiting, disconnected, emergency or check required.
- Kept FarmState as the single source of truth and preserved compatibility getters.
- Kept the 0.7.5a green Dashboard card language and removed visible INA226 wording from the main page.

## Compatibility
- Existing API version remains 2.
- Existing protocol version remains 1.
- Existing temperature, humidity and soilMoisture fields remain unchanged.
- Relay profile remains 8 channels.
