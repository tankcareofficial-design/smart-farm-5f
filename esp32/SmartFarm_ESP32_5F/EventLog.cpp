#include "EventLog.h"

void EventLog::add(const String &category, const String &message,
                   const String &ruleId, int relayChannel) {
  EventLogEntry &entry = _entries[_next];
  entry.timestampMs = millis();
  entry.category = category;
  entry.message = message;
  entry.ruleId = ruleId;
  entry.relayChannel = relayChannel;
  _next = (_next + 1) % MAX_EVENT_LOGS;
  if (_count < MAX_EVENT_LOGS) _count++;
}

void EventLog::clear() {
  _count = 0;
  _next = 0;
}

size_t EventLog::count() const { return _count; }

void EventLog::writeJson(JsonArray array) const {
  const size_t start = (_count == MAX_EVENT_LOGS) ? _next : 0;
  for (size_t i = 0; i < _count; i++) {
    const EventLogEntry &entry = _entries[(start + i) % MAX_EVENT_LOGS];
    JsonObject item = array.add<JsonObject>();
    item["timestampMs"] = entry.timestampMs;
    item["category"] = entry.category;
    item["message"] = entry.message;
    if (!entry.ruleId.isEmpty()) item["ruleId"] = entry.ruleId;
    if (entry.relayChannel >= 0) item["relayChannel"] = entry.relayChannel;
  }
}
