import 'package:flutter/material.dart';

import '../theme/sf_colors.dart';
import '../theme/sf_radius.dart';
import '../theme/sf_text_styles.dart';

enum SFStatus { online, offline, warning, alarm, manual, schedule, automatic }

class SFStatusBadge extends StatelessWidget {
  final SFStatus status;
  final String? label;

  const SFStatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final text = label ?? _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: SFRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: SFTextStyles.label.copyWith(color: color)),
        ],
      ),
    );
  }

  Color _statusColor(SFStatus status) {
    switch (status) {
      case SFStatus.online:
      case SFStatus.automatic:
        return SFColors.success;
      case SFStatus.offline:
        return SFColors.textDisabled;
      case SFStatus.warning:
        return SFColors.warning;
      case SFStatus.alarm:
        return SFColors.danger;
      case SFStatus.manual:
        return SFColors.manual;
      case SFStatus.schedule:
        return SFColors.schedule;
    }
  }

  String _statusLabel(SFStatus status) {
    switch (status) {
      case SFStatus.online:
        return 'ออนไลน์';
      case SFStatus.offline:
        return 'ออฟไลน์';
      case SFStatus.warning:
        return 'คำเตือน';
      case SFStatus.alarm:
        return 'แจ้งเตือน';
      case SFStatus.manual:
        return 'Manual';
      case SFStatus.schedule:
        return 'Schedule';
      case SFStatus.automatic:
        return 'Auto';
    }
  }
}
