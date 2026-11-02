import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  static const _farmNameKey = 'settings.farmName';
  static const _controllerNameKey = 'settings.controllerName';
  static const _controllerIdKey = 'settings.controllerId';
  static const _controllerOnlineKey = 'settings.controllerOnline';
  static const _controllerBaseUrlKey = 'settings.controllerBaseUrl';
  static const _controllerAutoReconnectKey = 'settings.controllerAutoReconnect';
  static const _wifiNameKey = 'settings.wifiName';
  static const _notificationsKey = 'settings.notifications';
  static const _themeKey = 'settings.theme';
  static const _languageKey = 'settings.language';
  static const _cloudSignedInKey = 'settings.cloudSignedIn';
  static const _automaticTimeKey = 'settings.automaticTime';

  Future<AppSettings> load() async {
    final defaults = AppSettings.defaults();

    final themeName = await _preferences.getString(_themeKey);
    final languageCode = await _preferences.getString(_languageKey);

    return AppSettings(
      farmName: await _preferences.getString(_farmNameKey) ?? defaults.farmName,
      controllerName:
          await _preferences.getString(_controllerNameKey) ??
          defaults.controllerName,
      controllerId:
          await _preferences.getString(_controllerIdKey) ??
          defaults.controllerId,
      controllerOnline:
          await _preferences.getBool(_controllerOnlineKey) ??
          defaults.controllerOnline,
      controllerBaseUrl:
          await _preferences.getString(_controllerBaseUrlKey) ??
          defaults.controllerBaseUrl,
      controllerAutoReconnect:
          await _preferences.getBool(_controllerAutoReconnectKey) ??
          defaults.controllerAutoReconnect,
      wifiName: await _preferences.getString(_wifiNameKey),
      notificationsEnabled:
          await _preferences.getBool(_notificationsKey) ??
          defaults.notificationsEnabled,
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => defaults.themeMode,
      ),
      languageCode: languageCode == 'en' ? 'en' : 'th',
      cloudSignedIn:
          await _preferences.getBool(_cloudSignedInKey) ??
          defaults.cloudSignedIn,
      useAutomaticTime:
          await _preferences.getBool(_automaticTimeKey) ??
          defaults.useAutomaticTime,
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait<void>([
      _preferences.setString(_farmNameKey, settings.farmName),
      _preferences.setString(_controllerNameKey, settings.controllerName),
      _preferences.setString(_controllerIdKey, settings.controllerId),
      _preferences.setBool(_controllerOnlineKey, settings.controllerOnline),
      _preferences.setString(_controllerBaseUrlKey, settings.controllerBaseUrl),
      _preferences.setBool(
        _controllerAutoReconnectKey,
        settings.controllerAutoReconnect,
      ),
      _preferences.setBool(_notificationsKey, settings.notificationsEnabled),
      _preferences.setString(_themeKey, settings.themeMode.name),
      _preferences.setString(_languageKey, settings.languageCode),
      _preferences.setBool(_cloudSignedInKey, settings.cloudSignedIn),
      _preferences.setBool(_automaticTimeKey, settings.useAutomaticTime),
    ]);

    final wifiName = settings.wifiName;
    if (wifiName == null || wifiName.isEmpty) {
      await _preferences.remove(_wifiNameKey);
    } else {
      await _preferences.setString(_wifiNameKey, wifiName);
    }
  }
}
