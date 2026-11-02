# R8.5 checklist
- Compile with ESP32 Arduino core and ArduinoJson.
- Verify DS3231 on SDA 8 / SCL 9 / address 0x68.
- RTC lost-power state must block schedule execution.
- Reboot must preserve schedule rules.
- Rule must execute once per minute key only.
- Timed pulse must turn relay off after duration.
- Emergency state integration must be verified before field deployment.
