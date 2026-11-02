Smart Farm+ 0.7.6 FIX + Windows USB Serial
==========================================

สิ่งที่เพิ่ม/แก้ไข
- เพิ่ม flutter_libserialport ^0.6.0
- เพิ่ม SerialConnectionService
- เพิ่ม SmartFarmController
- เพิ่มหน้า Windows Serial Dashboard
- เพิ่มเมนู Settings > USB Serial (Windows)
- แก้ duplicate_definition จาก separatorBuilder: (_, _)
- แก้ DropdownButtonFormField value เป็น initialValue
- ปรับ build number เป็น 0.7.6+18

วิธีนำไปทับโปรเจกต์เดิม
1. ปิด VS Code/แอปที่กำลังใช้ไฟล์โปรเจกต์
2. สำรองโฟลเดอร์ C:\Users\Ratthaphum\smart_farm ไว้ก่อน
3. แตก ZIP นี้ แล้วคัดลอกไฟล์ทั้งหมดด้านในไปทับ smart_farm
4. เปิด PowerShell ในโฟลเดอร์ smart_farm
5. เปิด Windows Developer Mode:
   start ms-settings:developers
6. รัน:
   flutter clean
   flutter pub get
   dart format lib
   flutter analyze
   flutter run -d windows

วิธีใช้งาน
- เข้า Settings
- กด USB Serial (Windows)
- ปิด Arduino Serial Monitor ก่อน
- เลือก COM ของ ESP32-S3
- กดเชื่อมต่อ
- Baud rate = 115200
