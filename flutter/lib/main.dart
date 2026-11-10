import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/theme/sf_theme.dart';
import 'models/app_settings.dart';
import 'screens/splash_screen.dart';
import 'stores/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsStore = SettingsStore();
  await settingsStore.initialize();

  runApp(SmartFarmApp(settingsStore: settingsStore));
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key, required this.settingsStore});

  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (context, _) {
        final settings = settingsStore.settings;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smartfarm+',
          theme: SFTheme.light,
          darkTheme: SFTheme.dark,
          themeMode: switch (settings.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          locale: Locale(settings.languageCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashScreen(settingsStore: settingsStore),
        );
      },
    );
  }
}
