# R8.11 Flutter test
1. flutter clean
2. flutter pub get
3. dart format lib
4. flutter analyze
5. flutter test
6. Connect to controller. RTC should auto-sync if DS3231 is detected but invalid.
7. Create manual device CH1 and toggle it. It must call /api/relay, not /api/v3/devices/request.
8. Restart app; saved device profiles must be synchronized after connection.
