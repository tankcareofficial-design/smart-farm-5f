# Smart Farm+ Checkpoint 5F R5

- แก้ลำดับ Controller provisioning และเก็บ Station IP หลังเชื่อม Wi-Fi บ้าน/ฟาร์ม
- เปิดเมนูตั้งค่า Controller และ Wi-Fi ได้เสมอ แม้ Controller เชื่อมต่ออยู่
- บันทึก Base URL เป็น Station IP หลัง Pairing สำเร็จ
- คืน Dashboard แบบเดิม: วันเวลา สุขภาพฟาร์ม Emergency Stop การ์ดเซ็นเซอร์ และทางลัด
- Sensor card สร้างตามรายการที่เพิ่มจริง แต่ไม่แสดงค่าจำลอง
- Emergency Stop/Release เรียก ESP32 API จริง พร้อมยืนยันก่อนสั่ง
- อัปเดตแอปเป็น 0.8.2+23 และ Firmware เป็น 0.6.5-5f-r5-provisioning-dashboard
