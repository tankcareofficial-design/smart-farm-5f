import 'package:flutter/animation.dart';

abstract final class SFAnimation {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;

  const SFAnimation._();
}
