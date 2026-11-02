# Smart Farm Flutter 5F R8.9 HOTFIX 1

Version: 0.8.9+81

## Analyzer cleanup
- Removed unused `app_localizations.dart` import.
- Added braces to the reported `for` and `if` statements.
- Migrated device type and control mode selection from deprecated per-tile `groupValue`/`onChanged` to `RadioGroup`.
- Preserved disabled sensor-mode behavior when no configured sensor exists.

## Verification note
The ZIP structure and archive integrity were checked. Flutter SDK is not installed in the build environment, so `flutter analyze` and compilation were not executed here.
