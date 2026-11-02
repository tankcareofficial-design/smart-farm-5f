import 'package:flutter/material.dart';

import '../models/sensor_model.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({super.key, required this.sensor});

  final SensorModel sensor;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(sensor.status);
    final value = _formatValue(sensor);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(sensor.icon, color: color),
                ),
                const Spacer(),
                _StatusBadge(status: sensor.status, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              sensor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' ${sensor.unit}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: sensor.normalizedValue),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.10),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              sensor.subtitle ?? 'กำลังรับข้อมูล',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatValue(SensorModel sensor) {
    if (sensor.unit == '°C' || sensor.unit == 'V') {
      return sensor.value.toStringAsFixed(1);
    }

    return sensor.value.toStringAsFixed(0);
  }

  static Color _statusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.online:
        return const Color(0xFF2E7D32);
      case SensorStatus.warning:
        return const Color(0xFFF57C00);
      case SensorStatus.offline:
        return const Color(0xFFD32F2F);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final SensorStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SensorStatus.online => 'ออนไลน์',
      SensorStatus.warning => 'ควรตรวจสอบ',
      SensorStatus.offline => 'ออฟไลน์',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
