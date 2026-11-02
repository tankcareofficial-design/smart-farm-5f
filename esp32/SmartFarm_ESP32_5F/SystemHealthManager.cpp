#include "SystemHealthManager.h"
#include <math.h>

void SystemHealthManager::begin(ClockService &clock, StateManager &state,
                                RelayManager &relays) {
  _clock = &clock;
  _state = &state;
  _relays = &relays;
  update(false);
}

void SystemHealthManager::update(bool emergencyLatched) {
  const uint32_t now = millis();
  if (_lastUpdateMs != 0 && now - _lastUpdateMs < 1000) return;
  _lastUpdateMs = now;

  _snapshot.freeHeap = ESP.getFreeHeap();
  _snapshot.minimumFreeHeap = ESP.getMinFreeHeap();
  _snapshot.heapHealthy = _snapshot.freeHeap >= 30000;
  _snapshot.clockReady = _clock != nullptr && _clock->snapshot().valid;
  _snapshot.networkReady = WiFi.status() == WL_CONNECTED ||
                           WiFi.softAPgetStationNum() > 0;
  _snapshot.rssi = WiFi.status() == WL_CONNECTED ? WiFi.RSSI() : 0;

  const bool soilAvailable = _state != nullptr &&
                             !isnan(_state->soilMoisture());
  const bool temperatureAvailable = _state != nullptr &&
                                    !isnan(_state->temperature());
  const bool humidityAvailable = _state != nullptr &&
                                 _state->hasHumidity() &&
                                 !isnan(_state->humidity());
  _snapshot.sensorDataAvailable = soilAvailable || temperatureAvailable ||
                                  humidityAvailable;

  _snapshot.activeRelayCount = 0;
  if (_relays != nullptr) {
    for (size_t i = 0; i < _relays->count(); ++i) {
      if (_relays->get(i)) ++_snapshot.activeRelayCount;
    }
  }

  uint16_t score = 0;
  score += _snapshot.heapHealthy ? 30 : 10;
  score += _snapshot.clockReady ? 25 : 0;
  score += _snapshot.networkReady ? 15 : 5;
  score += _snapshot.sensorDataAvailable ? 20 : 5;
  score += emergencyLatched ? 0 : 10;
  if (score > 100) score = 100;
  _snapshot.score = static_cast<uint8_t>(score);
  _snapshot.ready = !emergencyLatched && _snapshot.heapHealthy &&
                    _snapshot.clockReady;

  if (emergencyLatched) {
    _snapshot.status = "emergency";
  } else if (!_snapshot.heapHealthy) {
    _snapshot.status = "degraded_memory";
  } else if (!_snapshot.clockReady) {
    _snapshot.status = "clock_unavailable";
  } else if (!_snapshot.sensorDataAvailable) {
    _snapshot.status = "no_sensor_data";
  } else if (!_snapshot.networkReady) {
    _snapshot.status = "local_automation_only";
  } else {
    _snapshot.status = "healthy";
  }
}

void SystemHealthManager::writeJson(JsonObject object) const {
  object["score"] = _snapshot.score;
  object["ready"] = _snapshot.ready;
  object["status"] = _snapshot.status;
  object["clockReady"] = _snapshot.clockReady;
  object["networkReady"] = _snapshot.networkReady;
  object["sensorDataAvailable"] = _snapshot.sensorDataAvailable;
  object["heapHealthy"] = _snapshot.heapHealthy;
  object["freeHeap"] = _snapshot.freeHeap;
  object["minimumFreeHeap"] = _snapshot.minimumFreeHeap;
  object["rssi"] = _snapshot.rssi;
  object["activeRelayCount"] = _snapshot.activeRelayCount;
}
