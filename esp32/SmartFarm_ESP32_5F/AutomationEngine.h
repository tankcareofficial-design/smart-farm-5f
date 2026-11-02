#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include "Config.h"
#include "RelayManager.h"
#include "EventLog.h"

class Protocol;

struct AutomationRule {
  String ruleId;
  String name;
  bool enabled = true;
  String sensorId;
  String metric;
  size_t relayChannel = 0;
  float turnOnBelow = 45.0f;
  float turnOffAbove = 60.0f;
  uint32_t cooldownSeconds = 10;
  bool active = false;
  uint32_t lastActionMs = 0;
};

struct ManualOverrideState {
  bool active = false;
  bool forcedOn = false;
  uint32_t expiresAtMs = 0;
};

class AutomationEngine {
 public:
  void begin(Preferences &preferences, RelayManager &relayManager, EventLog &eventLog);
  void setAutomationControlledMask(uint32_t mask) { _automationControlledMask = mask; }
  void updateOverrides(Protocol &protocol);
  bool addRule(const AutomationRule &rule, String &errorCode, String &errorMessage);
  bool removeRule(const String &ruleId);
  bool setRuleEnabled(const String &ruleId, bool enabled);
  void clearRules();
  size_t count() const;
  void writeRulesJson(JsonArray array) const;

  void evaluate(const String &sensorId, const String &metric, float value, Protocol &protocol);
  bool setManualRelay(size_t channel, bool on, uint32_t overrideSeconds, Protocol &protocol);
  bool clearManualOverride(size_t channel, Protocol &protocol);
  bool isManualOverrideActive(size_t channel);
  void writeOverridesJson(JsonArray array);

 private:
  Preferences *_preferences = nullptr;
  RelayManager *_relayManager = nullptr;
  EventLog *_eventLog = nullptr;
  AutomationRule _rules[MAX_AUTOMATION_RULES];
  ManualOverrideState _overrides[RELAY_COUNT];
  uint32_t _automationControlledMask = 0;
  size_t _count = 0;

  int findRuleIndex(const String &ruleId) const;
  bool cooldownReady(const AutomationRule &rule, uint32_t now) const;
  void expireOverrides(Protocol *protocol = nullptr);
  void save();
  void load();
};
