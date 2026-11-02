# Smart Farm Checkpoint 5F Revision 1

## Fixed
- Synchronized `DevicesScreen` with the 5F `DeviceStore` API.
- Confirmed `DeviceStore` provides `controllerConnected`, `lastCommandError`,
  `clearCommandError()`, `isCommandPending()` and asynchronous
  `setOutputState()`.
- Supplied `onConfigureController` when opening `Esp32ControllerPage`.
- Connected the Controller configuration action to `PairControllerScreen`.
- Kept the existing Dashboard, theme, navigation and persisted-device format.

## Clean replacement
Extract this ZIP into a new folder, or replace the whole project folder. Do not
merge it over an older `lib/` tree because stale Dart files can create API
mismatches in the Dart Analysis Server.
