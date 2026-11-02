#pragma once

#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include "RelayManager.h"
#include "StateManager.h"
#include "AutomationEngine.h"
#include "ClockService.h"
#include "ScheduleAutomationEngine.h"
#include "SystemHealthManager.h"

class Protocol;

class WiFiTransport {
 public:
  void begin(const String &deviceId, RelayManager &relayManager,
             StateManager &stateManager, AutomationEngine &automationEngine,
             Protocol &protocol, ClockService &clockService,
             ScheduleAutomationEngine &scheduleAutomationEngine,
             SystemHealthManager &systemHealthManager);
  void poll();
  String accessPointSsid() const;
  IPAddress accessPointIp() const;
  bool emergencyLatched() const { return _emergencyLatched; }

 private:
  WebServer _server{80};
  Preferences _wifiPreferences;
  String _ssid;
  String _deviceId;
  String _stationSsid;
  RelayManager *_relayManager = nullptr;
  StateManager *_stateManager = nullptr;
  AutomationEngine *_automationEngine = nullptr;
  Protocol *_protocol = nullptr;
  ClockService *_clockService = nullptr;
  ScheduleAutomationEngine *_scheduleAutomationEngine = nullptr;
  SystemHealthManager *_systemHealthManager = nullptr;
  bool _emergencyLatched = false;
  uint32_t _lastStationRetryMs = 0;

  void configureRoutes();
  void restoreStationConnection();
  bool connectStation(const String &ssid, const String &password,
                      uint32_t timeoutMs);
  void maintainStationConnection();
  void sendJson(int statusCode, JsonDocument &document);
  void sendError(int statusCode, const char *code, const String &message);
  void addCorsHeaders();
  void handleDeviceInfo();
  void handleState();
  void handleRelays();
  void handleSetRelay();
  void handleEmergencyStop();
  void handleEmergencyRelease();
  void writeAccessoryManifest(JsonArray array) const;
  void appendAccessory(JsonArray array, const char *deviceId,
                       const char *deviceType, const char *portId,
                       const char *role, const char *displayName,
                       const char *connectionType, const char *status,
                       const char *capabilityA, const char *labelA, const char *unitA,
                       const char *capabilityB = nullptr, const char *labelB = nullptr,
                       const char *unitB = nullptr) const;
  void handleWifiScan();
  void handleWifiConnect();
  void handleClock();
  void handleClockSync();
  void handleAutomations();
  void handleAutomationSave();
  void handleAutomationDelete();
  void handleAutomationTest();
  void handleSnapshot();
  void handleDeviceRequest();
  void handleDeviceEvaluate();
  void handleDeviceDelete();
  void handleRuntime();
};
