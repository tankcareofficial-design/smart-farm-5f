#include "Protocol.h"
#include <Wire.h>
#include <WiFi.h>
#include <math.h>

void Protocol::begin(const String &deviceId, Preferences &preferences,
                     SensorRegistry &registry, RelayManager &relayManager,
                     StateManager &stateManager, AutomationEngine &automationEngine,
                     EventLog &eventLog) {
  _deviceId = deviceId;
  _preferences = &preferences;
  _registry = &registry;
  _relayManager = &relayManager;
  _stateManager = &stateManager;
  _automationEngine = &automationEngine;
  _eventLog = &eventLog;
  _lineBuffer.reserve(MAX_JSON_LINE);
}

void Protocol::poll() {
  while (Serial.available() > 0) {
    const char value = static_cast<char>(Serial.read());
    if (value == '\r') continue;
    if (value == '\n') {
      processLine(_lineBuffer);
      _lineBuffer = "";
      continue;
    }
    if (_lineBuffer.length() >= MAX_JSON_LINE) {
      _lineBuffer = "";
      sendError("", "line_too_long", "JSON line exceeded maximum length.");
      continue;
    }
    _lineBuffer += value;
  }
}

void Protocol::processExternalLine(const String &line) { processLine(line); }

void Protocol::setNetworkOutput(Print *output) { _networkOutput = output; }

void Protocol::processLine(const String &line) {
  if (line.isEmpty()) return;
  JsonDocument request;
  const DeserializationError error = deserializeJson(request, line);
  if (error) {
    sendError("", "invalid_json", error.c_str());
    return;
  }
  route(request);
}

void Protocol::route(JsonDocument &request) {
  const String type = request["type"] | "";
  const String requestId = requestIdFrom(request);
  if (request["protocolVersion"].is<int>() &&
      request["protocolVersion"].as<int>() != PROTOCOL_VERSION) {
    sendError(requestId, "unsupported_protocol", "Unsupported protocolVersion.");
    return;
  }
  if (type == "ping") handlePing(request);
  else if (type == "device_info") handleDeviceInfo(request);
  else if (type == "scan_hardware") handleScanHardware(request);
  else if (type == "list_sensors") handleListSensors(request);
  else if (type == "add_sensor") handleAddSensor(request);
  else if (type == "remove_sensor") handleRemoveSensor(request);
  else if (type == "list_relays") handleListRelays(request);
  else if (type == "set_relay") handleSetRelay(request);
  else if (type == "toggle_relay") handleToggleRelay(request);
  else if (type == "clear_manual_override") handleClearManualOverride(request);
  else if (type == "list_manual_overrides") handleListManualOverrides(request);
  else if (type == "get_state") handleGetState(request);
  else if (type == "add_rule") handleAddRule(request);
  else if (type == "list_rules") handleListRules(request);
  else if (type == "remove_rule") handleRemoveRule(request);
  else if (type == "set_rule_enabled") handleSetRuleEnabled(request);
  else if (type == "list_event_logs") handleListEventLogs(request);
  else if (type == "clear_event_logs") handleClearEventLogs(request);
  else if (type == "factory_reset") handleFactoryReset(request);
  else sendError(requestId, "unknown_command", "Unknown request type.");
}

void Protocol::sendJson(JsonDocument &doc) {
  serializeJson(doc, Serial);
  Serial.println();
  if (_networkOutput != nullptr) {
    serializeJson(doc, *_networkOutput);
    _networkOutput->println();
  }
}
String Protocol::requestIdFrom(JsonDocument &doc) const {
  return doc["requestId"].is<const char *>() ? doc["requestId"].as<String>() : "";
}
void Protocol::sendAck(const String &requestId, const char *action) {
  JsonDocument response;
  response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "ack";
  response["requestId"] = requestId; response["deviceId"] = _deviceId;
  response["action"] = action; response["ok"] = true; sendJson(response);
}
void Protocol::sendError(const String &requestId, const char *code, const String &message) {
  JsonDocument response;
  response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "error";
  response["requestId"] = requestId; response["deviceId"] = _deviceId;
  response["code"] = code; response["message"] = message; sendJson(response);
}
void Protocol::sendSystemReady() {
  JsonDocument event; event["protocolVersion"] = PROTOCOL_VERSION;
  event["type"] = "system_ready"; event["deviceId"] = _deviceId;
  event["firmwareVersion"] = FW_VERSION; event["uptimeMs"] = millis(); sendJson(event);
}
void Protocol::sendSensorUpdate(const String &sensorId, const String &metric, float value, const String &unit) {
  JsonDocument event; event["protocolVersion"] = PROTOCOL_VERSION;
  event["type"] = "sensor_update"; event["deviceId"] = _deviceId;
  event["sensorId"] = sensorId; event["metric"] = metric;
  event["value"] = serialized(String(value, 2)); event["unit"] = unit;
  event["timestampMs"] = millis(); sendJson(event);
}
void Protocol::sendRelayChanged(size_t channel, bool on, const String &source) {
  JsonDocument event; event["protocolVersion"] = PROTOCOL_VERSION;
  event["type"] = "relay_changed"; event["deviceId"] = _deviceId;
  event["channel"] = channel; event["on"] = on; event["source"] = source;
  event["timestampMs"] = millis(); sendJson(event);
}
void Protocol::sendAutomationEvent(const char *eventType, const AutomationRule &rule, float value) {
  JsonDocument event; event["protocolVersion"] = PROTOCOL_VERSION;
  event["type"] = eventType; event["deviceId"] = _deviceId;
  event["ruleId"] = rule.ruleId; event["name"] = rule.name;
  event["sensorId"] = rule.sensorId; event["metric"] = rule.metric;
  event["value"] = serialized(String(value, 2)); event["relayChannel"] = rule.relayChannel;
  event["timestampMs"] = millis(); sendJson(event);
}
void Protocol::sendManualOverrideChanged(size_t channel, bool active, bool forcedOn, uint32_t expiresAtMs) {
  JsonDocument event; event["protocolVersion"] = PROTOCOL_VERSION;
  event["type"] = "manual_override_changed"; event["deviceId"] = _deviceId;
  event["channel"] = channel; event["active"] = active; event["forcedOn"] = forcedOn;
  event["expiresAtMs"] = expiresAtMs; event["timestampMs"] = millis(); sendJson(event);
}

void Protocol::handlePing(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "pong";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  response["uptimeMs"] = millis(); sendJson(response);
}
void Protocol::handleDeviceInfo(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "device_info";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  response["firmwareVersion"] = FW_VERSION; response["hardwareProfile"] = HARDWARE_PROFILE;
  response["accessorySchemaVersion"] = ACCESSORY_SCHEMA_VERSION; response["chipModel"] = ESP.getChipModel();
  response["chipRevision"] = ESP.getChipRevision(); response["cpuMHz"] = ESP.getCpuFreqMHz();
  response["flashBytes"] = ESP.getFlashChipSize(); response["psramBytes"] = ESP.getPsramSize();
  response["freeHeapBytes"] = ESP.getFreeHeap(); response["freePsramBytes"] = ESP.getFreePsram();
  response["sensorCount"] = _registry->count(); response["relayCount"] = _relayManager->count();
  response["automationRuleCount"] = _automationEngine->count(); response["mockHardware"] = USE_MOCK_HARDWARE_SCAN;
  sendJson(response);
}
void Protocol::handleScanHardware(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "scan_result";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  response["muxAddress"] = TCA9548A_ADDRESS; response["mock"] = USE_MOCK_HARDWARE_SCAN;
  JsonArray devices = response["devices"].to<JsonArray>();
  const bool muxFound = USE_MOCK_HARDWARE_SCAN ? (performMockScan(devices), true) : performRealMuxScan(devices);
  response["muxFound"] = muxFound; response["count"] = devices.size(); sendJson(response);
}
void Protocol::handleListSensors(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "sensor_list";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  JsonArray array = response["sensors"].to<JsonArray>(); _registry->writeJson(array);
  response["count"] = _registry->count(); sendJson(response);
}
void Protocol::handleAddSensor(JsonDocument &request) {
  const String requestId = requestIdFrom(request); JsonObject item = request["sensor"].as<JsonObject>();
  if (item.isNull()) { sendError(requestId, "missing_sensor", "Missing sensor object."); return; }
  SensorRecord sensor; sensor.sensorId = item["sensorId"] | ""; sensor.name = item["name"] | "";
  sensor.driverId = item["driverId"] | ""; sensor.connectionType = item["connectionType"] | "i2c_mux";
  sensor.muxChannel = item["muxChannel"] | -1; sensor.deviceAddress = item["deviceAddress"] | -1;
  sensor.enabled = item["enabled"] | true; String code, message;
  if (!_registry->add(sensor, code, message)) { sendError(requestId, code.c_str(), message); return; }
  sendAck(requestId, "add_sensor");
}
void Protocol::handleRemoveSensor(JsonDocument &request) {
  const String requestId = requestIdFrom(request); const String sensorId = request["sensorId"] | "";
  if (sensorId.isEmpty()) { sendError(requestId, "missing_sensor_id", "sensorId is required."); return; }
  if (!_registry->remove(sensorId)) { sendError(requestId, "sensor_not_found", "Sensor was not found."); return; }
  sendAck(requestId, "remove_sensor");
}
void Protocol::handleListRelays(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "relay_list";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  JsonArray array = response["relays"].to<JsonArray>(); _relayManager->writeJson(array);
  response["count"] = _relayManager->count(); sendJson(response);
}
void Protocol::handleSetRelay(JsonDocument &request) {
  const String requestId = requestIdFrom(request);
  if (!request["channel"].is<int>() || !request["on"].is<bool>()) {
    sendError(requestId, "invalid_relay_command", "channel and boolean on are required."); return;
  }
  const int channel = request["channel"]; const bool on = request["on"];
  const uint32_t seconds = request["overrideSeconds"] | DEFAULT_MANUAL_OVERRIDE_SECONDS;
  if (channel < 0 || !_automationEngine->setManualRelay(channel, on, seconds, *this)) {
    sendError(requestId, "invalid_relay_channel", "Relay channel is out of range."); return;
  }
  sendAck(requestId, "set_relay");
}
void Protocol::handleToggleRelay(JsonDocument &request) {
  const String requestId = requestIdFrom(request);
  if (!request["channel"].is<int>()) { sendError(requestId, "invalid_relay_command", "channel is required."); return; }
  const int channel = request["channel"];
  if (channel < 0 || static_cast<size_t>(channel) >= _relayManager->count()) {
    sendError(requestId, "invalid_relay_channel", "Relay channel is out of range."); return;
  }
  const uint32_t seconds = request["overrideSeconds"] | DEFAULT_MANUAL_OVERRIDE_SECONDS;
  if (!_automationEngine->setManualRelay(channel, !_relayManager->get(channel), seconds, *this)) {
    sendError(requestId, "relay_command_failed", "Unable to toggle relay."); return;
  }
  sendAck(requestId, "toggle_relay");
}
void Protocol::handleClearManualOverride(JsonDocument &request) {
  const String requestId = requestIdFrom(request); const int channel = request["channel"] | -1;
  if (channel < 0 || !_automationEngine->clearManualOverride(channel, *this)) {
    sendError(requestId, "invalid_relay_channel", "Relay channel is out of range."); return;
  }
  sendAck(requestId, "clear_manual_override");
}
void Protocol::handleListManualOverrides(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "manual_override_list";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  JsonArray array = response["overrides"].to<JsonArray>(); _automationEngine->writeOverridesJson(array); sendJson(response);
}
void Protocol::handleGetState(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "state_snapshot";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId; response["uptimeMs"] = millis();
  JsonObject metrics = response["metrics"].to<JsonObject>();
  if (!isnan(_stateManager->soilMoisture()))
    metrics["soilMoisture"] = serialized(String(_stateManager->soilMoisture(), 2));
  else metrics["soilMoisture"] = nullptr;
  if (!isnan(_stateManager->temperature()))
    metrics["temperature"] = serialized(String(_stateManager->temperature(), 2));
  else metrics["temperature"] = nullptr;
  if (_stateManager->hasHumidity() && !isnan(_stateManager->humidity()))
    metrics["humidity"] = serialized(String(_stateManager->humidity(), 2));
  else metrics["humidity"] = nullptr;
  response["wifiClientCount"] = WiFi.softAPgetStationNum();
  JsonArray relays = response["relays"].to<JsonArray>(); _relayManager->writeJson(relays);
  JsonArray rules = response["automationRules"].to<JsonArray>(); _automationEngine->writeRulesJson(rules);
  JsonArray overrides = response["manualOverrides"].to<JsonArray>(); _automationEngine->writeOverridesJson(overrides);
  sendJson(response);
}
void Protocol::handleAddRule(JsonDocument &request) {
  const String requestId = requestIdFrom(request); JsonObject item = request["rule"].as<JsonObject>();
  if (item.isNull()) { sendError(requestId, "missing_rule", "Missing rule object."); return; }
  AutomationRule rule; rule.ruleId = item["ruleId"] | ""; rule.name = item["name"] | "";
  rule.enabled = item["enabled"] | true; rule.sensorId = item["sensorId"] | "";
  rule.metric = item["metric"] | ""; rule.relayChannel = item["relayChannel"] | 0;
  rule.turnOnBelow = item["turnOnBelow"] | 45.0f; rule.turnOffAbove = item["turnOffAbove"] | 60.0f;
  rule.cooldownSeconds = item["cooldownSeconds"] | 10; String code, message;
  if (!_automationEngine->addRule(rule, code, message)) { sendError(requestId, code.c_str(), message); return; }
  sendAck(requestId, "add_rule");
}
void Protocol::handleListRules(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "automation_rule_list";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  JsonArray array = response["rules"].to<JsonArray>(); _automationEngine->writeRulesJson(array);
  response["count"] = _automationEngine->count(); sendJson(response);
}
void Protocol::handleRemoveRule(JsonDocument &request) {
  const String requestId = requestIdFrom(request); const String ruleId = request["ruleId"] | "";
  if (ruleId.isEmpty()) { sendError(requestId, "missing_rule_id", "ruleId is required."); return; }
  if (!_automationEngine->removeRule(ruleId)) { sendError(requestId, "rule_not_found", "Rule was not found."); return; }
  sendAck(requestId, "remove_rule");
}
void Protocol::handleSetRuleEnabled(JsonDocument &request) {
  const String requestId = requestIdFrom(request); const String ruleId = request["ruleId"] | "";
  if (ruleId.isEmpty() || !request["enabled"].is<bool>()) {
    sendError(requestId, "invalid_rule_command", "ruleId and boolean enabled are required."); return;
  }
  if (!_automationEngine->setRuleEnabled(ruleId, request["enabled"].as<bool>())) {
    sendError(requestId, "rule_not_found", "Rule was not found."); return;
  }
  sendAck(requestId, "set_rule_enabled");
}
void Protocol::handleListEventLogs(JsonDocument &request) {
  JsonDocument response; response["protocolVersion"] = PROTOCOL_VERSION; response["type"] = "event_log_list";
  response["requestId"] = requestIdFrom(request); response["deviceId"] = _deviceId;
  JsonArray array = response["logs"].to<JsonArray>(); _eventLog->writeJson(array);
  response["count"] = _eventLog->count(); sendJson(response);
}
void Protocol::handleClearEventLogs(JsonDocument &request) {
  _eventLog->clear(); sendAck(requestIdFrom(request), "clear_event_logs");
}
void Protocol::handleFactoryReset(JsonDocument &request) {
  _registry->clear(); _automationEngine->clearRules(); _eventLog->clear();
  for (size_t i = 0; i < _relayManager->count(); i++) {
    _automationEngine->clearManualOverride(i, *this); _relayManager->set(i, false);
  }
  sendAck(requestIdFrom(request), "factory_reset");
}

bool Protocol::selectMuxChannel(uint8_t channel) {
  if (channel > 7) return false; Wire.beginTransmission(TCA9548A_ADDRESS);
  Wire.write(1U << channel); return Wire.endTransmission() == 0;
}
void Protocol::disableAllMuxChannels() { Wire.beginTransmission(TCA9548A_ADDRESS); Wire.write(0); Wire.endTransmission(); }
bool Protocol::i2cAddressResponds(uint8_t address) { Wire.beginTransmission(address); return Wire.endTransmission() == 0; }
const char *Protocol::guessDriverId(uint8_t address) {
  switch (address) { case 0x40: return "ina226_or_similar"; case 0x44: case 0x45: return "sht3x";
    case 0x68: return "ds3231_or_rtc"; case 0x76: case 0x77: return "bme280_or_bmp280";
    default: return "unknown_i2c"; }
}
void Protocol::appendScanDevice(JsonArray &devices, int channel, uint8_t address, const char *driverId, bool certain) {
  JsonObject item = devices.add<JsonObject>(); item["connectionType"] = "i2c_mux";
  item["muxAddress"] = TCA9548A_ADDRESS; item["muxChannel"] = channel;
  item["deviceAddress"] = address; item["driverId"] = driverId; item["identificationCertain"] = certain;
}
void Protocol::performMockScan(JsonArray &devices) {
  appendScanDevice(devices, 0, 0x68, "ds3231", true);
  appendScanDevice(devices, 1, 0x40, "ina226", true);
  appendScanDevice(devices, 2, 0x20, "soil_i2c_generic", false);
}
bool Protocol::performRealMuxScan(JsonArray &devices) {
  if (!i2cAddressResponds(TCA9548A_ADDRESS)) return false;
  for (uint8_t channel = 0; channel < 8; channel++) {
    if (!selectMuxChannel(channel)) continue; delay(2);
    for (uint8_t address = 0x08; address <= 0x77; address++) {
      if (address != TCA9548A_ADDRESS && i2cAddressResponds(address))
        appendScanDevice(devices, channel, address, guessDriverId(address), false);
    }
  }
  disableAllMuxChannels(); return true;
}

void Protocol::writeEventLogs(JsonArray array) const {
  if (_eventLog != nullptr) _eventLog->writeJson(array);
}
