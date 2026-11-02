# Smart Farm Checkpoint 5F

## Live relay control

- Device switches now require a live ESP32 connection.
- Added per-device command-in-progress protection to prevent duplicate taps.
- Added optimistic UI with automatic rollback when ESP32 rejects or times out.
- Added offline/error banner on the Devices screen.
- Device state continues to synchronize from `/api/state` polling.
- Added client support for `GET /api/relays`.
- Dashboard, theme, navigation, saved-device format, and existing controller pairing flow are unchanged.

## Protocol

- `GET /api/device`
- `GET /api/state`
- `GET /api/relays`
- `POST /api/relay`

Relay channels are zero-based in the HTTP API and shown as one-based channels in the app.
