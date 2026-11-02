# Smart Farm 5F R8.8 HOTFIX 2

- Rebuilt Add/Edit Device as a strict wizard: Type -> Information -> Mode -> Mode configuration.
- Schedule mode opens a dedicated timer page with start time, stop time, and selectable weekdays.
- Sensor mode opens a dedicated rule page with sensor metric, comparison operator, and target value.
- Manual mode can finish directly after mode selection.
- Fixed dark theme in the entire Add Device bottom sheet by removing forced light colors.
- Rebuilt device cards to prevent layout overflow and to show requested/runtime state correctly.
- Fixed dashboard device preview to use Device Intent instead of binding the switch only to physical relay state.
- Added compact live ESP32/DS clock to the top-right of the Devices page.
- Schedule daysMask is now sent to ESP32 as daysOfWeek instead of always sending all seven days.
