#include "RelayManager.h"

namespace {
constexpr char RELAY_STATE_MASK_KEY[] = "relayMask";
constexpr char RELAY_STATE_VALID_KEY[] = "relayValid";
}

void RelayManager::begin(Preferences &preferences) {
  _preferences = &preferences;
  _hasPersistedState =
      RESTORE_RELAY_STATE_AFTER_POWER_LOSS &&
      _preferences->getBool(RELAY_STATE_VALID_KEY, false);
  _persistedMask = _hasPersistedState
                       ? _preferences->getUInt(RELAY_STATE_MASK_KEY, 0)
                       : 0;

  // Establish the electrically inactive level before GPIO becomes an output.
  // This minimizes boot-time relay pulses on both active-HIGH and active-LOW boards.
  for (size_t i = 0; i < RELAY_COUNT; i++) {
    // Always start safe. Persisted state is restored only after device profiles
    // are loaded, so automation-owned channels can be excluded.
    _relays[i].on = false;
    _relays[i].name = "Relay " + String(i + 1);
    if (RELAY_PINS[i] >= 0) {
      const bool inactiveLevel = RELAY_ACTIVE_LOW ? HIGH : LOW;
      digitalWrite(RELAY_PINS[i], inactiveLevel);
      pinMode(RELAY_PINS[i], OUTPUT);
    }
  }

  // Apply the safe OFF state. Manual persisted state is restored later from
  // setup(), after ScheduleAutomationEngine has exposed its owned channels.
  for (size_t i = 0; i < RELAY_COUNT; i++) applyHardware(i);

  // Create a valid persisted baseline on the first boot without one.
  if (!_hasPersistedState && RESTORE_RELAY_STATE_AFTER_POWER_LOSS) {
    persistState();
  }
}

bool RelayManager::set(size_t channel, bool on) {
  if (channel >= RELAY_COUNT) return false;
  if (_relays[channel].on == on) {
    applyHardware(channel);
    return true;
  }
  _relays[channel].on = on;
  applyHardware(channel);
  persistState();
  return true;
}


bool RelayManager::setTransient(size_t channel, bool on, bool *changed) {
  if (changed) *changed = false;
  if (channel >= RELAY_COUNT) return false;
  if (_relays[channel].on == on) return true;
  _relays[channel].on = on;
  applyHardware(channel);
  if (changed) *changed = true;
  return true;
}

void RelayManager::restorePersistedManualState(uint32_t excludedChannelsMask) {
  for (size_t channel = 0; channel < RELAY_COUNT; ++channel) {
    const bool excluded = (excludedChannelsMask & (1UL << channel)) != 0;
    const bool restoreOn = _hasPersistedState && !excluded &&
                           ((_persistedMask & (1UL << channel)) != 0);
    _relays[channel].on = restoreOn;
    applyHardware(channel);
  }

  // Remove stale automation output bits from storage. Future transient
  // schedule/sensor changes do not update the persisted manual mask.
  persistState();
}

void RelayManager::clearPersistedChannel(size_t channel) {
  if (channel >= RELAY_COUNT) return;
  _persistedMask &= ~(1UL << channel);
  persistState();
}

bool RelayManager::toggle(size_t channel) {
  if (channel >= RELAY_COUNT) return false;
  return set(channel, !_relays[channel].on);
}

bool RelayManager::get(size_t channel) const {
  return channel < RELAY_COUNT ? _relays[channel].on : false;
}

size_t RelayManager::count() const { return RELAY_COUNT; }

void RelayManager::writeJson(JsonArray array) const {
  for (size_t i = 0; i < RELAY_COUNT; i++) {
    JsonObject item = array.add<JsonObject>();
    item["channel"] = i;
    item["name"] = _relays[i].name;
    item["on"] = _relays[i].on;
    item["gpio"] = RELAY_PINS[i];
    item["virtual"] = RELAY_PINS[i] < 0;
    item["physicalConfigured"] = RELAY_PINS[i] >= 0;
    item["activeLow"] = RELAY_ACTIVE_LOW;
    item["powerLossRestoreEnabled"] = RESTORE_RELAY_STATE_AFTER_POWER_LOSS;
    item["restoredFromStorage"] = _hasPersistedState;
  }
}

void RelayManager::applyHardware(size_t channel) {
  if (channel >= RELAY_COUNT || RELAY_PINS[channel] < 0) return;
  const bool outputLevel =
      RELAY_ACTIVE_LOW ? !_relays[channel].on : _relays[channel].on;
  digitalWrite(RELAY_PINS[channel], outputLevel ? HIGH : LOW);
}

uint32_t RelayManager::currentMask() const {
  uint32_t mask = 0;
  for (size_t i = 0; i < RELAY_COUNT && i < 32; i++) {
    if (_relays[i].on) mask |= (1UL << i);
  }
  return mask;
}

void RelayManager::persistState() {
  if (!_preferences || !RESTORE_RELAY_STATE_AFTER_POWER_LOSS) return;
  const uint32_t mask = currentMask();
  if (_hasPersistedState && mask == _persistedMask) return;

  // Write the mask first and validity marker last. A power loss between writes
  // can only leave the previous valid state or a complete new state.
  _preferences->putUInt(RELAY_STATE_MASK_KEY, mask);
  _preferences->putBool(RELAY_STATE_VALID_KEY, true);
  _persistedMask = mask;
  _hasPersistedState = true;
}
