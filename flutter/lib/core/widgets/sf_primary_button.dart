import 'package:flutter/material.dart';

class SFPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  const SFPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(label);

    if (icon == null || loading) {
      return FilledButton(
        onPressed: loading ? null : onPressed,
        child: buttonChild,
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: buttonChild,
    );
  }
}
