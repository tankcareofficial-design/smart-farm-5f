# Smart Farm ESP32 5F R8.3 — Plug & Play Foundation

- Added hardware profile `smart_farm_8ch_plugplay_v1`.
- Added accessory manifest schema 1 to `/api/device` and `/api/state`.
- Accessories are identified by port and role, not only by sensor model.
- Battery and solar can use identical measurement hardware while remaining separate roles.
- User-facing names are simple Thai names; electrical details remain internal.
- Missing SHT31, soil, battery and solar hardware reports `not_installed` and null metrics.
- No mock sensor values or mock hardware scan is enabled.
- Existing API 2, protocol 1 and metric keys remain backward compatible.
