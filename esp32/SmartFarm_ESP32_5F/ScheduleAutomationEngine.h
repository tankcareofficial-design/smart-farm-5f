#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include "ClockService.h"
#include "RelayManager.h"
#include "EventLog.h"
#include "StateManager.h"
#include "Config.h"

enum class DeviceRuntimeState : uint8_t { OFF, WAITING, RUNNING, BLOCKED, OVERRIDE, ERROR };

struct RuleCondition {
  String type;
  String sensorId;
  String metric;
  String op;
  float value = NAN;
  float valueHigh = NAN;
};

struct ScheduleRule {
  String id, name, deviceId;
  String deviceType = "custom";
  String controlMode = "schedule";
  bool enabled = true;
  uint8_t hour = 6, minute = 0;
  uint8_t endHour = 23, endMinute = 59;
  bool scheduleEnabled = true;
  bool useTimeWindow = false;
  uint8_t dayMask = 0x7F;
  uint8_t relayChannel = 0;
  uint16_t priority = 300;
  uint32_t durationSeconds = 1200;
  uint32_t maxRuntimeSeconds = 1800;
  uint32_t cooldownSeconds = 300;
  String conditionLogic = "and";
  RuleCondition conditions[4];
  uint8_t conditionCount = 0;
  bool requestedOn = false;
  bool forceOverride = false;
  uint32_t overrideUntilEpoch = 0;
  DeviceRuntimeState runtimeState = DeviceRuntimeState::OFF;
  String waitingReason;
  String activeReason;
  String lastExecutionKey;
  uint32_t lastExecutionEpoch = 0;
  uint32_t offAtMs = 0;
  uint32_t startedAtMs = 0;
  String lastResult;
};

struct DecisionResult {
  bool allowed = false;
  DeviceRuntimeState state = DeviceRuntimeState::OFF;
  String primaryReason;
  String reasons[MAX_DECISION_REASONS];
  uint8_t reasonCount = 0;
  uint32_t nextEvaluationEpoch = 0;
};

class ScheduleAutomationEngine {
 public:
  void begin(Preferences &prefs, ClockService &clock, RelayManager &relays, EventLog &events, StateManager &state);
  void update(bool emergencyLatched);
  bool upsertFromJson(JsonObjectConst json, String &error);
  bool remove(const String &id);
  bool test(const String &id, bool emergencyLatched, String &error);
  bool requestDevice(const String &deviceId, bool on, bool force, uint32_t overrideSeconds, bool emergency, DecisionResult &result);
  bool evaluateDevice(const String &deviceId, bool emergency, DecisionResult &result) const;
  void writeJson(JsonArray array) const;
  void writeRuntimeJson(JsonArray array) const;
  bool nextRunIso(const ScheduleRule &rule, char *buffer, size_t size) const;
  size_t count() const { return _count; }
  uint32_t revision() const { return _revision; }
  uint32_t controlledRelayMask() const;
  int findDeviceIndex(const String &deviceId) const { return findDevice(deviceId); }
  int relayChannelForDevice(const String &deviceId) const;
  bool removeDevice(const String &deviceId);
 private:
  Preferences *_prefs=nullptr; ClockService *_clock=nullptr; RelayManager *_relays=nullptr; EventLog *_events=nullptr; StateManager *_state=nullptr;
  ScheduleRule _rules[MAX_SCHEDULE_RULES]; size_t _count=0; uint32_t _revision=1; bool _loading=false; uint32_t _quarantinedRelayMask=0;
  int find(const String &id) const; int findDevice(const String &deviceId) const;
  bool execute(ScheduleRule &r, bool emergency, String &error, bool testRun=false);
  bool validate(const ScheduleRule &r, String &error) const;
  bool relayBusyByHigherPriority(const ScheduleRule &candidate) const;
  bool evaluateCondition(const RuleCondition &c, String &reason) const;
  bool stopThresholdReached(const RuleCondition &c) const;
  DecisionResult decide(const ScheduleRule &r, bool emergency) const;
  bool scheduleAllowsNow(const ScheduleRule &r, const ClockSnapshot &snap) const;
  bool scheduleOccurrenceKey(const ScheduleRule &r, const ClockSnapshot &snap,
                             String &key) const;
  void stopRule(ScheduleRule &r, const char *reason);
  void save(); void load();
  static const char *stateName(DeviceRuntimeState state);
};
