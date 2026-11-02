# SmartFarm Checkpoint 5F Revision 2

## Emergency stop
- Emergency stop now sends a real command to ESP32 instead of changing only Flutter state.
- ESP32 turns every relay OFF and creates a permanent manual override (`overrideSeconds = 0`).
- Automation cannot turn relays back ON while the emergency latch is active.
- Emergency latch is saved in NVS and remains active after restart.
- Added emergency release command from the same dashboard action.

## Standalone-style Wi-Fi provisioning
1. Open Settings > Controller.
2. Connect the phone to `SmartFarm-xxxxxx` using the password printed on the box.
3. Return to the app and press Connect.
4. ESP32 scans nearby Wi-Fi networks and returns the list to Flutter.
5. Enter the selected Wi-Fi name/password; ESP32 saves it and reconnects automatically.

The ESP32 AP remains available at `192.168.4.1` while STA mode connects to the farm/router Wi-Fi.
