# Smart Farm 5F R8.10 Global Clock Hotfix

Version: 0.8.10+92

- SmartFarmController is now the single source of truth for controller time.
- Controller clock baseline is refreshed on connect, polling, manual refresh, and when opening Devices.
- DeviceStore delegates controller time instead of maintaining a second baseline.
- A DS3231 value can be displayed even while lostPower/valid is false; schedules remain blocked until valid.
- Clock parser accepts dateTimeLocal and common compatible aliases.
- Devices screen distinguishes valid time, unverified DS3231 time, RTC unavailable, and disconnected.
