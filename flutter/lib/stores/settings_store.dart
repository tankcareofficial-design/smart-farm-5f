import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_repository.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore({SettingsRepository? repository})
    : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;
  AppSettings _settings = AppSettings.defaults();
  bool _initialized = false;

  AppSettings get settings => _settings;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _settings = await _repository.load();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _commit(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> updateFarmName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _settings.farmName) return;
    await _commit(_settings.copyWith(farmName: trimmed));
  }

  Future<void> updateControllerName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _settings.controllerName) return;
    await _commit(_settings.copyWith(controllerName: trimmed));
  }

  Future<void> applyPairingResult({
    required String controllerId,
    required String controllerName,
    required String wifiName,
    String? controllerBaseUrl,
  }) async {
    await _commit(
      _settings.copyWith(
        controllerId: controllerId,
        controllerName: controllerName,
        controllerOnline: true,
        wifiName: wifiName,
        controllerBaseUrl: controllerBaseUrl ?? _settings.controllerBaseUrl,
      ),
    );
  }

  Future<void> saveRealController({
    required String controllerId,
    required String controllerName,
    required String wifiName,
    String? controllerBaseUrl,
  }) async {
    final String id = controllerId.trim();
    if (id.isEmpty) return;

    await _commit(
      _settings.copyWith(
        controllerId: id,
        controllerName: controllerName.trim().isEmpty
            ? 'กล่องควบคุมฟาร์ม'
            : controllerName.trim(),
        controllerOnline: true,
        wifiName: wifiName.trim().isEmpty ? null : wifiName.trim(),
        controllerBaseUrl: controllerBaseUrl ?? _settings.controllerBaseUrl,
      ),
    );
  }

  Future<void> setControllerBaseUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _settings.controllerBaseUrl) return;
    await _commit(_settings.copyWith(controllerBaseUrl: trimmed));
  }

  Future<void> setControllerAutoReconnect(bool value) async {
    if (value == _settings.controllerAutoReconnect) return;
    await _commit(_settings.copyWith(controllerAutoReconnect: value));
  }

  Future<void> setControllerOnline(bool value) async {
    if (value == _settings.controllerOnline) return;
    await _commit(_settings.copyWith(controllerOnline: value));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (value == _settings.notificationsEnabled) return;
    await _commit(_settings.copyWith(notificationsEnabled: value));
  }

  Future<void> setAutomaticTime(bool value) async {
    if (value == _settings.useAutomaticTime) return;
    await _commit(_settings.copyWith(useAutomaticTime: value));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (mode == _settings.themeMode) return;
    await _commit(_settings.copyWith(themeMode: mode));
  }

  Future<void> setLanguage(String languageCode) async {
    final normalized = languageCode == 'en' ? 'en' : 'th';
    if (normalized == _settings.languageCode) return;
    await _commit(_settings.copyWith(languageCode: normalized));
  }
}
