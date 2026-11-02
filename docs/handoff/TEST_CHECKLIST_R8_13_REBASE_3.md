# Test Checklist R8.13 Rebase 3

## Connection
- Connect SmartFarm AP and press Connect once
- `/api/device` succeeds even if one snapshot request times out
- 1–2 poll failures show degraded, not offline
- 3 consecutive failures show offline
- A successful poll returns online immediately

## Edit
- Edit name, time, days, and condition
- Save dialog stays open on HTTP 400
- Save succeeds without changing device ID
- Card and snapshot show updated values

## Delete
- Turn relay ON
- Delete device
- Verify relay OFF before card disappears
- Reboot ESP32; device must not return
- Reuse the same relay channel for a new device

## Quality
- flutter clean
- flutter pub get
- dart format lib test
- flutter analyze
- flutter test
- Arduino compile for ESP32S3 Dev Module
