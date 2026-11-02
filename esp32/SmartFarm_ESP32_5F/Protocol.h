#pragma once
#include <Arduino.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include "Config.h"
#include "SensorRegistry.h"
#include "RelayManager.h"
#include "StateManager.h"
#include "AutomationEngine.h"
#include "EventLog.h"

class Protocol {
 public:
  void begin(const String &deviceId, Preferences &preferences,
             SensorRegistry &registry, RelayManager &relayManager,
             StateManager &stateManager, AutomationEngine &automationEngine,
             EventLog &eventLog);
  void poll();
  void processExternalLine(const String &line);
  void setNetworkOutput(Print *output);
  void sendSystemReady();
  void sendSensorUpdate(const String &sensorId, const String &metric,
                        float value, const String &unit);
  void sendRelayChanged(size_t channel, bool on, const String &source);
  void sendAutomationEvent(const char *eventType, const AutomationRule &rule, float value);
  void sendManualOverrideChanged(size_t channel, bool active, bool forcedOn,
                                 uint32_t expiresAtMs);
  void writeEventLogs(JsonArray array) const;

 private:
  String _deviceId;
  Preferences *_preferences = nullptr;
  SensorRegistry *_registry = nullptr;
  RelayManager *_relayManager = nullptr;
  StateManager *_stateManager = nullptr;
  AutomationEngine *_automationEngine = nullptr;
  EventLog *_eventLog = nullptr;
  String _lineBuffer;
  Print *_networkOutput = nullptr;

  void processLine(const String &line);
  void route(JsonDocument &request);
  void sendJson(JsonDocument &doc);
  void sendAck(const String &requestId, const char *action);
  void sendError(const String &requestId, const char *code, const String &message);
  String requestIdFrom(JsonDocument &doc) const;

  void handlePing(JsonDocument &request);
  void handleDeviceInfo(JsonDocument &request);
  void handleScanHardware(JsonDocument &request);
  void handleListSensors(JsonDocument &request);
  void handleAddSensor(JsonDocument &request);
  void handleRemoveSensor(JsonDocument &request);
  void handleListRelays(JsonDocument &request);
  void handleSetRelay(JsonDocument &request);
  void handleToggleRelay(JsonDocument &request);
  void handleClearManualOverride(JsonDocument &request);
  void handleListManualOverrides(JsonDocument &request);
  void handleGetState(JsonDocument &request);
  void handleAddRule(JsonDocument &request);
  void handleListRules(JsonDocument &request);
  void handleRemoveRule(JsonDocument &request);
  void handleSetRuleEnabled(JsonDocument &request);
  void handleListEventLogs(JsonDocument &request);
  void handleClearEventLogs(JsonDocument &request);
  void handleFactoryReset(JsonDocument &request);

  bool selectMuxChannel(uint8_t channel);
  void disableAllMuxChannels();
  bool i2cAddressResponds(uint8_t address);
  const char *guessDriverId(uint8_t address);
  void appendScanDevice(JsonArray &devices, int channel, uint8_t address,
                        const char *driverId, bool certain);
  void performMockScan(JsonArray &devices);
  bool performRealMuxScan(JsonArray &devices);
};
