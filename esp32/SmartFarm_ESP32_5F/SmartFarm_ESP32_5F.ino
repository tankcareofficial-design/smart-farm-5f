#include <Arduino.h>
#include <Wire.h>
#include <Preferences.h>
#include "ProvisioningResetManager.h"
#include <ArduinoJson.h>
#include "Config.h"
#include "Protocol.h"
#include "SensorRegistry.h"
#include "RelayManager.h"
#include "StateManager.h"
#include "AutomationEngine.h"
#include "EventLog.h"
#include "WiFiTransport.h"
#include "ClockService.h"
#include "ScheduleAutomationEngine.h"
#include "SystemHealthManager.h"

Preferences preferences;
ProvisioningResetManager provisioningResetManager;
SensorRegistry sensorRegistry;
RelayManager relayManager;
StateManager stateManager;
AutomationEngine automationEngine;
EventLog eventLog;
Protocol protocol;
WiFiTransport wifiTransport;
ClockService clockService;
ScheduleAutomationEngine scheduleAutomationEngine;
SystemHealthManager systemHealthManager;
String deviceId;

static String createDeviceId() {
  const uint64_t chipId = ESP.getEfuseMac();
  char buffer[32];
  snprintf(buffer, sizeof(buffer), "sf-%04X%08X",
           static_cast<uint16_t>(chipId >> 32), static_cast<uint32_t>(chipId));
  return String(buffer);
}

void setup() {
  Serial.begin(SERIAL_BAUD);
  provisioningResetManager.begin();
  delay(1200);
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN, I2C_FREQUENCY);
  preferences.begin("smart-farm", false);

  deviceId = preferences.getString("deviceId", "");
  if (deviceId.isEmpty()) {
    deviceId = createDeviceId();
    preferences.putString("deviceId", deviceId);
  }

  sensorRegistry.begin(preferences);
  relayManager.begin(preferences);
  automationEngine.begin(preferences, relayManager, eventLog);
  clockService.begin(Wire);
  stateManager.begin(relayManager, automationEngine);
  scheduleAutomationEngine.begin(preferences, clockService, relayManager, eventLog, stateManager);
  const uint32_t automationRelayMask = scheduleAutomationEngine.controlledRelayMask();
  automationEngine.setAutomationControlledMask(automationRelayMask);
  relayManager.restorePersistedManualState(automationRelayMask);
  eventLog.add("relay_recovery", "Manual relay state restored after automation channels were excluded");
  systemHealthManager.begin(clockService, stateManager, relayManager);
  protocol.begin(deviceId, preferences, sensorRegistry, relayManager,
                 stateManager, automationEngine, eventLog);
  wifiTransport.begin(deviceId, relayManager, stateManager, automationEngine, protocol, clockService, scheduleAutomationEngine, systemHealthManager);

  Serial.println();
  Serial.println("Smart Farm+ Controller");
  Serial.printf("Firmware: %s\n", FW_VERSION);
  Serial.printf("Device ID: %s\n", deviceId.c_str());
  Serial.printf("Protocol: %u\n", PROTOCOL_VERSION);
  Serial.printf("Mock hardware: %s\n", USE_MOCK_HARDWARE_SCAN ? "ON" : "OFF");
  const ClockSnapshot rtc = clockService.snapshot();
  Serial.printf("RTC: available=%s valid=%s quality=%s error=%s SDA=%d SCL=%d\n",
                rtc.available ? "YES" : "NO", rtc.valid ? "YES" : "NO",
                rtc.quality.c_str(), rtc.errorCode.c_str(), I2C_SDA_PIN, I2C_SCL_PIN);
  Serial.printf("Physical relay GPIO configured: ");
  for (size_t i = 0; i < RELAY_COUNT; ++i) {
    Serial.printf("CH%u=%d%s", static_cast<unsigned>(i + 1), RELAY_PINS[i],
                  i + 1 == RELAY_COUNT ? "\n" : ", ");
  }
  Serial.println("Automation Engine: READY");
  Serial.println("Serial JSON and HTTP API ready.");
  eventLog.add("system", "Controller started");
  protocol.sendSystemReady();
}

void loop() {
  provisioningResetManager.update();
  protocol.poll();
  wifiTransport.poll();
  automationEngine.updateOverrides(protocol);
  scheduleAutomationEngine.update(wifiTransport.emergencyLatched());
  systemHealthManager.update(wifiTransport.emergencyLatched());
  stateManager.update(protocol);
  delay(2);
}
