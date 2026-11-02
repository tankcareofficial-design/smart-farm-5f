Smart Farm+ Core V0.3.0 — Automation Engine
============================================

ไลบรารีที่ต้องติดตั้ง:
- ArduinoJson 7.x by Benoit Blanchon
- ESP32 board package by Espressif Systems

ตั้งค่าบอร์ด:
- ESP32S3 Dev Module
- Flash Size: 16MB
- PSRAM: OPI PSRAM
- USB CDC On Boot: ใช้ค่าเดิมที่ Serial Monitor ทำงานสำเร็จ
- Serial Monitor: 115200 baud, Newline

ของใหม่ใน V0.3:
- Automation Rule Registry เก็บใน NVS
- Hysteresis: เปิดและปิดคนละค่า ป้องกันรีเลย์สั่น
- Cooldown
- Event automation_triggered / automation_released
- Manual Override พร้อมเวลาหมดอายุ
- Event Log แบบ ring buffer 24 รายการใน RAM
- get_state รวม rules และ manual overrides

ขั้นตอนทดสอบแนะนำ
------------------

1) เพิ่มกฎรดน้ำอัตโนมัติ
{"protocolVersion":1,"type":"add_rule","requestId":"a-001","rule":{"ruleId":"water-zone-1","name":"รดน้ำแปลง 1","enabled":true,"sensorId":"soil-001","metric":"soil_moisture","relayChannel":0,"turnOnBelow":45,"turnOffAbove":59,"cooldownSeconds":5}}

2) ดูรายการกฎ
{"protocolVersion":1,"type":"list_rules","requestId":"a-002"}

ค่าความชื้นจำลองแกว่งประมาณ 44–60%:
- เมื่อ <= 45% จะส่ง automation_triggered และเปิด Relay 1
- เมื่อ >= 59% จะส่ง automation_released และปิด Relay 1
- หนึ่งรอบใช้ประมาณ 1 นาที

3) สั่ง Relay 1 เอง พร้อม Manual Override 20 วินาที
{"protocolVersion":1,"type":"set_relay","requestId":"a-003","channel":0,"on":false,"overrideSeconds":20}

ระหว่าง 20 วินาที Automation จะไม่แย่งควบคุมช่อง 0
overrideSeconds = 0 หมายถึงค้างไว้จนกว่าจะสั่ง clear_manual_override
หากไม่ใส่ overrideSeconds จะใช้ค่าเริ่มต้น 300 วินาที

4) ยกเลิก Manual Override
{"protocolVersion":1,"type":"clear_manual_override","requestId":"a-004","channel":0}

5) ดู Manual Override ทุกช่อง
{"protocolVersion":1,"type":"list_manual_overrides","requestId":"a-005"}

6) ดู Event Log
{"protocolVersion":1,"type":"list_event_logs","requestId":"a-006"}

7) ดูสถานะรวม
{"protocolVersion":1,"type":"get_state","requestId":"a-007"}

8) ปิด/เปิดกฎ
{"protocolVersion":1,"type":"set_rule_enabled","requestId":"a-008","ruleId":"water-zone-1","enabled":false}

9) ลบกฎ
{"protocolVersion":1,"type":"remove_rule","requestId":"a-009","ruleId":"water-zone-1"}

10) ล้าง Event Log
{"protocolVersion":1,"type":"clear_event_logs","requestId":"a-010"}

หมายเหตุสำคัญ:
- รีเลย์ยังเป็น Virtual เพราะ RELAY_PINS ใน Config.h เป็น -1
- Event Log อยู่ใน RAM และหายเมื่อรีสตาร์ต ซึ่งตั้งใจไว้เพื่อลดการเขียน Flash
- Automation Rules อยู่ใน NVS และยังอยู่หลังรีสตาร์ต
- Manual Override ไม่เก็บใน NVS เพื่อความปลอดภัย หลังรีสตาร์ตจะถูกยกเลิก

============================================================
V0.4 Wi-Fi Foundation สำหรับ Smart Farm+ 0.7.8
============================================================
ESP32 จะสร้าง Wi-Fi แบบ Standalone:
SSID: SmartFarm-xxxxxx (ท้าย Device ID)
Password: smartfarm123
IP: 192.168.4.1
TCP JSON port: 8765

มือถือ Android/iOS เชื่อม Wi-Fi นี้ แล้วแอปเปิด TCP socket ไปยัง
192.168.4.1:8765 โดยส่ง JSON หนึ่งข้อความต่อหนึ่งบรรทัดเหมือน USB Serial

============================================================
V0.4.2 HTTP API (Mobile-first)
============================================================
ยกเลิก TCP port 8765 สำหรับแอปมือถือแล้ว แอปใช้ HTTP port 80:
- GET  http://192.168.4.1/api/device
- GET  http://192.168.4.1/api/state
- POST http://192.168.4.1/api/relay
ดู MOBILE_HTTP_TEST_TH.txt สำหรับวิธีทดสอบ
