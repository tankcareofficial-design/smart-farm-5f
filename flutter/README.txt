Smart Farm+ Release 0.7.4a — Merge Hotfix

แก้ไข:
- คืนหน้า SensorScreen กลับมาแทน Placeholder
- คงหน้า SettingsScreen จาก Release 0.7.4
- คง Pair Controller Wizard
- ไม่แตะ Dashboard, Devices, Sensor Store หรือ Settings Store

ติดตั้ง:
1. แทนไฟล์ lib/screens/main_screen.dart ด้วยไฟล์ในชุดนี้
2. รัน:
   dart format lib
   flutter analyze
3. ถ้าผ่าน ให้ Hot Restart ด้วย R

หลังแก้:
- หน้าหลัก = Dashboard
- อุปกรณ์ = DevicesScreen
- เซ็นเซอร์ = SensorScreen
- อัตโนมัติ = Placeholder
- ตั้งค่า = SettingsScreen
