#pragma once
#include <Arduino.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include "Config.h"

struct SensorRecord {
  String sensorId;
  String name;
  String driverId;
  String connectionType;
  int muxChannel;
  int deviceAddress;
  bool enabled;
};

class SensorRegistry {
 public:
  void begin(Preferences &preferences);
  bool add(const SensorRecord &sensor, String &errorCode, String &errorMessage);
  bool remove(const String &sensorId);
  int findIndex(const String &sensorId) const;
  size_t count() const;
  const SensorRecord &at(size_t index) const;
  void clear();
  void writeJson(JsonArray array) const;

 private:
  Preferences *_preferences = nullptr;
  SensorRecord _sensors[MAX_SENSORS];
  size_t _count = 0;
  void load();
  void save();
};
