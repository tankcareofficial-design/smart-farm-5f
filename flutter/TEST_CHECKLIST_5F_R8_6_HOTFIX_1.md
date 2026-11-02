# Test Checklist — 5F R8.6 HOTFIX 1

Run from the Flutter project root:

```bash
dart format lib/models/system_clock_state.dart lib/screens/automation_screen.dart lib/screens/main_screen.dart
flutter analyze
flutter test
flutter run
```

Expected analyzer result:

```text
No issues found!
```

Regression checks:
- Open Automation page.
- Create and save a schedule.
- Navigate back during loading; no context-after-dispose exception.
- Verify DS3231 clock card still renders.
- Verify all five bottom navigation destinations work.
