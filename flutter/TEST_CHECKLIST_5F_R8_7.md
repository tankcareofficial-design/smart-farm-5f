# R8.7 test checklist

1. Compile ESP32 with ArduinoJson 7.x.
2. Verify DS3231 time and `/api/v3/snapshot`.
3. Create a rule with a time window and sensor condition.
4. Request ON while conditions fail: runtime must be `waiting`, relay OFF.
5. Make conditions pass: relay ON and runtime `running`.
6. Request OFF: waiting/running request is cancelled and relay OFF.
7. Force override: relay may run unless emergency stop is latched.
8. Disconnect Flutter: ESP32 automation continues.
9. Reconnect Flutter: cached data appears first, then snapshot revision updates.
10. Confirm CYD can later use the same v3 snapshot/request JSON contract over UART.
