# Smart Farm+ Checkpoint 5F R4

## เป้าหมาย
- ปรับหน้า Settings → Controller ให้เป็น Standalone ก่อนเชื่อมต่อ
- แสดง Advanced หลังเชื่อมต่อสำเร็จเท่านั้น
- ย้าย Base URL, API, Diagnostics และ Event/HTTP Log ไปหน้า Advanced
- ยกเลิกข้อมูลเซ็นเซอร์จำลองจากเส้นทางใช้งานจริง
- แสดง Empty State เมื่อยังไม่มีเซ็นเซอร์หรือยังไม่มีค่าจริง

## Flutter
- Dashboard ใช้สถานะ Controller และ DeviceStore จริงเท่านั้น
- SensorStore เก็บเฉพาะการตั้งค่าเซ็นเซอร์ในช่วง 5F R4
- ไม่มีการเริ่ม SimulationService ใน Dashboard หรือ SensorStore
- อัปเดตเวอร์ชันเป็น 0.8.1+22

## ESP32
- อัปเดต firmware เป็น 0.6.4-5f-r4-standalone-real-data
- ปิด mock hardware scan โดยค่าเริ่มต้น
- API และ Protocol Version 1 คงเดิมเพื่อรักษา compatibility

## หมายเหตุ
ค่าจริงของเซ็นเซอร์แบบ Dynamic จะเชื่อมเต็มรูปแบบในขั้น 5H
