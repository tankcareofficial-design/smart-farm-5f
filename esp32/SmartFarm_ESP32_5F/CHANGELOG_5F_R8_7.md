# Smart Farm 5F R8.7

- ESP32 remains the single source of truth and continues automation without the app.
- Unified device intent: request ON/OFF is evaluated by ESP32 before relay execution.
- Runtime states: off, waiting, running, blocked, override, error.
- Conditions support AND/OR, day, exact time/time window, soil moisture, temperature and humidity.
- Snapshot API `/api/v3/snapshot` for reconnect and CYD preparation.
- Flutter displays cached snapshot immediately, then replaces it with ESP32 realtime state.
- Manual override is separate from normal request and emergency safety remains highest priority.
