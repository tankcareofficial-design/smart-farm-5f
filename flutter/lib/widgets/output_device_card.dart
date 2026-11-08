import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../models/output_device.dart';

class OutputDeviceCard extends StatelessWidget {
  const OutputDeviceCard({
    super.key,
    required this.device,
    required this.onStateChanged,
    required this.onEdit,
    required this.onDelete,
    this.commandPending = false,
    this.controllerConnected = false,
    this.emergencyLocked = false,
  });

  final OutputDevice device;
  final ValueChanged<bool> onStateChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool commandPending;
  final bool controllerConnected;
  final bool emergencyLocked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = device.isOn || device.runtimeState == 'running';
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: active
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    device.icon,
                    color: active ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _runtimeText(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: context.l10n.text('เมนูอุปกรณ์', 'Device menu'),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined),
                          const SizedBox(width: 10),
                          Text(context.l10n.text('แก้ไข', 'Edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: colors.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            context.l10n.text('ลบ', 'Delete'),
                            style: TextStyle(color: colors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(text: 'CH ${device.channel}'),
                _Badge(text: _typeName(context)),
                _Badge(
                  text: controllerConnected
                      ? context.l10n.text('ออนไลน์', 'Online')
                      : context.l10n.text('ออฟไลน์', 'Offline'),
                ),
                _Badge(text: _modeName(context)),
              ],
            ),
            if (device.schedule.enabled || device.condition.enabled) ...[
              const SizedBox(height: 10),
              Text(
                _configurationText(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    active
                        ? context.l10n.text('คำสั่งหยุดอุปกรณ์', 'Stop device')
                        : context.l10n.text(
                            'ส่งคำขอเปิดอุปกรณ์',
                            'Request device start',
                          ),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (commandPending)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                Switch.adaptive(
                  value: commandPending
                      ? device.requestedOn
                      : device.requestedOn || active,
                  onChanged:
                      device.enabled && !emergencyLocked ? onStateChanged : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _runtimeText(BuildContext context) {
    if (device.runtimeState == 'running' || device.isOn) {
      return context.l10n.text('กำลังทำงาน', 'Running');
    }
    if (!device.requestedOn) return context.l10n.text('ปิดอยู่', 'Off');
    if (device.remainingSeconds > 0) {
      final h = device.remainingSeconds ~/ 3600;
      final m = (device.remainingSeconds % 3600) ~/ 60;
      return context.l10n.text(
        'รับคำขอแล้ว • เหลือ ${h > 0 ? '$h ชม. ' : ''}$m นาที',
        'Request accepted • ${h > 0 ? '${h}h ' : ''}${m}m remaining',
      );
    }
    if (device.waitingReason.isNotEmpty) {
      return context.l10n.text(
        'รับคำขอแล้ว • ${device.waitingReason}',
        'Request accepted • ${device.waitingReason}',
      );
    }
    if (device.condition.enabled) {
      return context.l10n.text(
        'กำลังรอเงื่อนไขเซ็นเซอร์',
        'Waiting for sensor rule',
      );
    }
    if (device.schedule.enabled) {
      return context.l10n.text('กำลังรอเวลาที่กำหนด', 'Waiting for schedule');
    }
    return context.l10n.text(
      'รับคำขอแล้ว • กำลังประเมิน',
      'Request accepted • evaluating',
    );
  }

  String _configurationText(BuildContext context) {
    if (device.schedule.enabled) {
      final days = device.scheduleDaysLabel(
        english: Localizations.localeOf(context).languageCode == 'en',
      );
      final overnight = device.scheduleCrossesMidnight
          ? context.l10n.text(' • ข้ามวัน', ' • Overnight')
          : '';
      return context.l10n.text(
        'เวลา ${device.schedule.startLabel}–${device.schedule.endLabel}\n$days$overnight',
        '${device.schedule.startLabel}–${device.schedule.endLabel}\n$days$overnight',
      );
    }
    final metric = switch (device.condition.metric) {
      'temperature' => context.l10n.text('อุณหภูมิ', 'Temperature'),
      'humidity' => context.l10n.text('ความชื้นอากาศ', 'Air humidity'),
      _ => context.l10n.text('ความชื้นดิน', 'Soil moisture'),
    };
    return '$metric ${device.condition.operator} ${device.condition.value.toStringAsFixed(0)}';
  }

  String _typeName(BuildContext context) => switch (device.type) {
    OutputDeviceType.pump => context.l10n.text('ปั๊มน้ำ', 'Pump'),
    OutputDeviceType.valve => context.l10n.text('วาล์ว', 'Valve'),
    OutputDeviceType.fan => context.l10n.text('พัดลม', 'Fan'),
    OutputDeviceType.light => context.l10n.text('ไฟ', 'Light'),
    OutputDeviceType.fogger => context.l10n.text('พ่นหมอก', 'Fogger'),
    OutputDeviceType.custom => context.l10n.text('กำหนดเอง', 'Custom'),
  };

  String _modeName(BuildContext context) => switch (device.mode) {
    OutputControlMode.manual => context.l10n.text('ควบคุมเอง', 'Manual'),
    OutputControlMode.schedule => context.l10n.text('ตั้งเวลา', 'Schedule'),
    OutputControlMode.automatic => context.l10n.text('ตามเซ็นเซอร์', 'Sensor'),
  };
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
