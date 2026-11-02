# R8.9 ESP32 checklist
- Compile and flash firmware.
- Disconnect DS3231: manual device must still start.
- Disconnect DS3231: sensor-only device must still evaluate.
- Disconnect DS3231: scheduled device must return `clock_invalid`.
- Verify `/api/v3/clock` and `/api/v3/clock/sync`.
- Verify selected weekday and overnight schedules.
- Verify a start threshold activates and valueHigh stops the running output.
- Verify a condition without sensorId is rejected with `missing_sensor_id`.
