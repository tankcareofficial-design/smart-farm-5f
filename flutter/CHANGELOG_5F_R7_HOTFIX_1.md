# Smart Farm+ 5F R7 Hotfix 1

แก้ข้อผิดพลาดจากการรวมโมเดล `FarmState` รุ่นใหม่กับ `FarmController`/`SensorsScreen` รุ่นเดิม:

- เพิ่ม `FarmState.empty`
- เพิ่ม `FarmState.copyWith(...)`
- เพิ่มค่าตัวอ่านเซ็นเซอร์แบบ nullable: `temperature`, `humidity`, `soilMoisture`
- ปรับ `FarmController` ให้รักษาสถานะ connection ระหว่างล้างข้อมูลเซ็นเซอร์
- ไม่สร้างค่าจำลองในเส้นทาง Dashboard หลัก
- แก้ analyzer errors ทั้ง 23 รายการที่รายงานจาก `farm_controller.dart` และ `sensors_screen.dart`
