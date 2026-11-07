#include "ClockService.h"

uint8_t ClockService::bcdToDec(uint8_t v) { return (v >> 4) * 10 + (v & 0x0F); }
uint8_t ClockService::decToBcd(uint8_t v) { return ((v / 10) << 4) | (v % 10); }
bool ClockService::isLeapYear(uint16_t y) { return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0); }
uint8_t ClockService::daysInMonth(uint16_t y, uint8_t m) {
  static const uint8_t days[] = {31,28,31,30,31,30,31,31,30,31,30,31};
  if (m < 1 || m > 12) return 0;
  return (m == 2 && isLeapYear(y)) ? 29 : days[m - 1];
}

bool ClockService::probe() const {
  if (!_wire) return false;
  _wire->beginTransmission(DS3231_ADDRESS);
  return _wire->endTransmission() == 0;
}

bool ClockService::begin(TwoWire &wire) {
  _wire = &wire;
  _snapshot.synchronized = false;
  _snapshot.available = false;
  _snapshot.valid = false;
  _snapshot.readFailures = 0;
  _snapshot.errorCode = "not_started";
  return readRtc();
}

void ClockService::update() {
  if (millis() - _lastReadMs < 500) return;
  _lastReadMs = millis();
  readRtc();
}

void ClockService::updateQuality() {
  if (!_snapshot.available) _snapshot.quality = "unavailable";
  else if (_snapshot.lostPower) _snapshot.quality = "lost_power";
  else if (!_snapshot.valid) _snapshot.quality = "invalid";
  else if (_snapshot.readFailures > 0) _snapshot.quality = "degraded";
  else if (_snapshot.synchronized) _snapshot.quality = "synchronized";
  else _snapshot.quality = "rtc";
}

bool ClockService::recordReadFailure(const char *errorCode, bool deviceMissing) {
  const bool hadVerifiedClock = _snapshot.valid;
  _snapshot.readFailures++;

  // Do not invalidate a previously verified clock on a single I2C miss.
  // After three consecutive transport failures, fail safe and block schedule.
  if (!hadVerifiedClock || _snapshot.readFailures >= kTransientFailureThreshold) {
    if (deviceMissing) _snapshot.available = false;
    _snapshot.valid = false;
    _snapshot.errorCode = errorCode;
  } else {
    _snapshot.errorCode = String(errorCode) + "_transient";
  }

  updateQuality();
  return false;
}

bool ClockService::readTemperature() {
  _wire->beginTransmission(DS3231_ADDRESS);
  _wire->write(static_cast<uint8_t>(0x11));
  if (_wire->endTransmission(false) != 0) return false;
  if (_wire->requestFrom(static_cast<int>(DS3231_ADDRESS), 2) != 2) return false;
  const int8_t msb = static_cast<int8_t>(_wire->read());
  const uint8_t lsb = _wire->read();
  _snapshot.chipTemperatureC = static_cast<float>(msb) + ((lsb >> 6) * 0.25f);
  return true;
}

bool ClockService::readRtc() {
  if (!probe()) {
    return recordReadFailure("device_not_found", true);
  }
  _snapshot.available = true;

  _wire->beginTransmission(DS3231_ADDRESS);
  _wire->write(static_cast<uint8_t>(0x00));
  if (_wire->endTransmission(false) != 0 ||
      _wire->requestFrom(static_cast<int>(DS3231_ADDRESS), 7) != 7) {
    return recordReadFailure("i2c_read_failed", false);
  }

  const uint8_t second = bcdToDec(_wire->read() & 0x7F);
  const uint8_t minute = bcdToDec(_wire->read() & 0x7F);
  const uint8_t hour = bcdToDec(_wire->read() & 0x3F);
  const uint8_t dayOfWeek = bcdToDec(_wire->read() & 0x07);
  const uint8_t day = bcdToDec(_wire->read() & 0x3F);
  const uint8_t month = bcdToDec(_wire->read() & 0x1F);
  const uint16_t year = 2000 + bcdToDec(_wire->read());

  _wire->beginTransmission(DS3231_ADDRESS);
  _wire->write(static_cast<uint8_t>(0x0F));
  if (_wire->endTransmission(false) != 0 ||
      _wire->requestFrom(static_cast<int>(DS3231_ADDRESS), 1) != 1) {
    return recordReadFailure("status_read_failed", false);
  }
  const bool lostPower = (_wire->read() & 0x80) != 0;

  const uint8_t maxDay = daysInMonth(year, month);
  const bool dateTimeValid = year >= 2025 && year <= 2099 &&
                             month >= 1 && month <= 12 &&
                             day >= 1 && day <= maxDay &&
                             dayOfWeek >= 1 && dayOfWeek <= 7 &&
                             hour < 24 && minute < 60 && second < 60;

  // Commit the time atomically only after all required RTC registers
  // (time + status) have been read successfully.
  _snapshot.year = year;
  _snapshot.month = month;
  _snapshot.day = day;
  _snapshot.dayOfWeek = dayOfWeek;
  _snapshot.hour = hour;
  _snapshot.minute = minute;
  _snapshot.second = second;
  _snapshot.lostPower = lostPower;
  _snapshot.valid = !lostPower && dateTimeValid;
  _snapshot.readFailures = 0;
  _snapshot.errorCode = _snapshot.valid
      ? "none"
      : (lostPower ? "lost_power" : "invalid_datetime");

  // Temperature is diagnostic only. Its read failure must not invalidate
  // the scheduler clock.
  readTemperature();
  updateQuality();
  return _snapshot.valid;
}

bool ClockService::setLocalTime(uint16_t y, uint8_t mo, uint8_t d, uint8_t dow,
                                uint8_t h, uint8_t mi, uint8_t s) {
  if (!_wire || y < 2000 || y > 2099 || mo < 1 || mo > 12 ||
      d < 1 || d > daysInMonth(y, mo) || dow < 1 || dow > 7 ||
      h > 23 || mi > 59 || s > 59) return false;

  _wire->beginTransmission(DS3231_ADDRESS);
  _wire->write(static_cast<uint8_t>(0x00));
  _wire->write(decToBcd(s)); _wire->write(decToBcd(mi)); _wire->write(decToBcd(h));
  _wire->write(decToBcd(dow)); _wire->write(decToBcd(d));
  _wire->write(decToBcd(mo)); _wire->write(decToBcd(y - 2000));
  if (_wire->endTransmission() != 0) return false;

  _wire->beginTransmission(DS3231_ADDRESS);
  _wire->write(static_cast<uint8_t>(0x0F));
  if (_wire->endTransmission(false) == 0 &&
      _wire->requestFrom(static_cast<int>(DS3231_ADDRESS), 1) == 1) {
    const uint8_t status = _wire->read() & ~0x80;
    _wire->beginTransmission(DS3231_ADDRESS);
    _wire->write(static_cast<uint8_t>(0x0F));
    _wire->write(status);
    _wire->endTransmission();
  }
  _snapshot.synchronized = true;
  const bool ok = readRtc();
  if (ok) _snapshot.lastSyncEpoch = epochLocal();
  return ok;
}

bool ClockService::minuteKey(char *buffer, size_t size) const {
  if (!_snapshot.valid || !buffer || size < 18) return false;
  snprintf(buffer, size, "%04u-%02u-%02uT%02u:%02u", _snapshot.year,
           _snapshot.month, _snapshot.day, _snapshot.hour, _snapshot.minute);
  return true;
}

bool ClockService::dateTimeIso(char *buffer, size_t size) const {
  if (!_snapshot.valid || !buffer || size < 20) return false;
  snprintf(buffer, size, "%04u-%02u-%02uT%02u:%02u:%02u", _snapshot.year,
           _snapshot.month, _snapshot.day, _snapshot.hour, _snapshot.minute,
           _snapshot.second);
  return true;
}

bool ClockService::rawDateTimeIso(char *buffer, size_t size) const {
  if (!_snapshot.available || !buffer || size < 20) return false;
  if (_snapshot.year < 2000 || _snapshot.year > 2099 ||
      _snapshot.month < 1 || _snapshot.month > 12 ||
      _snapshot.day < 1 || _snapshot.day > daysInMonth(_snapshot.year, _snapshot.month) ||
      _snapshot.hour > 23 || _snapshot.minute > 59 || _snapshot.second > 59) return false;
  snprintf(buffer, size, "%04u-%02u-%02uT%02u:%02u:%02u", _snapshot.year,
           _snapshot.month, _snapshot.day, _snapshot.hour, _snapshot.minute,
           _snapshot.second);
  return true;
}

uint32_t ClockService::epochLocal() const {
  if (!_snapshot.valid) return 0;
  uint32_t days = 0;
  for (uint16_t y = 1970; y < _snapshot.year; ++y) days += isLeapYear(y) ? 366 : 365;
  for (uint8_t m = 1; m < _snapshot.month; ++m) days += daysInMonth(_snapshot.year, m);
  days += _snapshot.day - 1;
  return days * 86400UL + _snapshot.hour * 3600UL + _snapshot.minute * 60UL + _snapshot.second;
}

int32_t ClockService::secondsUntil(uint8_t dow, uint8_t hour, uint8_t minute) const {
  if (!_snapshot.valid || dow < 1 || dow > 7 || hour > 23 || minute > 59) return -1;
  const int32_t nowSecond = _snapshot.hour * 3600L + _snapshot.minute * 60L + _snapshot.second;
  const int32_t targetSecond = hour * 3600L + minute * 60L;
  int32_t dayDelta = static_cast<int32_t>(dow) - static_cast<int32_t>(_snapshot.dayOfWeek);
  if (dayDelta < 0) dayDelta += 7;
  int32_t result = dayDelta * 86400L + targetSecond - nowSecond;
  if (result <= 0) result += 7 * 86400L;
  return result;
}
