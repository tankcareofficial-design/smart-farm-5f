#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>
#include "Config.h"

struct EventLogEntry {
  uint32_t timestampMs = 0;
  String category;
  String message;
  String ruleId;
  int relayChannel = -1;
};

class EventLog {
 public:
  void add(const String &category, const String &message,
           const String &ruleId = "", int relayChannel = -1);
  void clear();
  size_t count() const;
  void writeJson(JsonArray array) const;

 private:
  EventLogEntry _entries[MAX_EVENT_LOGS];
  size_t _count = 0;
  size_t _next = 0;
};
