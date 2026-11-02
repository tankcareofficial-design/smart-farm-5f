import 'package:flutter/widgets.dart';

abstract final class SFSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const SizedBox verticalXxs = SizedBox(height: xxs);
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);

  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);

  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  const SFSpacing._();
}
