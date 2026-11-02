# R8.12 V2 hardware verification

1. Flash firmware and provision Wi-Fi.
2. Turn CH1 ON and CH2 OFF, remove controller power for 10 seconds, restore power.
3. Confirm CH1 returns ON and CH2 remains OFF after boot.
4. Press EN/RESET and confirm states return again.
5. Create a schedule whose current time requires OFF; reboot while relay is ON and confirm schedule reconciliation changes it to OFF.
6. Trigger emergency stop, power-cycle, and confirm every channel remains OFF.
7. Hold BOOT 5–9 seconds: Wi-Fi is cleared but relay state remains stored.
8. Hold BOOT at least 10 seconds: full factory reset clears Wi-Fi, profiles, schedules, and relay state.
