# Smart Farm+ 0.7.5

After copying the project, run:

```powershell
flutter pub get
dart format lib
flutter analyze
```

Then uninstall the old app once if plugin registration behaves unexpectedly and run `flutter run`.

Theme, language, farm name, controller and Wi-Fi settings are now stored locally. Schedule and critical controller data will still be stored on ESP32 NVS in a later release.
