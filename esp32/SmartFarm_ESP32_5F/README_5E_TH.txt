SmartFarm ESP32 Checkpoint 5E Live Wi-Fi
Target: ESP32-S3 N16R8

Wi-Fi AP
SSID: SmartFarm-XXXXXX
Password: smartfarm123
IP: 192.168.4.1
Serial Monitor: 115200 baud

สำคัญ
- ใช้ WiFi.mode(WIFI_AP) และ WiFi.softAP() แบบเดียวกับ V0.4.2 ที่พิสูจน์แล้วว่ามือถือมองเห็น
- ไม่ใช้ WIFI_AP_STA, WiFi.disconnect(true,true) หรือ ESPAsyncWebServer ใน Checkpoint นี้
- API ที่แอปใช้: GET /api/device, GET /api/state, POST /api/relay
- channel ใน API เริ่มจาก 0: CH1=0, CH2=1, CH3=2, CH4=3

Arduino IDE
- Board: ESP32S3 Dev Module
- Flash Size: 16MB
- PSRAM: OPI PSRAM
- USB CDC On Boot: Enabled (ตามบอร์ดที่ใช้)
- Library: ArduinoJson
