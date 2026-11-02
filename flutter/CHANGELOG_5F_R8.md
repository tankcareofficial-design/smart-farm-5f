# Smart Farm+ Checkpoint 5F R8

Version: 0.8.5+26

## Flutter
- ยกระดับ `FarmState` เป็น snapshot กลางที่รวม Controller, diagnostics, sensor readings และ event timeline
- เพิ่ม `DashboardPhase`: disconnected, connecting, live, emergency และ degraded
- เพิ่มโมเดล `SensorReading` แบบ generic รองรับชนิดเซ็นเซอร์เพิ่มในอนาคตโดยไม่ต้องเพิ่ม field ใหม่ใน FarmState
- คง getter temperature/humidity/soilMoisture ไว้เพื่อ backward compatibility โดยอ่านจากรายการ sensor readings
- Dashboard Sensor Grid แสดงค่าจริงจาก ESP32 เมื่อ API ส่งมา และยังคงแสดง No data เมื่อไม่มีค่าจริง
- เพิ่ม Sensor live state: waiting, live, stale, unavailable และ error
- เพิ่ม `FarmEvent` และแสดง event ล่าสุดใน System Alerts
- เพิ่ม protocol version และ uptime ใน Hero Card
- ปรับ Farm Health Engine เป็น weight 30/30/20/10/10 และรองรับ sensor error/stale
- นำ demo data API ออกจาก compatibility FarmController
- API และ Controller/Wi-Fi provisioning จาก R7 ยังคงเดิม

## ESP32
- Firmware marker: `0.6.8-5f-r8-state-snapshot`
- API backward compatible กับ R7
- คง uptime, protocol version, metrics, event log, emergency latch และ Wi-Fi reconnect

## Safety
- ไม่มีค่าจำลองถูกสร้างขึ้นใน runtime
- Emergency release ไม่เปิดรีเลย์กลับอัตโนมัติ
- Relay command ถูกปิดเมื่อ Controller offline หรือ emergency active
