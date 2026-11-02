import 'package:flutter/widgets.dart';

abstract final class SFRadius {
  static const double smallValue = 10;
  static const double mediumValue = 16;
  static const double largeValue = 22;
  static const double extraLargeValue = 30;
  static const double pillValue = 999;

  static const BorderRadius small = BorderRadius.all(
    Radius.circular(smallValue),
  );

  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(mediumValue),
  );

  static const BorderRadius large = BorderRadius.all(
    Radius.circular(largeValue),
  );

  static const BorderRadius extraLarge = BorderRadius.all(
    Radius.circular(extraLargeValue),
  );

  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));

  const SFRadius._();
}
