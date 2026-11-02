# Smart Farm 5F R8.13 Rebase 3
## Connection Stability, Safe Delete & Edit Recovery

### Flutter
- `/api/device` เป็น endpoint ยืนยันว่า Controller เข้าถึงได้
- State, Clock และ Snapshot โหลดแยกกัน; endpoint รองล้มเหลวไม่ทำให้ Connect ล้มทันที
- Probe `/api/device` retry แบบ 0/300/800 ms
- Poll ล้มเหลว 1–2 ครั้งเป็น degraded; 3 ครั้งต่อเนื่องจึง offline
- เพิ่ม/แก้ไขอุปกรณ์รอ ESP32 ยืนยันก่อนแก้ Local State
- Dialog แสดง loading และคงเปิดเมื่อบันทึกไม่สำเร็จ
- ลบอุปกรณ์รอ Safe Delete จาก ESP32 ก่อนลบการ์ด
- แก้ curly-braces lint ใน DeviceStore

### ESP32
- เพิ่ม `POST /api/v3/devices/delete`
- Delete สั่ง Relay OFF ก่อน ล้าง persisted relay bit แล้วจึงลบ Profile
- Response ยืนยัน `actualRelayState=off`
- Firmware `0.8.0-5f-r8.13-rebase-3`

### Hardware invariants
- ESP32-S3 N16R8
- Active HIGH
- Relay GPIO: 4, 5, 6, 7, 15, 16, 17, 18
- DS3231 SDA=8, SCL=9
