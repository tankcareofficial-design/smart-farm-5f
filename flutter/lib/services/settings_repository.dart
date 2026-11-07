import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  // Preserve the public `preferences:` constructor argument while keeping
  // the backing store private; a field-formal would rename the named argument.
  // ignore: prefer_initializing_formals
  SettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

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
    final preferences = _prefs;

    final themeName = await preferences.getString(_themeKey);
    final languageCode = await preferences.getString(_languageKey);

    return AppSettings(
      farmName: await preferences.getString(_farmNameKey) ?? defaults.farmName,
      controllerName:
          await preferences.getString(_controllerNameKey) ??
          defaults.controllerName,
      controllerId:
          await preferences.getString(_controllerIdKey) ??
          defaults.controllerId,
      controllerOnline:
          await preferences.getBool(_controllerOnlineKey) ??
          defaults.controllerOnline,
      controllerBaseUrl:
          await preferences.getString(_controllerBaseUrlKey) ??
          defaults.controllerBaseUrl,
      controllerAutoReconnect:
          await preferences.getBool(_controllerAutoReconnectKey) ??
          defaults.controllerAutoReconnect,
      wifiName: await preferences.getString(_wifiNameKey),
      notificationsEnabled:
          await preferences.getBool(_notificationsKey) ??
          defaults.notificationsEnabled,
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => defaults.themeMode,
      ),
      languageCode: languageCode == 'en' ? 'en' : 'th',
      cloudSignedIn:
          await preferences.getBool(_cloudSignedInKey) ??
          defaults.cloudSignedIn,
      useAutomaticTime:
          await preferences.getBool(_automaticTimeKey) ??
          defaults.useAutomaticTime,
    );
  }

  Future<void> save(AppSettings settings) async {
    final preferences = _prefs;

    await Future.wait<void>([
      preferences.setString(_farmNameKey, settings.farmName),
      preferences.setString(_controllerNameKey, settings.controllerName),
      preferences.setString(_controllerIdKey, settings.controllerId),
      preferences.setBool(_controllerOnlineKey, settings.controllerOnline),
      preferences.setString(_controllerBaseUrlKey, settings.controllerBaseUrl),
      preferences.setBool(
        _controllerAutoReconnectKey,
        settings.controllerAutoReconnect,
      ),
      preferences.setBool(_notificationsKey, settings.notificationsEnabled),
      preferences.setString(_themeKey, settings.themeMode.name),
      preferences.setString(_languageKey, settings.languageCode),
      preferences.setBool(_cloudSignedInKey, settings.cloudSignedIn),
      preferences.setBool(_automaticTimeKey, settings.useAutomaticTime),
    ]);

    final wifiName = settings.wifiName;
    if (wifiName == null || wifiName.isEmpty) {
      await preferences.remove(_wifiNameKey);
    } else {
      await preferences.setString(_wifiNameKey, wifiName);
    }
  }
}
