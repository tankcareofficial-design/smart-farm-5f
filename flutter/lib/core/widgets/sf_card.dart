import 'package:flutter/material.dart';

import '../theme/sf_radius.dart';
import '../theme/sf_spacing.dart';

class SFCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;

  const SFCard({
    super.key,
    required this.child,
    this.padding = SFSpacing.cardPadding,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor = highlighted
        ? colors.primary.withValues(alpha: isDark ? 0.55 : 0.35)
        : colors.outlineVariant;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: SFRadius.large,
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isDark ? 0.18 : 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: SFRadius.large,
        child: content,
      ),
    );
  }
}
