# R8.11 Core Recovery - Hardware Test Gate

1. Flash ESP32 and verify Serial lists CH1=4, CH2=5, CH3=6, CH4=7, CH5=15, CH6=16, CH7=17, CH8=18.
2. Verify RTC reports available=YES and valid=YES after phone sync.
3. Manual ON/OFF test CH1-CH8 with no mains load connected.
4. Save 08:00-10:00 schedule: must return HTTP 200.
5. Save 22:08-06:15 schedule: must return HTTP 200 and duration 29220 seconds.
6. Equal start/end must be blocked in Flutter and rejected by firmware.
7. Run dart format lib and flutter analyze.
8. Compile firmware for ESP32S3 Dev Module, Flash 16MB, PSRAM OPI.
