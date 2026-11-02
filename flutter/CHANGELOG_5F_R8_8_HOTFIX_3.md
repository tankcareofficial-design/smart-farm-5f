# Smart Farm 5F R8.8 HOTFIX 3

- Ensures `DeviceStore.estimatedControllerDateTime` is included in the release source.
- Keeps the ESP32/DS clock baseline and local real-time estimation in `DeviceStore`.
- Adds braces to the clock validity guard.
- Resolves the `undefined_getter` diagnostic in `devices_screen.dart` when the complete release is extracted.

Important: replace both `lib/stores/device_store.dart` and `lib/screens/devices_screen.dart`; do not copy only the screen file over an older project.
