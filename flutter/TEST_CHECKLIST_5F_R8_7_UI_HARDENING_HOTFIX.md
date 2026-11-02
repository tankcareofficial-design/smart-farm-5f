# Test checklist

## Static checks
- Run `flutter pub get`.
- Run `dart format lib test`.
- Run `flutter analyze` and resolve any SDK-specific diagnostics.
- Run `flutter test`.

## Theme checks
- Switch between System, Light, and Dark.
- Open Controller, Pair Controller, Automation, Sensors, Devices, Settings, dialogs, and bottom sheets in each mode.
- Confirm Pair Controller no longer changes to a separate green Material theme.
- Confirm cards do not remain white in dark mode.

## Language checks
- Test Thai and English.
- Confirm Controller diagnostics and roadmap content change language correctly.
- Confirm no visible `5F R4`, `5F4`, `Coming Soon`, `Placeholder`, or demo wording remains.

## Layout checks
- Test portrait and landscape.
- Test a small Android display and a tablet-width display.
- Open the keyboard in all forms and check for RenderFlex overflow.

## Functional regression
- Pair a controller.
- Connect/disconnect and verify status colors.
- Open automation and verify RTC status presentation.
- Change theme and language, close the app, reopen, and verify persistence.
