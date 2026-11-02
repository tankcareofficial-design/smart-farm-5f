#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include "Config.h"

struct RelayState {
  bool on;
  String name;
};

class RelayManager {
 public:
  void begin(Preferences &preferences);
  bool set(size_t channel, bool on);
  // Returns true when the channel is valid and the requested state is applied.
  // Optional changed reports whether GPIO state actually changed.
  bool setTransient(size_t channel, bool on, bool *changed = nullptr);
  void restorePersistedManualState(uint32_t excludedChannelsMask);
  void clearPersistedChannel(size_t channel);
  bool toggle(size_t channel);
  bool get(size_t channel) const;
  size_t count() const;
  void writeJson(JsonArray array) const;

 private:
  RelayState _relays[RELAY_COUNT];
  Preferences *_preferences = nullptr;
  uint32_t _persistedMask = 0;
  bool _hasPersistedState = false;

  void applyHardware(size_t channel);
  void persistState();
  uint32_t currentMask() const;
};
