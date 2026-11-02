import 'package:flutter/material.dart';

abstract final class SFColors {
  // Brand
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF185A2C);
  static const Color primaryLight = Color(0xFF76C982);
  static const Color secondary = Color(0xFF5B8C62);

  // Background and surfaces
  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF17251C);
  static const Color border = Color(0xFFE2E8E3);

  // Text
  static const Color textPrimary = Color(0xFF172019);
  static const Color textSecondary = Color(0xFF667069);
  static const Color textDisabled = Color(0xFF9EA6A0);

  // System status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF28C28);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF2878C7);

  // Control modes
  static const Color manual = Color(0xFF2878C7);
  static const Color schedule = Color(0xFF7656C9);
  static const Color automatic = Color(0xFF2E7D32);

  const SFColors._();
}
