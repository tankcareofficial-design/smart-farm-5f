# Smart Farm+ Checkpoint 5F R7

Version: 0.8.4+25

## Flutter
- แยก Dashboard ออกจากไฟล์เดียวเป็นโมดูล Overview และ Data Widgets
- เพิ่ม `FarmState` เพื่อรวม snapshot จาก Controller, DeviceStore และ SensorStore
- เพิ่ม `FarmHealthEngine` เพื่อย้ายการคำนวณสุขภาพฟาร์มออกจาก UI
- รักษา Classic Dashboard UI จาก R6 และข้อมูลจริงจาก ESP32
- เพิ่ม Firmware/Connection Mode ใน Hero Card เมื่อมีข้อมูล
- แก้ unused import และ lint ที่ต้องใช้วงเล็บปีกกา
- รักษา Emergency Stop, Sensor Grid และ Device Preview เดิม

## ESP32
- Firmware: `0.6.7-5f-r7-architecture-stable`
- คง API และ Protocol จาก R6 เพื่อ backward compatibility
- ไม่มีการเปลี่ยน endpoint หรือพฤติกรรม fail-safe
