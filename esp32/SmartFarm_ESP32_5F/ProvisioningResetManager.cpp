#include "ProvisioningResetManager.h"
#include "Config.h"
#include <Preferences.h>
#include <WiFi.h>
#include <nvs_flash.h>

void ProvisioningResetManager::begin() {
  pinMode(FACTORY_RESET_PIN, INPUT_PULLUP);
  Preferences system;
  system.begin("sf-system", false);
  const uint32_t saved = system.getUInt("wifiBuild", 0);
  if (DEVELOPMENT_CLEAR_WIFI_ON_FIRMWARE_CHANGE && saved != WIFI_PROVISIONING_VERSION) {
    system.putUInt("wifiBuild", WIFI_PROVISIONING_VERSION);
    system.end();
    clearWiFiOnly();
    Serial.println("[Provisioning] Firmware changed: Wi-Fi credentials cleared only.");
    return;
  }
  system.end();
}

void ProvisioningResetManager::update() {
  const bool down = digitalRead(FACTORY_RESET_PIN) == LOW;
  if (down && !_pressed) {
    _pressed = true;
    _handled = false;
    _pressedAt = millis();
  }
  if (down && !_handled) {
    const uint32_t held = millis() - _pressedAt;
    if (held >= FACTORY_RESET_HOLD_MS) {
      _handled = true;
      factoryReset();
    }
  }
  if (!down && _pressed) {
    const uint32_t held = millis() - _pressedAt;
    if (!_handled && held >= WIFI_RESET_HOLD_MS) {
      _handled = true;
      clearWiFiOnly();
      Serial.println("[Provisioning] BOOT held 5s: Wi-Fi credentials cleared.");
      delay(100);
      ESP.restart();
    }
    _pressed = false;
  }
}

void ProvisioningResetManager::clearWiFiOnly() {
  WiFi.disconnect(true, true);
  Preferences wifi;
  wifi.begin("sf-wifi", false);
  wifi.clear();
  wifi.end();
}

void ProvisioningResetManager::factoryReset() {
  Serial.println("[Provisioning] BOOT held 10s: full factory reset.");
  delay(100);
  nvs_flash_erase();
  nvs_flash_init();
  ESP.restart();
}
