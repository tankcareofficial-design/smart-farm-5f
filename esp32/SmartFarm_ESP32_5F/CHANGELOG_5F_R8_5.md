# R8.5 Automation + DS3231
- Native DS3231 driver on I2C 0x68; no external RTC library required.
- Validity and oscillator-stop checks prevent fabricated time.
- Added persistent schedule automation engine (up to 32 rules).
- Minute execution keys prevent duplicate triggers.
- Timed relay pulse, emergency blocking, runtime limits and event logging.
- Existing sensor automation and API/protocol remain backward compatible.
