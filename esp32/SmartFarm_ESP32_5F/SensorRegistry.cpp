#include "SensorRegistry.h"

void SensorRegistry::begin(Preferences &preferences) {
  _preferences = &preferences;
  load();
}

bool SensorRegistry::add(const SensorRecord &sensor, String &errorCode, String &errorMessage) {
  if (sensor.sensorId.isEmpty() || sensor.driverId.isEmpty()) {
    errorCode = "invalid_sensor";
    errorMessage = "sensorId and driverId are required.";
    return false;
  }
  if (sensor.muxChannel < 0 || sensor.muxChannel > 7) {
    errorCode = "invalid_mux_channel";
    errorMessage = "muxChannel must be from 0 to 7.";
    return false;
  }
  if (sensor.deviceAddress < 0x08 || sensor.deviceAddress > 0x77) {
    errorCode = "invalid_i2c_address";
    errorMessage = "deviceAddress must be from 0x08 to 0x77.";
    return false;
  }
  if (findIndex(sensor.sensorId) >= 0) {
    errorCode = "sensor_exists";
    errorMessage = "A sensor with this sensorId already exists.";
    return false;
  }
  if (_count >= MAX_SENSORS) {
    errorCode = "registry_full";
    errorMessage = "Sensor registry is full.";
    return false;
  }

  _sensors[_count++] = sensor;
  save();
  return true;
}

bool SensorRegistry::remove(const String &sensorId) {
  const int index = findIndex(sensorId);
  if (index < 0) return false;

  for (size_t i = static_cast<size_t>(index); i + 1 < _count; i++) {
    _sensors[i] = _sensors[i + 1];
  }
  _count--;
  save();
  return true;
}

int SensorRegistry::findIndex(const String &sensorId) const {
  for (size_t i = 0; i < _count; i++) {
    if (_sensors[i].sensorId == sensorId) return static_cast<int>(i);
  }
  return -1;
}

size_t SensorRegistry::count() const { return _count; }
const SensorRecord &SensorRegistry::at(size_t index) const { return _sensors[index]; }

void SensorRegistry::clear() {
  _count = 0;
  if (_preferences) _preferences->remove("registry");
}

void SensorRegistry::writeJson(JsonArray array) const {
  for (size_t i = 0; i < _count; i++) {
    JsonObject item = array.add<JsonObject>();
    item["sensorId"] = _sensors[i].sensorId;
    item["name"] = _sensors[i].name;
    item["driverId"] = _sensors[i].driverId;
    item["connectionType"] = _sensors[i].connectionType;
    item["muxChannel"] = _sensors[i].muxChannel;
    item["deviceAddress"] = _sensors[i].deviceAddress;
    item["enabled"] = _sensors[i].enabled;
  }
}

void SensorRegistry::load() {
  _count = 0;
  if (!_preferences) return;
  const String json = _preferences->getString("registry", "");
  if (json.isEmpty()) return;

  JsonDocument doc;
  if (deserializeJson(doc, json)) return;
  JsonArray array = doc["sensors"].as<JsonArray>();
  for (JsonObject item : array) {
    if (_count >= MAX_SENSORS) break;
    SensorRecord &sensor = _sensors[_count++];
    sensor.sensorId = item["sensorId"] | "";
    sensor.name = item["name"] | "";
    sensor.driverId = item["driverId"] | "";
    sensor.connectionType = item["connectionType"] | "i2c_mux";
    sensor.muxChannel = item["muxChannel"] | -1;
    sensor.deviceAddress = item["deviceAddress"] | -1;
    sensor.enabled = item["enabled"] | true;
  }
}

void SensorRegistry::save() {
  if (!_preferences) return;
  JsonDocument doc;
  JsonArray array = doc["sensors"].to<JsonArray>();
  writeJson(array);
  String json;
  serializeJson(doc, json);
  _preferences->putString("registry", json);
}
