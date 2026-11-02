import 'package:flutter/material.dart';

import 'sf_colors.dart';
import 'sf_radius.dart';
import 'sf_text_styles.dart';

abstract final class SFTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: SFColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: SFColors.primary,
          secondary: SFColors.secondary,
          surface: SFColors.surface,
          error: SFColors.danger,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SFColors.background,
      fontFamily: null,
      textTheme: const TextTheme(
        displaySmall: SFTextStyles.display,
        headlineSmall: SFTextStyles.headline,
        titleLarge: SFTextStyles.titleLarge,
        titleMedium: SFTextStyles.title,
        bodyMedium: SFTextStyles.body,
        bodySmall: SFTextStyles.bodySecondary,
        labelLarge: SFTextStyles.label,
        labelSmall: SFTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: SFColors.background,
        foregroundColor: SFColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: SFColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SFRadius.large,
          side: BorderSide(color: SFColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: SFColors.surface,
        border: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: SFColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: SFColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: SFColors.primary, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: SFColors.surface,
        indicatorColor: Color(0xFFE4F2E7),
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: const RoundedRectangleBorder(borderRadius: SFRadius.medium),
          textStyle: SFTextStyles.title,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: const RoundedRectangleBorder(borderRadius: SFRadius.medium),
          side: const BorderSide(color: SFColors.border),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const background = Color(0xFF0D120E);
    const surface = Color(0xFF171E18);
    const surfaceContainer = Color(0xFF1D261F);
    const border = Color(0xFF354238);
    const textPrimary = Color(0xFFF1F7F2);
    const textSecondary = Color(0xFFBAC7BC);
    const primary = Color(0xFF85E19A);

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: SFColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          onPrimary: const Color(0xFF06210C),
          secondary: const Color(0xFFA8D98B),
          onSecondary: const Color(0xFF10220D),
          surface: surface,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          outline: border,
          outlineVariant: const Color(0xFF29342B),
          error: const Color(0xFFFF8A80),
          onError: const Color(0xFF370001),
        );

    final baseTextTheme = const TextTheme(
      displaySmall: SFTextStyles.display,
      headlineSmall: SFTextStyles.headline,
      titleLarge: SFTextStyles.titleLarge,
      titleMedium: SFTextStyles.title,
      bodyMedium: SFTextStyles.body,
      bodySmall: SFTextStyles.bodySecondary,
      labelLarge: SFTextStyles.label,
      labelSmall: SFTextStyles.caption,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: baseTextTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: SFRadius.large,
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
        subtitleTextStyle: TextStyle(color: textSecondary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: Color(0xFF87948A)),
        helperStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SFRadius.medium,
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: const Color(0xFF294C31),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: const Color(0xFF06210C),
          shape: const RoundedRectangleBorder(borderRadius: SFRadius.medium),
          textStyle: SFTextStyles.title,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          shape: const RoundedRectangleBorder(borderRadius: SFRadius.medium),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? const Color(0xFF06210C)
              : textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? primary
              : const Color(0xFF3B463D);
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF263129),
        contentTextStyle: TextStyle(color: textPrimary),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  const SFTheme._();
}
