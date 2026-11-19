#pragma once
#include <Arduino.h>
#include <Wire.h>
#include "Config.h"

struct ClockSnapshot {
  bool available = false;
  bool valid = false;
  bool lostPower = false;
  bool synchronized = false;
  uint16_t year = 0;
  uint8_t month = 0, day = 0, dayOfWeek = 0, hour = 0, minute = 0, second = 0;
  float chipTemperatureC = NAN;
  uint32_t lastSyncEpoch = 0;
  uint32_t readFailures = 0;
  String quality = "unavailable";
  String errorCode = "not_started";
};

class ClockService {
 public:
  bool begin(TwoWire &wire = Wire);
  void update();
  ClockSnapshot snapshot() const { return _snapshot; }
  bool setLocalTime(uint16_t year, uint8_t month, uint8_t day, uint8_t dayOfWeek,
                    uint8_t hour, uint8_t minute, uint8_t second);
  bool minuteKey(char *buffer, size_t size) const;
  bool dateTimeIso(char *buffer, size_t size) const;
  bool rawDateTimeIso(char *buffer, size_t size) const;
  uint32_t epochLocal() const;
  int32_t secondsUntil(uint8_t dayOfWeek, uint8_t hour, uint8_t minute) const;
 private:
  TwoWire *_wire = nullptr;
  ClockSnapshot _snapshot;
  uint32_t _lastReadMs = 0;
  static uint8_t bcdToDec(uint8_t value);
  static uint8_t decToBcd(uint8_t value);
  static bool isLeapYear(uint16_t year);
  static uint8_t daysInMonth(uint16_t year, uint8_t month);
  bool readRtc();
  bool readTemperature();
  bool probe() const;
  bool recordReadFailure(const char *errorCode, bool deviceMissing);
  void updateQuality();
  static constexpr uint8_t kTransientFailureThreshold = 3;
};
