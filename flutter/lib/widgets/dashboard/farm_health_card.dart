import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/sf_animation.dart';
import '../../core/theme/sf_colors.dart';
import '../../core/theme/sf_radius.dart';
import '../../core/theme/sf_spacing.dart';
import '../../core/theme/sf_text_styles.dart';
import '../../core/widgets/sf_card.dart';
import '../../models/sensor_data.dart';

class FarmHealthCard extends StatelessWidget {
  final SensorData data;
  final int activeDeviceCount;
  final int totalDeviceCount;

  const FarmHealthCard({
    super.key,
    required this.data,
    required this.activeDeviceCount,
    required this.totalDeviceCount,
  });

  @override
  Widget build(BuildContext context) {
    final int score = _calculateHealthScore();
    final _HealthStatus status = _getHealthStatus(context, score);

    return SFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: SFRadius.medium,
                ),
                child: Icon(status.icon, color: status.color, size: 27),
              ),
              SFSpacing.horizontalSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('สุขภาพฟาร์ม', 'Farm Health'),
                      style: SFTextStyles.title,
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.l10n.text(
                        'ประเมินจากข้อมูลระบบล่าสุด',
                        'Based on the latest system data',
                      ),
                      style: SFTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.11),
                  borderRadius: SFRadius.pill,
                ),
                child: Text(
                  status.label,
                  style: SFTextStyles.label.copyWith(color: status.color),
                ),
              ),
            ],
          ),
          SFSpacing.verticalLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: score.toDouble()),
                duration: SFAnimation.slow,
                curve: SFAnimation.standardCurve,
                builder: (context, value, _) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: SFTextStyles.display.copyWith(
                      color: status.color,
                      fontSize: 42,
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(left: 3, bottom: 5),
                child: Text('/100', style: SFTextStyles.bodySecondary),
              ),
              const Spacer(),
              Text(
                context.l10n.text(
                  '$activeDeviceCount/$totalDeviceCount อุปกรณ์ทำงาน',
                  '$activeDeviceCount/$totalDeviceCount devices active',
                ),
                style: SFTextStyles.caption,
              ),
            ],
          ),
          SFSpacing.verticalSm,
          ClipRRect(
            borderRadius: SFRadius.pill,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: score / 100),
              duration: SFAnimation.slow,
              curve: SFAnimation.standardCurve,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  color: status.color,
                  backgroundColor: status.color.withValues(alpha: 0.10),
                );
              },
            ),
          ),
          SFSpacing.verticalMd,
          Wrap(
            spacing: SFSpacing.xs,
            runSpacing: SFSpacing.xs,
            children: [
              _HealthItem(
                label: context.l10n.text('อุณหภูมิ', 'Temperature'),
                healthy: data.temperature >= 20 && data.temperature <= 35,
              ),
              _HealthItem(
                label: context.l10n.text('ความชื้น', 'Humidity'),
                healthy: data.humidity >= 40 && data.humidity <= 85,
              ),
              _HealthItem(
                label: context.l10n.text('ความชื้นดิน', 'Soil Moisture'),
                healthy: data.soilMoisture >= 40,
              ),
              _HealthItem(
                label: context.l10n.text('ระดับน้ำ', 'Water Level'),
                healthy: data.waterLevel >= 20,
              ),
              _HealthItem(
                label: context.l10n.text('แบตเตอรี่', 'Battery'),
                healthy: data.battery >= 25,
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateHealthScore() {
    int score = 100;

    if (data.temperature < 20 || data.temperature > 35) {
      score -= 15;
    }

    if (data.humidity < 40 || data.humidity > 85) {
      score -= 10;
    }

    if (data.soilMoisture < 40) {
      score -= 20;
    }

    if (data.waterLevel < 20) {
      score -= 25;
    }

    if (data.battery < 25) {
      score -= 20;
    }

    if (totalDeviceCount > 0 && activeDeviceCount == 0) {
      score -= 5;
    }

    return score.clamp(0, 100);
  }

  _HealthStatus _getHealthStatus(BuildContext context, int score) {
    if (score >= 90) {
      return _HealthStatus(
        label: context.l10n.text('ยอดเยี่ยม', 'Excellent'),
        color: SFColors.success,
        icon: Icons.verified_rounded,
      );
    }

    if (score >= 70) {
      return _HealthStatus(
        label: context.l10n.text('ปกติ', 'Normal'),
        color: SFColors.info,
        icon: Icons.health_and_safety_rounded,
      );
    }

    if (score >= 45) {
      return _HealthStatus(
        label: context.l10n.text('ควรตรวจสอบ', 'Check Required'),
        color: SFColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    }

    return _HealthStatus(
      label: context.l10n.text('วิกฤต', 'Critical'),
      color: SFColors.danger,
      icon: Icons.error_rounded,
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final bool healthy;

  const _HealthItem({required this.label, required this.healthy});

  @override
  Widget build(BuildContext context) {
    final Color color = healthy ? SFColors.success : SFColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: SFRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            healthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(label, style: SFTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _HealthStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _HealthStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}
