#pragma once
#include <Arduino.h>

static constexpr char FW_VERSION[] = "0.8.0-5f-r8.13-rebase-3";
static constexpr uint16_t PROTOCOL_VERSION = 1;
static constexpr char HARDWARE_PROFILE[] = "smart_farm_8ch_v1";
static constexpr uint8_t ACCESSORY_SCHEMA_VERSION = 2;
static constexpr uint8_t CLOCK_SCHEMA_VERSION = 2;
static constexpr uint8_t AUTOMATION_SCHEMA_VERSION = 3;
static constexpr uint8_t SNAPSHOT_SCHEMA_VERSION = 3;
static constexpr uint16_t STORAGE_SCHEMA_VERSION = 2;
static constexpr uint32_t WIFI_PROVISIONING_VERSION = 81202;
static constexpr bool DEVELOPMENT_CLEAR_WIFI_ON_FIRMWARE_CHANGE = true;
static constexpr int FACTORY_RESET_PIN = 0;
static constexpr uint32_t WIFI_RESET_HOLD_MS = 5000;
static constexpr uint32_t FACTORY_RESET_HOLD_MS = 10000;
static constexpr uint8_t API_VERSION = 3;
static constexpr uint8_t DS3231_ADDRESS = 0x68;
static constexpr uint32_t SERIAL_BAUD = 115200;
static constexpr char WIFI_AP_PREFIX[] = "SmartFarm-";
static constexpr char WIFI_AP_PASSWORD[] = "smartfarm123";
static constexpr uint16_t WIFI_HTTP_PORT = 80;


static constexpr int I2C_SDA_PIN = 8;
static constexpr int I2C_SCL_PIN = 9;
static constexpr uint32_t I2C_FREQUENCY = 100000;
static constexpr uint8_t TCA9548A_ADDRESS = 0x70;

static constexpr bool USE_MOCK_HARDWARE_SCAN = false;
static constexpr bool USE_MOCK_SENSOR_VALUES = false;

// DS3231 and ESP32 internal temperature are board temperatures, not reliable
// farm-air measurements. Keep disabled until a dedicated ambient sensor is used.
static constexpr bool USE_DS3231_TEMPERATURE_AS_AMBIENT = false;

static constexpr bool ENABLE_SHT31 = true;
static constexpr uint8_t SHT31_ADDRESS = 0x44;

// Capacitive soil sensor analog output. Change pin/calibration to match wiring.
// Set -1 to disable soil sensor.
static constexpr int SOIL_SENSOR_ADC_PIN = -1;
static constexpr int SOIL_ADC_DRY = 3000;
static constexpr int SOIL_ADC_WET = 1200;

static constexpr size_t MAX_SENSORS = 16;
static constexpr size_t MAX_AUTOMATION_RULES = 8;
static constexpr size_t MAX_SCHEDULE_RULES = 32;
static constexpr size_t MAX_DECISION_REASONS = 6;
static constexpr uint32_t MAX_AUTOMATION_RUNTIME_SECONDS = 86400;
static constexpr uint32_t MAX_SCHEDULE_WINDOW_SECONDS = 86340;
static constexpr size_t MAX_EVENT_LOGS = 24;
static constexpr size_t MAX_JSON_LINE = 3072;
static constexpr size_t RELAY_COUNT = 8;

// ESP32-S3 N16R8 44-pin board. RTC remains on GPIO8/GPIO9.
// Relay board is Active HIGH and all eight control pins are on one header side.
static constexpr int RELAY_PINS[RELAY_COUNT] = {
    4, 5, 6, 7, 15, 16, 17, 18};
static constexpr bool RELAY_ACTIVE_LOW = false;
static constexpr bool RESTORE_RELAY_STATE_AFTER_POWER_LOSS = true;

static constexpr uint32_t SENSOR_EVENT_INTERVAL_MS = 3000;
static constexpr uint32_t DEFAULT_MANUAL_OVERRIDE_SECONDS = 300;
static constexpr uint32_t WIFI_CONNECT_TIMEOUT_MS = 15000;
static constexpr uint32_t WIFI_RECONNECT_INTERVAL_MS = 15000;
