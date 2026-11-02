# R8.10 Test Checklist

- flutter clean
- flutter pub get
- dart format lib test
- flutter analyze
- flutter test
- ทดสอบ manual โดยไม่มี RTC
- ทดสอบ sensor-only โดยไม่มี RTC
- ทดสอบ schedule เมื่อ RTC invalid
- ทดสอบ DS3231 valid แสดง HH:mm:ss และวัน DD/MM/YYYY
