import 'dart:async';

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/sf_animation.dart';
import '../core/theme/sf_colors.dart';
import '../core/theme/sf_text_styles.dart';
import '../stores/settings_store.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.settingsStore});

  final SettingsStore settingsStore;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _visible = true;
      });
    });

    _navigationTimer = Timer(
      const Duration(milliseconds: 1800),
      _openMainScreen,
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _openMainScreen() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: SFAnimation.normal,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MainScreen(settingsStore: widget.settingsStore);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colors.surface : const Color(0xFFF8FAF7),
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: SFAnimation.slow,
            curve: SFAnimation.standardCurve,
            child: AnimatedScale(
              scale: _visible ? 1 : 0.88,
              duration: SFAnimation.slow,
              curve: SFAnimation.bounceCurve,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colors.surfaceContainerHighest
                            : Colors.white,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: [
                          BoxShadow(
                            color: SFColors.primary.withValues(alpha: 0.16),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(31),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Smart Farm+',
                      style: SFTextStyles.display.copyWith(
                        color: isDark ? colors.onSurface : SFColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.text(
                        'ระบบควบคุมสวนอัจฉริยะ',
                        'Smart farming control system',
                      ),
                      textAlign: TextAlign.center,
                      style: SFTextStyles.bodySecondary.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'RTPM • ElecBI-CEC',
                      style: SFTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-assisted development with ChatGPT',
                      style: SFTextStyles.caption.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
