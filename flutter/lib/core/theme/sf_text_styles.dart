import 'package:flutter/material.dart';

abstract final class SFTextStyles {
  static const TextStyle display = TextStyle(
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  const SFTextStyles._();
}
