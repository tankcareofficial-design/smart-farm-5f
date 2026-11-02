#include "StateManager.h"
#include "Protocol.h"
#include "AutomationEngine.h"
#include <Wire.h>
#include <math.h>

void StateManager::begin(RelayManager &relayManager, AutomationEngine &automationEngine) {
  _relayManager = &relayManager;
  _automationEngine = &automationEngine;
  _lastSensorEventMs = millis();
  if (SOIL_SENSOR_ADC_PIN >= 0) {
    pinMode(SOIL_SENSOR_ADC_PIN, INPUT);
    analogReadResolution(12);
  }
  readRealSensors();
}

void StateManager::update(Protocol &protocol) {
  const uint32_t now = millis();
  if (now - _lastSensorEventMs < SENSOR_EVENT_INTERVAL_MS) return;
  _lastSensorEventMs = now;

  if (USE_MOCK_SENSOR_VALUES) {
    const float phase = static_cast<float>(now % 60000UL) / 60000.0f * 6.2831853f;
    _soil = 52.0f + sinf(phase) * 8.0f;
    _temperature = 28.0f + sinf(phase * 0.7f) * 2.0f;
    _humidity = 72.0f + cosf(phase * 0.8f) * 6.0f;
    _hasHumidity = true;
  } else {
    readRealSensors();
  }

  if (!isnan(_soil)) {
    protocol.sendSensorUpdate("soil-001", "soil_moisture", _soil, "%");
    _automationEngine->evaluate("soil-001", "soil_moisture", _soil, protocol);
  }
  if (!isnan(_temperature)) {
    protocol.sendSensorUpdate("temp-001", "temperature", _temperature, "C");
    _automationEngine->evaluate("temp-001", "temperature", _temperature, protocol);
  }
  if (_hasHumidity && !isnan(_humidity)) {
    protocol.sendSensorUpdate("air-001", "humidity", _humidity, "%");
    _automationEngine->evaluate("air-001", "humidity", _humidity, protocol);
  }
}

void StateManager::readRealSensors() {
  _soil = readSoilPercent();

  _temperature = NAN;
  _humidity = NAN;
  _hasHumidity = false;

  if (ENABLE_SHT31) {
    float shtTemperature = NAN;
    float shtHumidity = NAN;
    if (readSht31(shtTemperature, shtHumidity)) {
      _temperature = shtTemperature;
      _humidity = shtHumidity;
      _hasHumidity = true;
      return;
    }
  }

  if (USE_DS3231_TEMPERATURE_AS_AMBIENT) {
    float ds3231Temperature = NAN;
    if (readDs3231Temperature(ds3231Temperature)) {
      _temperature = ds3231Temperature;
    }
  }
}


uint8_t StateManager::sht31Crc(const uint8_t *data, size_t length) {
  uint8_t crc = 0xFF;
  for (size_t i = 0; i < length; ++i) {
    crc ^= data[i];
    for (uint8_t bit = 0; bit < 8; ++bit) {
      crc = (crc & 0x80) ? static_cast<uint8_t>((crc << 1) ^ 0x31)
                         : static_cast<uint8_t>(crc << 1);
    }
  }
  return crc;
}

bool StateManager::readSht31(float &temperature, float &humidity) {
  Wire.beginTransmission(SHT31_ADDRESS);
  Wire.write(0x24);  // high repeatability, no clock stretching
  Wire.write(0x00);
  if (Wire.endTransmission() != 0) return false;

  delay(16);
  if (Wire.requestFrom(static_cast<int>(SHT31_ADDRESS), 6) != 6) return false;

  uint8_t data[6];
  for (uint8_t i = 0; i < 6; ++i) data[i] = Wire.read();
  if (sht31Crc(data, 2) != data[2] || sht31Crc(data + 3, 2) != data[5]) {
    return false;
  }

  const uint16_t rawTemperature = (static_cast<uint16_t>(data[0]) << 8) | data[1];
  const uint16_t rawHumidity = (static_cast<uint16_t>(data[3]) << 8) | data[4];
  temperature = -45.0f + 175.0f * static_cast<float>(rawTemperature) / 65535.0f;
  humidity = 100.0f * static_cast<float>(rawHumidity) / 65535.0f;
  if (humidity < 0.0f) humidity = 0.0f;
  if (humidity > 100.0f) humidity = 100.0f;
  return !isnan(temperature) && !isnan(humidity);
}

float StateManager::readSoilPercent() {
  // Runtime check is intentional: SOIL_SENSOR_ADC_PIN is a constexpr, not a
  // preprocessor macro. Using #if here made an undefined macro evaluate as 0
  // and accidentally enabled ADC reads from a floating pin.
  if (SOIL_SENSOR_ADC_PIN < 0) return NAN;

  const int raw = analogRead(SOIL_SENSOR_ADC_PIN);
  const int dry = SOIL_ADC_DRY;
  const int wet = SOIL_ADC_WET;
  if (dry == wet) return NAN;
  float percent = (static_cast<float>(raw - dry) * 100.0f) /
                  static_cast<float>(wet - dry);
  if (percent < 0.0f) percent = 0.0f;
  if (percent > 100.0f) percent = 100.0f;
  return percent;
}

bool StateManager::readDs3231Temperature(float &value) {
  Wire.beginTransmission(0x68);
  Wire.write(0x11);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(0x68, 2) != 2) return false;
  const int8_t msb = static_cast<int8_t>(Wire.read());
  const uint8_t lsb = Wire.read();
  value = static_cast<float>(msb) + static_cast<float>(lsb >> 6) * 0.25f;
  return true;
}

float StateManager::soilMoisture() const { return _soil; }
float StateManager::temperature() const { return _temperature; }
float StateManager::humidity() const { return _humidity; }
bool StateManager::hasHumidity() const { return _hasHumidity; }
