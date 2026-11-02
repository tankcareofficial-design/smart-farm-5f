# Smart Farm 5F R8.13 Rebase 2

## Relay Recovery & Command Integrity

Changes:
- Legacy AutomationEngine no longer writes relay GPIO.
- Legacy sensor rules are quarantined once and new legacy rules are rejected.
- Relay boot starts safe OFF; persisted state restores only manual channels.
- Invalid stored automation profiles retain relay ownership and remain safe OFF.
- Schedule window end boundary is exclusive and runtime uses second-level precision.
- Cross-midnight schedules use the previous day for the after-midnight segment.
- Schedule occurrence identity is persisted to prevent re-execution after reboot.
- Flutter uses one command worker per device with last-command-wins behavior.

Hardware invariants:
- ESP32-S3 N16R8
- Active HIGH relay
- GPIO 4, 5, 6, 7, 15, 16, 17, 18
- DS3231 SDA GPIO8, SCL GPIO9
