# R8.8 test checklist
1. flutter pub get
2. dart format lib test
3. flutter analyze
4. Add a manual device.
5. Add a scheduled device and select start/stop time.
6. Add a sensor-condition device and select metric/operator/value.
7. Restart app and confirm configurations persist.
8. Confirm Automation tab is absent.
9. Confirm Farm Health is above Quick Actions.
10. Confirm Connected Accessories card is absent.
11. Press ON before conditions match: switch represents requested ON; card must show waiting, while actual relay remains off.
12. Confirm dark and light theme in Add/Edit Device.
