#include "WiFiTransport.h"
#include "Config.h"
#include "Protocol.h"
#include <ArduinoJson.h>
#include <math.h>

void WiFiTransport::begin(const String &deviceId, RelayManager &relayManager,
                          StateManager &stateManager,
                          AutomationEngine &automationEngine,
                          Protocol &protocol, ClockService &clockService,
                          ScheduleAutomationEngine &scheduleAutomationEngine,
                          SystemHealthManager &systemHealthManager) {
  _deviceId = deviceId;
  _relayManager = &relayManager;
  _stateManager = &stateManager;
  _automationEngine = &automationEngine;
  _protocol = &protocol;
  _clockService = &clockService;
  _scheduleAutomationEngine = &scheduleAutomationEngine;
  _systemHealthManager = &systemHealthManager;

  String suffix = deviceId;
  const int dash = suffix.lastIndexOf('-');
  if (dash >= 0) suffix = suffix.substring(dash + 1);
  if (suffix.length() > 6) suffix = suffix.substring(suffix.length() - 6);
  _ssid = String(WIFI_AP_PREFIX) + suffix;

  _wifiPreferences.begin("sf-wifi", false);
  _emergencyLatched = _wifiPreferences.getBool("emergency", false);
  if (_emergencyLatched) {
    for (size_t channel = 0; channel < _relayManager->count(); ++channel) {
      _automationEngine->setManualRelay(channel, false, 0, *_protocol);
    }
  }
  WiFi.mode(WIFI_AP_STA);
  WiFi.setSleep(false);
  const bool apStarted = WiFi.softAP(_ssid.c_str(), WIFI_AP_PASSWORD);
  delay(250);

  configureRoutes();
  _server.begin();
  restoreStationConnection();

  Serial.println();
  Serial.println("===== SMART FARM 5F R2 PROVISIONING =====");
  Serial.printf("AP start: %s\n", apStarted ? "SUCCESS" : "FAILED");
  Serial.printf("SSID: %s\n", _ssid.c_str());
  Serial.printf("Password: %s\n", WIFI_AP_PASSWORD);
  Serial.printf("AP IP: %s\n", WiFi.softAPIP().toString().c_str());
  Serial.printf("Station: %s\n", WiFi.status() == WL_CONNECTED ? "CONNECTED" : "OFFLINE");
  Serial.println("=========================================");
}

void WiFiTransport::configureRoutes() {
  _server.on("/", HTTP_GET, [this]() {
    addCorsHeaders();
    _server.send(200, "text/plain; charset=utf-8",
                 "Smart Farm+ ESP32 HTTP API\n"
                 "GET /api/device\nGET /api/state\nGET /api/relays\n"
                 "GET /api/wifi/scan\nPOST /api/wifi/connect\n"
                 "POST /api/relay\nPOST /api/emergency-stop\n"
                 "POST /api/emergency-release\n");
  });

  _server.on("/api/device", HTTP_GET, [this]() { handleDeviceInfo(); });
  _server.on("/api/state", HTTP_GET, [this]() { handleState(); });
  _server.on("/api/relays", HTTP_GET, [this]() { handleRelays(); });
  _server.on("/api/wifi/scan", HTTP_GET, [this]() { handleWifiScan(); });
  _server.on("/api/wifi/connect", HTTP_POST, [this]() { handleWifiConnect(); });
  _server.on("/api/relay", HTTP_POST, [this]() { handleSetRelay(); });
  _server.on("/api/emergency-stop", HTTP_POST,
             [this]() { handleEmergencyStop(); });
  _server.on("/api/emergency-release", HTTP_POST,
             [this]() { handleEmergencyRelease(); });
  _server.on("/api/v2/clock", HTTP_GET, [this]() { handleClock(); });
  _server.on("/api/v2/clock/sync", HTTP_POST, [this]() { handleClockSync(); });
  _server.on("/api/v3/clock", HTTP_GET, [this]() { handleClock(); });
  _server.on("/api/v3/clock/sync", HTTP_POST, [this]() { handleClockSync(); });
  _server.on("/api/v2/automations", HTTP_GET, [this]() { handleAutomations(); });
  _server.on("/api/v2/automations", HTTP_POST, [this]() { handleAutomationSave(); });
  _server.on("/api/v2/automations/delete", HTTP_POST, [this]() { handleAutomationDelete(); });
  _server.on("/api/v2/automations/test", HTTP_POST, [this]() { handleAutomationTest(); });
  _server.on("/api/v3/snapshot", HTTP_GET, [this]() { handleSnapshot(); });
  _server.on("/api/v3/devices/config", HTTP_POST, [this]() { handleAutomationSave(); });
  _server.on("/api/v3/devices/request", HTTP_POST, [this]() { handleDeviceRequest(); });
  _server.on("/api/v3/devices/evaluate", HTTP_POST, [this]() { handleDeviceEvaluate(); });
  _server.on("/api/v3/devices/delete", HTTP_POST, [this]() { handleDeviceDelete(); });
  _server.on("/api/v3/runtime", HTTP_GET, [this]() { handleRuntime(); });

  _server.onNotFound([this]() {
    if (_server.method() == HTTP_OPTIONS) {
      addCorsHeaders();
      _server.send(204, "text/plain", "");
      return;
    }
    sendError(404, "not_found", "API endpoint not found.");
  });
}

void WiFiTransport::poll() {
  _server.handleClient();
  maintainStationConnection();
}

void WiFiTransport::restoreStationConnection() {
  const String ssid = _wifiPreferences.getString("ssid", "");
  const String password = _wifiPreferences.getString("password", "");
  if (ssid.isEmpty()) return;
  connectStation(ssid, password, WIFI_CONNECT_TIMEOUT_MS);
}

bool WiFiTransport::connectStation(const String &ssid, const String &password,
                                   uint32_t timeoutMs) {
  WiFi.disconnect(false, false);
  delay(100);
  WiFi.begin(ssid.c_str(), password.c_str());
  const uint32_t startedAt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startedAt < timeoutMs) {
    _server.handleClient();
    delay(100);
  }
  if (WiFi.status() == WL_CONNECTED) {
    _stationSsid = ssid;
    Serial.printf("STA connected: %s IP=%s\n", ssid.c_str(),
                  WiFi.localIP().toString().c_str());
    return true;
  }
  Serial.printf("STA connection failed: %s status=%d\n", ssid.c_str(),
                static_cast<int>(WiFi.status()));
  return false;
}

void WiFiTransport::maintainStationConnection() {
  if (WiFi.status() == WL_CONNECTED || _stationSsid.isEmpty()) return;
  const uint32_t now = millis();
  if (now - _lastStationRetryMs < WIFI_RECONNECT_INTERVAL_MS) return;
  _lastStationRetryMs = now;
  const String password = _wifiPreferences.getString("password", "");
  connectStation(_stationSsid, password, 5000);
}

void WiFiTransport::handleDeviceInfo() {
  JsonDocument response;
  response["ok"] = true;
  response["deviceId"] = _deviceId;
  response["displayName"] = "กล่องควบคุมฟาร์ม";
  response["firmwareVersion"] = FW_VERSION;
  response["storageSchemaVersion"] = STORAGE_SCHEMA_VERSION;
  response["controllerId"] = _deviceId;
  response["protocolVersion"] = PROTOCOL_VERSION;
  response["apiVersion"] = API_VERSION;
  response["hardwareProfile"] = HARDWARE_PROFILE;
  response["accessorySchemaVersion"] = ACCESSORY_SCHEMA_VERSION;
  response["mode"] = "access_point_and_station";
  response["provisioningConfigured"] = !_stationSsid.isEmpty();
  response["provisioningState"] = WiFi.status() == WL_CONNECTED ? "station_connected" : (_stationSsid.isEmpty() ? "not_configured" : "reconnecting");
  response["ssid"] = _ssid;
  response["ip"] = WiFi.softAPIP().toString();
  response["relayCount"] = _relayManager->count();
  response["wifiClientCount"] = WiFi.softAPgetStationNum();
  response["stationConnected"] = WiFi.status() == WL_CONNECTED;
  response["stationSsid"] = WiFi.status() == WL_CONNECTED ? WiFi.SSID() : _stationSsid;
  response["stationIp"] = WiFi.status() == WL_CONNECTED ? WiFi.localIP().toString() : "";
  response["emergencyLatched"] = _emergencyLatched;
  response["uptimeMs"] = millis();
  response["freeHeap"] = ESP.getFreeHeap();
  response["rssi"] = WiFi.status() == WL_CONNECTED ? WiFi.RSSI() : 0;
  JsonArray accessories = response["accessories"].to<JsonArray>();
  writeAccessoryManifest(accessories);
  sendJson(200, response);
}

void WiFiTransport::handleState() {
  JsonDocument response;
  response["ok"] = true;
  response["deviceId"] = _deviceId;
  response["displayName"] = "กล่องควบคุมฟาร์ม";
  response["firmwareVersion"] = FW_VERSION;
  response["protocolVersion"] = PROTOCOL_VERSION;
  response["apiVersion"] = API_VERSION;
  response["hardwareProfile"] = HARDWARE_PROFILE;
  response["accessorySchemaVersion"] = ACCESSORY_SCHEMA_VERSION;
  response["uptimeMs"] = millis();
  response["wifiClientCount"] = WiFi.softAPgetStationNum();
  response["freeHeap"] = ESP.getFreeHeap();
  response["rssi"] = WiFi.status() == WL_CONNECTED ? WiFi.RSSI() : 0;
  response["stationConnected"] = WiFi.status() == WL_CONNECTED;
  response["stationSsid"] = WiFi.status() == WL_CONNECTED ? WiFi.SSID() : _stationSsid;
  response["stationIp"] = WiFi.status() == WL_CONNECTED ? WiFi.localIP().toString() : "";
  response["emergencyLatched"] = _emergencyLatched;

  JsonObject metrics = response["metrics"].to<JsonObject>();
  if (!isnan(_stateManager->soilMoisture())) {
    metrics["soilMoisture"] = serialized(String(_stateManager->soilMoisture(), 2));
  } else {
    metrics["soilMoisture"] = nullptr;
  }
  if (!isnan(_stateManager->temperature())) {
    metrics["temperature"] = serialized(String(_stateManager->temperature(), 2));
  } else {
    metrics["temperature"] = nullptr;
  }
  if (_stateManager->hasHumidity() && !isnan(_stateManager->humidity())) {
    metrics["humidity"] = serialized(String(_stateManager->humidity(), 2));
  } else {
    metrics["humidity"] = nullptr;
  }

  JsonArray accessories = response["accessories"].to<JsonArray>();
  writeAccessoryManifest(accessories);

  JsonArray relays = response["relays"].to<JsonArray>();
  _relayManager->writeJson(relays);
  JsonArray overrides = response["manualOverrides"].to<JsonArray>();
  _automationEngine->writeOverridesJson(overrides);
  for (size_t i = 0; i < relays.size(); ++i) {
    if (i < overrides.size()) relays[i]["overrideActive"] = overrides[i]["active"] | false;
  }
  sendJson(200, response);
}

void WiFiTransport::appendAccessory(
    JsonArray array, const char *deviceId, const char *deviceType,
    const char *portId, const char *role, const char *displayName,
    const char *connectionType, const char *status,
    const char *capabilityA, const char *labelA, const char *unitA,
    const char *capabilityB, const char *labelB, const char *unitB) const {
  JsonObject item = array.add<JsonObject>();
  item["deviceId"] = deviceId;
  item["deviceType"] = deviceType;
  item["portId"] = portId;
  item["role"] = role;
  item["displayName"] = displayName;
  item["connectionType"] = connectionType;
  item["status"] = status;
  item["lastSeenMs"] = strcmp(status, "connected") == 0 ? millis() : 0;
  JsonArray capabilities = item["capabilities"].to<JsonArray>();
  JsonObject first = capabilities.add<JsonObject>();
  first["key"] = capabilityA;
  first["label"] = labelA;
  first["unit"] = unitA;
  if (capabilityB != nullptr) {
    JsonObject second = capabilities.add<JsonObject>();
    second["key"] = capabilityB;
    second["label"] = labelB;
    second["unit"] = unitB;
  }
}

void WiFiTransport::writeAccessoryManifest(JsonArray array) const {
  const bool airLive = !isnan(_stateManager->temperature()) ||
                       (_stateManager->hasHumidity() && !isnan(_stateManager->humidity()));
  appendAccessory(array, "air-sht31", "sht31", "air", "ambient",
                  "อุณหภูมิและความชื้น", "i2c",
                  airLive ? "connected" : "not_installed",
                  "temperature", "อุณหภูมิ", "°C",
                  "humidity", "ความชื้นอากาศ", "%");

  const bool soilLive = !isnan(_stateManager->soilMoisture());
  appendAccessory(array, "soil-adc", "capacitive_soil", "soil", "soil",
                  "ความชื้นดิน", "analog",
                  soilLive ? "connected" : "not_installed",
                  "soilMoisture", "ความชื้นดิน", "%");

  appendAccessory(array, "power-battery", "ina226", "power_1", "battery",
                  "แบตเตอรี่", "i2c", "not_installed", "voltage", "แรงดัน", "V",
                  "current", "กระแส", "A");
  appendAccessory(array, "power-solar", "ina226", "power_2", "solar",
                  "แผงโซลาร์", "i2c", "not_installed", "voltage", "แรงดัน", "V",
                  "current", "กระแส", "A");
}

void WiFiTransport::handleRelays() {
  JsonDocument response;
  response["ok"] = true;
  response["deviceId"] = _deviceId;
  response["relayCount"] = _relayManager->count();
  response["emergencyLatched"] = _emergencyLatched;
  JsonArray relays = response["relays"].to<JsonArray>();
  _relayManager->writeJson(relays);
  JsonArray overrides = response["manualOverrides"].to<JsonArray>();
  _automationEngine->writeOverridesJson(overrides);
  for (size_t i = 0; i < relays.size(); ++i) {
    if (i < overrides.size()) relays[i]["overrideActive"] = overrides[i]["active"] | false;
  }
  sendJson(200, response);
}

void WiFiTransport::handleSetRelay() {
  if (!_server.hasArg("plain")) {
    sendError(400, "missing_body", "JSON request body is required.");
    return;
  }
  JsonDocument request;
  const DeserializationError error = deserializeJson(request, _server.arg("plain"));
  if (error) {
    sendError(400, "invalid_json", error.c_str());
    return;
  }
  if (!request["channel"].is<int>() || !request["on"].is<bool>()) {
    sendError(400, "invalid_relay_command", "channel and boolean on are required.");
    return;
  }
  const int channel = request["channel"].as<int>();
  const bool on = request["on"].as<bool>();
  if (_emergencyLatched && on) {
    sendError(423, "emergency_latched",
              "Emergency stop is active. Release it before turning outputs on.");
    return;
  }
  const uint32_t overrideSeconds = request["overrideSeconds"] | DEFAULT_MANUAL_OVERRIDE_SECONDS;
  if (channel < 0 || static_cast<size_t>(channel) >= _relayManager->count()) {
    sendError(400, "invalid_relay_channel", "Relay channel is out of range.");
    return;
  }
  if (!_automationEngine->setManualRelay(static_cast<size_t>(channel), on,
                                          overrideSeconds, *_protocol)) {
    sendError(500, "relay_command_failed", "Unable to change relay state.");
    return;
  }
  JsonDocument response;
  response["ok"] = true;
  response["channel"] = channel;
  response["on"] = _relayManager->get(static_cast<size_t>(channel));
  response["overrideSeconds"] = overrideSeconds;
  response["overrideActive"] = true;
  response["emergencyLatched"] = _emergencyLatched;
  sendJson(200, response);
}

void WiFiTransport::handleEmergencyStop() {
  bool ok = true;
  for (size_t channel = 0; channel < _relayManager->count(); ++channel) {
    // overrideSeconds=0 means no expiry. Automation cannot reopen the relay.
    ok = _automationEngine->setManualRelay(channel, false, 0, *_protocol) && ok;
  }
  if (!ok) {
    sendError(500, "emergency_stop_failed", "Unable to turn off every relay.");
    return;
  }
  _emergencyLatched = true;
  _wifiPreferences.putBool("emergency", true);
  JsonDocument response;
  response["ok"] = true;
  response["emergencyLatched"] = true;
  response["relayCount"] = _relayManager->count();
  sendJson(200, response);
}

void WiFiTransport::handleEmergencyRelease() {
  bool ok = true;
  for (size_t channel = 0; channel < _relayManager->count(); ++channel) {
    ok = _automationEngine->clearManualOverride(channel, *_protocol) && ok;
  }
  if (!ok) {
    sendError(500, "emergency_release_failed", "Unable to clear every override.");
    return;
  }
  _emergencyLatched = false;
  _wifiPreferences.putBool("emergency", false);
  JsonDocument response;
  response["ok"] = true;
  response["emergencyLatched"] = false;
  sendJson(200, response);
}

void WiFiTransport::handleWifiScan() {
  int16_t scanStatus = WiFi.scanComplete();

  // No scan is active/result-ready yet. Start an asynchronous scan so the
  // SoftAP HTTP server can continue servicing clients while the radio scans.
  if (scanStatus == WIFI_SCAN_FAILED) {
    scanStatus = WiFi.scanNetworks(true, true);
    if (scanStatus == WIFI_SCAN_FAILED) {
      sendError(503, "wifi_scan_failed", "Unable to start Wi-Fi scan.");
      return;
    }
  }

  JsonDocument response;
  response["ok"] = true;

  if (scanStatus == WIFI_SCAN_RUNNING) {
    response["scanning"] = true;
    response["scanState"] = "scanning";
    response["networks"].to<JsonArray>();
    sendJson(200, response);
    return;
  }

  if (scanStatus < 0) {
    sendError(503, "wifi_scan_failed", "Wi-Fi scan failed.");
    return;
  }

  response["scanning"] = false;
  response["scanState"] = "complete";
  response["count"] = scanStatus;
  JsonArray networks = response["networks"].to<JsonArray>();
  for (int i = 0; i < scanStatus; ++i) {
    JsonObject item = networks.add<JsonObject>();
    item["ssid"] = WiFi.SSID(i);
    item["rssi"] = WiFi.RSSI(i);
    item["secure"] = WiFi.encryptionType(i) != WIFI_AUTH_OPEN;
    item["channel"] = WiFi.channel(i);
  }
  WiFi.scanDelete();
  sendJson(200, response);
}

void WiFiTransport::handleWifiConnect() {
  if (!_server.hasArg("plain")) {
    sendError(400, "missing_body", "JSON request body is required.");
    return;
  }
  JsonDocument request;
  const DeserializationError error = deserializeJson(request, _server.arg("plain"));
  if (error) {
    sendError(400, "invalid_json", error.c_str());
    return;
  }
  const String ssid = request["ssid"] | "";
  const String password = request["password"] | "";
  if (ssid.isEmpty()) {
    sendError(400, "missing_ssid", "Wi-Fi SSID is required.");
    return;
  }

  const bool connected = connectStation(ssid, password, WIFI_CONNECT_TIMEOUT_MS);
  if (!connected) {
    JsonDocument response;
    response["ok"] = false;
    response["connected"] = false;
    response["message"] = "Incorrect password, weak signal, or network unavailable.";
    sendJson(200, response);
    return;
  }

  _stationSsid = ssid;
  _wifiPreferences.putString("ssid", ssid);
  _wifiPreferences.putString("password", password);
  JsonDocument response;
  response["ok"] = true;
  response["connected"] = true;
  response["ssid"] = ssid;
  response["ip"] = WiFi.localIP().toString();
  response["stationIp"] = WiFi.localIP().toString();
  response["stationSsid"] = ssid;
  response["provisioningConfigured"] = true;
  response["apStillAvailable"] = true;
  sendJson(200, response);
}


void WiFiTransport::handleClock() {
  _clockService->update();
  const ClockSnapshot clock = _clockService->snapshot();
  JsonDocument response;
  response["ok"] = true;
  JsonObject item = response["clock"].to<JsonObject>();
  item["schemaVersion"] = CLOCK_SCHEMA_VERSION;
  item["available"] = clock.available;
  item["valid"] = clock.valid;
  item["source"] = clock.available ? "ds3231" : "none";
  item["quality"] = clock.quality;
  item["lostPower"] = clock.lostPower;
  item["synchronized"] = clock.synchronized;
  item["utcOffsetMinutes"] = 420;
  if (isnan(clock.chipTemperatureC)) {
    item["chipTemperatureC"] = nullptr;
  } else {
    item["chipTemperatureC"] = roundf(clock.chipTemperatureC * 100.0f) / 100.0f;
  }
  item["readFailures"] = clock.readFailures;
  item["errorCode"] = clock.errorCode;
  item["i2cAddress"] = DS3231_ADDRESS;
  item["sdaPin"] = I2C_SDA_PIN;
  item["sclPin"] = I2C_SCL_PIN;
  item["year"] = clock.year; item["month"] = clock.month; item["day"] = clock.day;
  item["dayOfWeek"] = clock.dayOfWeek; item["hour"] = clock.hour;
  item["minute"] = clock.minute; item["second"] = clock.second;
  char iso[24];
  if (_clockService->rawDateTimeIso(iso, sizeof(iso))) item["dateTimeLocal"] = iso;
  else item["dateTimeLocal"] = nullptr;
  sendJson(200, response);
}

void WiFiTransport::handleClockSync() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request;
  if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  // The Flutter app may send the phone's local time. Empty body intentionally only refreshes status.
  if (request["year"].is<int>()) {
    const bool ok = _clockService->setLocalTime(
      request["year"], request["month"], request["day"], request["dayOfWeek"],
      request["hour"], request["minute"], request["second"] | 0);
    if (!ok) { sendError(400, "clock_sync_failed", "RTC rejected date/time."); return; }
  }
  handleClock();
}

void WiFiTransport::handleAutomations() {
  JsonDocument response;
  response["ok"] = true;
  response["schemaVersion"] = AUTOMATION_SCHEMA_VERSION;
  response["clockReady"] = _clockService->snapshot().valid;
  response["emergencyLatched"] = _emergencyLatched;
  JsonArray rules = response["rules"].to<JsonArray>();
  _scheduleAutomationEngine->writeJson(rules);
  sendJson(200, response);
}

void WiFiTransport::handleAutomationSave() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  const String rawBody = _server.arg("plain");
  JsonDocument request;
  DeserializationError parseError = deserializeJson(request, rawBody);
  if (parseError) {
    Serial.printf("[API] POST /api/v2/automations invalid_json: %s\n", parseError.c_str());
    sendError(400, "invalid_json", parseError.c_str());
    return;
  }
  String error;
  if (!_scheduleAutomationEngine->upsertFromJson(request.as<JsonObjectConst>(), error)) {
    Serial.printf("[API] POST /api/v2/automations rejected: %s body=%s\n", error.c_str(), rawBody.c_str());
    sendError(400, error.c_str(), String("Automation rule validation failed: ") + error);
    return;
  }
  Serial.printf("[API] automation saved id=%s\n", String(request["id"] | "").c_str());
  handleAutomations();
}

void WiFiTransport::handleAutomationDelete() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request;
  if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  String id = request["id"] | "";
  if (id.isEmpty() || !_scheduleAutomationEngine->remove(id)) { sendError(404, "rule_not_found", "Automation rule not found."); return; }
  handleAutomations();
}

void WiFiTransport::handleAutomationTest() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request;
  if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  String id = request["id"] | ""; String error;
  if (!_scheduleAutomationEngine->test(id, _emergencyLatched, error)) { sendError(409, error.c_str(), "Automation test blocked."); return; }
  JsonDocument response; response["ok"] = true; response["id"] = id; response["result"] = "started"; sendJson(200, response);
}


void WiFiTransport::handleSnapshot() {
  _clockService->update();
  JsonDocument response;
  response["ok"] = true;
  response["schemaVersion"] = SNAPSHOT_SCHEMA_VERSION;
  response["controllerId"] = _deviceId;
  response["firmwareVersion"] = FW_VERSION;
  response["storageSchemaVersion"] = STORAGE_SCHEMA_VERSION;
  response["apiVersion"] = API_VERSION;
  response["revision"] = _scheduleAutomationEngine->revision();
  response["generatedAtMs"] = millis();
  response["deviceId"] = _deviceId;
  response["firmwareVersion"] = FW_VERSION;
  response["emergencyLatched"] = _emergencyLatched;
  response["sourceOfTruth"] = "esp32";
  response["runtimeModel"] = "intent_decision_execution";
  JsonObject health = response["health"].to<JsonObject>();
  if (_systemHealthManager != nullptr) _systemHealthManager->writeJson(health);
  JsonObject capabilities = response["capabilities"].to<JsonObject>();
  capabilities["intentCommands"] = true;
  capabilities["deviceRuntime"] = true;
  capabilities["offlineAutomation"] = true;
  capabilities["futureCydClient"] = true;
  capabilities["deviceCentricConfiguration"] = true;
  capabilities["embeddedScheduleAndConditions"] = true;
  JsonObject clock = response["clock"].to<JsonObject>();
  const ClockSnapshot cs = _clockService->snapshot();
  clock["available"] = cs.available; clock["valid"] = cs.valid; clock["source"] = cs.available ? "ds3231" : "none";
  clock["quality"] = cs.quality; clock["lostPower"] = cs.lostPower; clock["errorCode"] = cs.errorCode;
  char iso[24]; if (_clockService->rawDateTimeIso(iso, sizeof(iso))) clock["dateTimeLocal"] = iso; else clock["dateTimeLocal"] = nullptr;
  JsonObject metrics = response["metrics"].to<JsonObject>();
  if (isnan(_stateManager->soilMoisture())) metrics["soilMoisture"] = nullptr; else metrics["soilMoisture"] = _stateManager->soilMoisture();
  if (isnan(_stateManager->temperature())) metrics["temperature"] = nullptr; else metrics["temperature"] = _stateManager->temperature();
  if (!_stateManager->hasHumidity() || isnan(_stateManager->humidity())) metrics["humidity"] = nullptr; else metrics["humidity"] = _stateManager->humidity();
  JsonArray relays = response["relays"].to<JsonArray>(); _relayManager->writeJson(relays);
  JsonArray rules = response["rules"].to<JsonArray>(); _scheduleAutomationEngine->writeJson(rules);
  JsonArray runtime = response["runtime"].to<JsonArray>(); _scheduleAutomationEngine->writeRuntimeJson(runtime);
  JsonArray events = response["events"].to<JsonArray>(); _protocol->writeEventLogs(events);
  sendJson(200, response);
}

void WiFiTransport::handleDeviceRequest() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request; if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  const String deviceId = request["deviceId"] | ""; const bool on = request["desiredState"].as<String>() == "on";
  const bool force = request["force"] | false; const uint32_t seconds = request["overrideSeconds"] | DEFAULT_MANUAL_OVERRIDE_SECONDS;
  if (deviceId.isEmpty()) { sendError(400, "missing_device_id", "deviceId is required."); return; }
  DecisionResult result; if (!_scheduleAutomationEngine->requestDevice(deviceId, on, force, seconds, _emergencyLatched, result)) { sendError(404, result.primaryReason.c_str(), "Device request failed."); return; }
  JsonDocument response; response["ok"] = true; response["accepted"] = true; response["deviceId"] = deviceId; response["allowed"] = result.allowed;
  response["runtimeState"] = result.state == DeviceRuntimeState::RUNNING ? "running" : result.state == DeviceRuntimeState::OVERRIDE ? "override" : result.state == DeviceRuntimeState::BLOCKED ? "blocked" : result.state == DeviceRuntimeState::OFF ? "off" : "waiting";
  response["reason"] = result.primaryReason; JsonArray reasons = response["reasons"].to<JsonArray>(); for (uint8_t i=0;i<result.reasonCount;i++) reasons.add(result.reasons[i]);
  sendJson(200, response);
}

void WiFiTransport::handleDeviceEvaluate() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request; if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  const String deviceId = request["deviceId"] | ""; DecisionResult result;
  if (!_scheduleAutomationEngine->evaluateDevice(deviceId, _emergencyLatched, result)) { sendError(404, result.primaryReason.c_str(), "Device not found."); return; }
  JsonDocument response; response["ok"] = true; response["deviceId"] = deviceId; response["allowed"] = result.allowed; response["reason"] = result.primaryReason;
  JsonArray reasons = response["reasons"].to<JsonArray>(); for (uint8_t i=0;i<result.reasonCount;i++) reasons.add(result.reasons[i]); sendJson(200, response);
}

void WiFiTransport::handleDeviceDelete() {
  if (!_server.hasArg("plain")) { sendError(400, "missing_body", "JSON body required."); return; }
  JsonDocument request;
  if (deserializeJson(request, _server.arg("plain"))) { sendError(400, "invalid_json", "Invalid JSON."); return; }
  const String deviceId = request["deviceId"] | "";
  if (deviceId.isEmpty()) { sendError(400, "missing_device_id", "deviceId is required."); return; }

  const int index = _scheduleAutomationEngine->findDeviceIndex(deviceId);
  if (index < 0) { sendError(404, "device_not_found", "Device profile not found."); return; }
  const int channel = _scheduleAutomationEngine->relayChannelForDevice(deviceId);
  if (channel < 0 || channel >= static_cast<int>(RELAY_COUNT)) {
    sendError(409, "invalid_relay_channel", "Device relay channel is invalid.");
    return;
  }

  bool changed = false;
  if (!_relayManager->setTransient(static_cast<size_t>(channel), false, &changed)) {
    sendError(500, "device_delete_safe_off_failed", "Unable to force relay OFF.");
    return;
  }
  _relayManager->clearPersistedChannel(static_cast<size_t>(channel));
  if (!_scheduleAutomationEngine->removeDevice(deviceId)) {
    sendError(500, "device_delete_failed", "Unable to remove device profile.");
    return;
  }

  JsonDocument response;
  response["ok"] = true;
  response["deviceId"] = deviceId;
  response["relayChannel"] = channel;
  response["actualRelayState"] = "off";
  response["relayChanged"] = changed;
  sendJson(200, response);
}

void WiFiTransport::handleRuntime() {
  JsonDocument response;
  response["ok"] = true;
  response["schemaVersion"] = SNAPSHOT_SCHEMA_VERSION;
  response["controllerId"] = _deviceId;
  response["firmwareVersion"] = FW_VERSION;
  response["storageSchemaVersion"] = STORAGE_SCHEMA_VERSION;
  response["revision"] = _scheduleAutomationEngine->revision();
  response["generatedAtMs"] = millis();
  response["deviceId"] = _deviceId;
  response["sourceOfTruth"] = "esp32";
  JsonArray runtime = response["runtime"].to<JsonArray>();
  _scheduleAutomationEngine->writeRuntimeJson(runtime);
  JsonObject health = response["health"].to<JsonObject>();
  if (_systemHealthManager != nullptr) _systemHealthManager->writeJson(health);
  sendJson(200, response);
}

void WiFiTransport::addCorsHeaders() {
  _server.sendHeader("Access-Control-Allow-Origin", "*");
  _server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  _server.sendHeader("Access-Control-Allow-Headers", "Content-Type,Accept");
  _server.sendHeader("Cache-Control", "no-store");
}

void WiFiTransport::sendJson(int statusCode, JsonDocument &document) {
  String body;
  serializeJson(document, body);
  addCorsHeaders();
  _server.send(statusCode, "application/json; charset=utf-8", body);
}

void WiFiTransport::sendError(int statusCode, const char *code,
                              const String &message) {
  JsonDocument response;
  response["ok"] = false;
  response["error"] = code;
  response["message"] = message;
  sendJson(statusCode, response);
}

String WiFiTransport::accessPointSsid() const { return _ssid; }
IPAddress WiFiTransport::accessPointIp() const { return WiFi.softAPIP(); }
