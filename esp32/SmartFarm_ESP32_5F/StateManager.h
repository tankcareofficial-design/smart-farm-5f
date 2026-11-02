#pragma once
#include <Arduino.h>
#include "Config.h"
#include "RelayManager.h"

class Protocol;
class AutomationEngine;

class StateManager {
 public:
  void begin(RelayManager &relayManager, AutomationEngine &automationEngine);
  void update(Protocol &protocol);
  float soilMoisture() const;
  float temperature() const;
  float humidity() const;
  bool hasHumidity() const;

 private:
  RelayManager *_relayManager = nullptr;
  AutomationEngine *_automationEngine = nullptr;
  uint32_t _lastSensorEventMs = 0;
  float _soil = NAN;
  float _temperature = NAN;
  float _humidity = NAN;
  bool _hasHumidity = false;

  void readRealSensors();
  float readSoilPercent();
  bool readDs3231Temperature(float &value);
  bool readSht31(float &temperature, float &humidity);
  static uint8_t sht31Crc(const uint8_t *data, size_t length);
};
