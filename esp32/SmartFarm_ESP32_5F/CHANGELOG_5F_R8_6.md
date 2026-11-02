# Smart Farm 5F R8.6 — ESP32

## Added
- DS3231 ClockService schema v2 พร้อม quality, chip temperature, ISO local time และ epoch calculation
- Clock sync จากเวลาท้องถิ่นของโทรศัพท์ผ่าน HTTP API
- Automation REST endpoints สำหรับ list/save/delete/test
- Next-run calculation รายสัปดาห์
- Rule deviceId, priority, cooldown, max runtime และ runtime state

## Safety
- Schedule ถูกระงับเมื่อ RTC invalid/lost power
- Emergency stop หยุด schedule ที่กำลังทำงานทันที
- Relay pulse ถูกจำกัดด้วย maxRuntimeSeconds
- Rule ที่ priority ต่ำกว่าจะไม่แทรก relay ที่ถูก rule สำคัญกว่าควบคุมอยู่
