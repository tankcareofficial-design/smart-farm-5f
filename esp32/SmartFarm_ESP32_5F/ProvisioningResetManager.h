#pragma once
#include <Arduino.h>

class ProvisioningResetManager {
 public:
  void begin();
  void update();
 private:
  bool _pressed = false;
  bool _handled = false;
  uint32_t _pressedAt = 0;
  void clearWiFiOnly();
  void factoryReset();
};
