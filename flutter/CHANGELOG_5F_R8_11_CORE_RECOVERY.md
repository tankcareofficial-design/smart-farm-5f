# R8.11 Core Recovery

## Release gates
- Manual devices use POST /api/relay directly and do not depend on RTC or a saved automation profile.
- Schedule and sensor devices keep using device intent API.
- Existing local device profiles are synchronized once after controller connection.
- Flutter automatically synchronizes an available but invalid/lost-power DS3231 from phone local time.
- Clock response contains diagnostics and raw fields.
- Physical relays remain virtual while RELAY_PINS are -1; set them to the real wired GPIO pins before hardware testing.
