#include "AutomationEngine.h"
#include "Protocol.h"

void AutomationEngine::begin(Preferences &preferences, RelayManager &relayManager,
                             EventLog &eventLog) {
  _preferences = &preferences;
  _relayManager = &relayManager;
  _eventLog = &eventLog;
  for (size_t i = 0; i < RELAY_COUNT; i++) _overrides[i] = ManualOverrideState();
  load();
  const uint32_t quarantineVersion = _preferences->getUInt("legacyQVersion", 0);
  if (_count > 0 && quarantineVersion < 1) {
    for (size_t i = 0; i < _count; ++i) {
      _rules[i].enabled = false;
      _rules[i].active = false;
    }
    save();
    _preferences->putUInt("legacyQVersion", 1);
    _eventLog->add("automation_quarantine",
                   "Legacy sensor rules disabled; device profiles are authoritative");
  }
}

int AutomationEngine::findRuleIndex(const String &ruleId) const {
  for (size_t i = 0; i < _count; i++) {
    if (_rules[i].ruleId == ruleId) return static_cast<int>(i);
  }
  return -1;
}

bool AutomationEngine::addRule(const AutomationRule &rule, String &errorCode,
                               String &errorMessage) {
  (void)rule;
  errorCode = "legacy_automation_deprecated";
  errorMessage =
      "Legacy sensor automation is disabled. Create a device profile condition instead.";
  if (_eventLog) {
    _eventLog->add("automation_quarantine",
                   "Legacy rule creation rejected; use a device profile condition");
  }
  return false;
}

bool AutomationEngine::removeRule(const String &ruleId) {
  const int index = findRuleIndex(ruleId);
  if (index < 0) return false;
  for (size_t i = static_cast<size_t>(index); i + 1 < _count; i++) _rules[i] = _rules[i + 1];
  _count--;
  save();
  _eventLog->add("automation", "Rule removed", ruleId);
  return true;
}

bool AutomationEngine::setRuleEnabled(const String &ruleId, bool enabled) {
  const int index = findRuleIndex(ruleId);
  if (index < 0) return false;
  if (enabled) {
    _rules[index].enabled = false;
    _rules[index].active = false;
    save();
    _eventLog->add("automation_quarantine",
                   "Legacy rule enable rejected; use a device profile condition",
                   ruleId);
    return false;
  }
  _rules[index].enabled = false;
  _rules[index].active = false;
  save();
  _eventLog->add("automation", "Rule disabled", ruleId);
  return true;
}

void AutomationEngine::clearRules() {
  _count = 0;
  if (_preferences) _preferences->remove("rules");
  _eventLog->add("automation", "All rules cleared");
}

size_t AutomationEngine::count() const { return _count; }

void AutomationEngine::writeRulesJson(JsonArray array) const {
  for (size_t i = 0; i < _count; i++) {
    const AutomationRule &rule = _rules[i];
    JsonObject item = array.add<JsonObject>();
    item["ruleId"] = rule.ruleId;
    item["name"] = rule.name;
    item["enabled"] = rule.enabled;
    item["sensorId"] = rule.sensorId;
    item["metric"] = rule.metric;
    item["relayChannel"] = rule.relayChannel;
    item["turnOnBelow"] = rule.turnOnBelow;
    item["turnOffAbove"] = rule.turnOffAbove;
    item["cooldownSeconds"] = rule.cooldownSeconds;
    item["active"] = rule.active;
    item["lastActionMs"] = rule.lastActionMs;
  }
}

bool AutomationEngine::cooldownReady(const AutomationRule &rule, uint32_t now) const {
  if (rule.lastActionMs == 0) return true;
  return static_cast<uint32_t>(now - rule.lastActionMs) >= rule.cooldownSeconds * 1000UL;
}

void AutomationEngine::expireOverrides(Protocol *protocol) {
  const uint32_t now = millis();
  for (size_t channel = 0; channel < RELAY_COUNT; channel++) {
    ManualOverrideState &overrideState = _overrides[channel];
    if (!overrideState.active || overrideState.expiresAtMs == 0) continue;
    if (static_cast<int32_t>(now - overrideState.expiresAtMs) >= 0) {
      overrideState.active = false;
      overrideState.expiresAtMs = 0;
      const bool automationControlled =
          (_automationControlledMask & (1UL << channel)) != 0;
      bool relayChanged = false;
      if (!automationControlled && _relayManager) {
        const bool wasOn = _relayManager->get(channel);
        const bool applied = _relayManager->set(channel, false);
        relayChanged = applied && wasOn && !_relayManager->get(channel);
      }
      _eventLog->add("manual_override",
                     automationControlled
                         ? "Manual override expired; automation reconciliation pending"
                         : "Manual override expired; manual relay OFF",
                     "", static_cast<int>(channel));
      if (protocol) {
        if (relayChanged) {
          protocol->sendRelayChanged(channel, false, "manual_override_expired");
        }
        protocol->sendManualOverrideChanged(channel, false, false, 0);
      }
    }
  }
}


void AutomationEngine::updateOverrides(Protocol &protocol) {
  expireOverrides(&protocol);
}

bool AutomationEngine::isManualOverrideActive(size_t channel) {
  expireOverrides();
  return channel < RELAY_COUNT && _overrides[channel].active;
}

void AutomationEngine::evaluate(const String &sensorId, const String &metric,
                                float value, Protocol &protocol) {
  // Compatibility-only path. ScheduleAutomationEngine is the sole authority
  // for sensor-based relay decisions. Keeping this method prevents API/schema
  // breakage while ensuring legacy rules cannot write GPIO.
  (void)sensorId;
  (void)metric;
  (void)value;
  expireOverrides(&protocol);
}

bool AutomationEngine::setManualRelay(size_t channel, bool on, uint32_t overrideSeconds,
                                      Protocol &protocol) {
  if (channel >= RELAY_COUNT || !_relayManager->set(channel, on)) return false;
  ManualOverrideState &overrideState = _overrides[channel];
  overrideState.active = true;
  overrideState.forcedOn = on;
  overrideState.expiresAtMs = overrideSeconds == 0 ? 0 : millis() + overrideSeconds * 1000UL;
  protocol.sendRelayChanged(channel, on, "manual_override");
  protocol.sendManualOverrideChanged(channel, true, on, overrideState.expiresAtMs);
  _eventLog->add("manual_override", on ? "Manual relay ON" : "Manual relay OFF", "",
                 static_cast<int>(channel));
  return true;
}

bool AutomationEngine::clearManualOverride(size_t channel, Protocol &protocol) {
  if (channel >= RELAY_COUNT) return false;
  _overrides[channel].active = false;
  _overrides[channel].expiresAtMs = 0;
  protocol.sendManualOverrideChanged(channel, false, _relayManager->get(channel), 0);
  _eventLog->add("manual_override", "Manual override cleared", "", static_cast<int>(channel));
  return true;
}

void AutomationEngine::writeOverridesJson(JsonArray array) {
  expireOverrides();
  for (size_t channel = 0; channel < RELAY_COUNT; channel++) {
    JsonObject item = array.add<JsonObject>();
    item["channel"] = channel;
    item["active"] = _overrides[channel].active;
    item["forcedOn"] = _overrides[channel].forcedOn;
    item["expiresAtMs"] = _overrides[channel].expiresAtMs;
  }
}

void AutomationEngine::save() {
  if (!_preferences) return;
  JsonDocument doc;
  JsonArray array = doc["rules"].to<JsonArray>();
  for (size_t i = 0; i < _count; i++) {
    JsonObject item = array.add<JsonObject>();
    const AutomationRule &rule = _rules[i];
    item["ruleId"] = rule.ruleId;
    item["name"] = rule.name;
    item["enabled"] = rule.enabled;
    item["sensorId"] = rule.sensorId;
    item["metric"] = rule.metric;
    item["relayChannel"] = rule.relayChannel;
    item["turnOnBelow"] = rule.turnOnBelow;
    item["turnOffAbove"] = rule.turnOffAbove;
    item["cooldownSeconds"] = rule.cooldownSeconds;
  }
  String json;
  serializeJson(doc, json);
  _preferences->putString("rules", json);
}

void AutomationEngine::load() {
  _count = 0;
  if (!_preferences) return;
  const String json = _preferences->getString("rules", "");
  if (json.isEmpty()) return;
  JsonDocument doc;
  if (deserializeJson(doc, json)) return;
  JsonArray array = doc["rules"].as<JsonArray>();
  for (JsonObject item : array) {
    if (_count >= MAX_AUTOMATION_RULES) break;
    AutomationRule &rule = _rules[_count++];
    rule.ruleId = item["ruleId"] | "";
    rule.name = item["name"] | "";
    rule.enabled = item["enabled"] | true;
    rule.sensorId = item["sensorId"] | "";
    rule.metric = item["metric"] | "";
    rule.relayChannel = item["relayChannel"] | 0;
    rule.turnOnBelow = item["turnOnBelow"] | 45.0f;
    rule.turnOffAbove = item["turnOffAbove"] | 60.0f;
    rule.cooldownSeconds = item["cooldownSeconds"] | 10;
    rule.active = false;
    rule.lastActionMs = 0;
  }
}
