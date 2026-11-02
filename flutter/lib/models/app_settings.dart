enum AppThemeMode { system, light, dark }

class AppSettings {
  const AppSettings({
    required this.farmName,
    required this.controllerName,
    required this.controllerId,
    required this.controllerOnline,
    required this.controllerBaseUrl,
    required this.controllerAutoReconnect,
    required this.wifiName,
    required this.notificationsEnabled,
    required this.themeMode,
    required this.languageCode,
    required this.cloudSignedIn,
    required this.useAutomaticTime,
  });

  final String farmName;
  final String controllerName;
  final String controllerId;
  final bool controllerOnline;
  final String controllerBaseUrl;
  final bool controllerAutoReconnect;
  final String? wifiName;

  bool get controllerConfigured => controllerId != 'ยังไม่ได้เชื่อมต่อ';
  final bool notificationsEnabled;
  final AppThemeMode themeMode;
  final String languageCode;
  final bool cloudSignedIn;
  final bool useAutomaticTime;

  factory AppSettings.defaults() {
    return const AppSettings(
      farmName: 'สวนของฉัน',
      controllerName: 'กล่องควบคุมฟาร์ม',
      controllerId: 'ยังไม่ได้เชื่อมต่อ',
      controllerOnline: false,
      controllerBaseUrl: 'http://192.168.4.1',
      controllerAutoReconnect: true,
      wifiName: null,
      notificationsEnabled: true,
      themeMode: AppThemeMode.light,
      languageCode: 'th',
      cloudSignedIn: false,
      useAutomaticTime: true,
    );
  }

  AppSettings copyWith({
    String? farmName,
    String? controllerName,
    String? controllerId,
    bool? controllerOnline,
    String? controllerBaseUrl,
    bool? controllerAutoReconnect,
    String? wifiName,
    bool clearWifiName = false,
    bool? notificationsEnabled,
    AppThemeMode? themeMode,
    String? languageCode,
    bool? cloudSignedIn,
    bool? useAutomaticTime,
  }) {
    return AppSettings(
      farmName: farmName ?? this.farmName,
      controllerName: controllerName ?? this.controllerName,
      controllerId: controllerId ?? this.controllerId,
      controllerOnline: controllerOnline ?? this.controllerOnline,
      controllerBaseUrl: controllerBaseUrl ?? this.controllerBaseUrl,
      controllerAutoReconnect:
          controllerAutoReconnect ?? this.controllerAutoReconnect,
      wifiName: clearWifiName ? null : wifiName ?? this.wifiName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      cloudSignedIn: cloudSignedIn ?? this.cloudSignedIn,
      useAutomaticTime: useAutomaticTime ?? this.useAutomaticTime,
    );
  }
}
