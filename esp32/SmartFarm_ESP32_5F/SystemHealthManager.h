#pragma once

#include <Arduino.h>
#include <ArduinoJson.h>
#include <WiFi.h>
#include "ClockService.h"
#include "StateManager.h"
#include "RelayManager.h"

struct SystemHealthSnapshot {
  uint8_t score = 0;
  bool ready = false;
  bool clockReady = false;
  bool networkReady = false;
  bool sensorDataAvailable = false;
  bool heapHealthy = false;
  uint32_t freeHeap = 0;
  uint32_t minimumFreeHeap = 0;
  int32_t rssi = 0;
  uint8_t activeRelayCount = 0;
  String status = "unknown";
};

class SystemHealthManager {
 public:
  void begin(ClockService &clock, StateManager &state, RelayManager &relays);
  void update(bool emergencyLatched);
  const SystemHealthSnapshot &snapshot() const { return _snapshot; }
  void writeJson(JsonObject object) const;

 private:
  ClockService *_clock = nullptr;
  StateManager *_state = nullptr;
  RelayManager *_relays = nullptr;
  SystemHealthSnapshot _snapshot;
  uint32_t _lastUpdateMs = 0;
};
