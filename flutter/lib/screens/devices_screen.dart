import 'dart:async';

import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';

import '../models/output_device.dart';
import '../stores/device_store.dart';
import '../stores/sensor_store.dart';
import '../widgets/output_device_card.dart';
import '../widgets/output_device_dialog.dart';

class DevicesScreen extends StatelessWidget {
  final DeviceStore store;
  final SensorStore sensorStore;

  const DevicesScreen({
    super.key,
    required this.store,
    required this.sensorStore,
  });

  Future<void> _showDeviceDialog(BuildContext context, {OutputDevice? device}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return OutputDeviceDialog(
          store: store,
          sensorStore: sensorStore,
          existingDevice: device,
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, OutputDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.l10n.text('ลบอุปกรณ์', 'Delete device'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            context.l10n.text(
              'ต้องการลบ “${device.name}” ออกจากระบบหรือไม่?',
              'Remove “${device.name}” from the system?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.text('ยกเลิก', 'Cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.text('ลบ', 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final deleted = await store.removeOutput(device.id);
      if (!context.mounted || deleted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            store.lastCommandError ??
                context.l10n.text('ลบอุปกรณ์ไม่สำเร็จ', 'Unable to delete device'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final devices = store.outputs;

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.text('อุปกรณ์ควบคุม', 'Control devices'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    context.l10n.text(
                      'จัดการรีเลย์ ปั๊ม วาล์ว และอุปกรณ์',
                      'Manage relays, pumps, valves and devices',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _Esp32Clock(store: store),
                ),
              ],
            ),
            body: devices.isEmpty
                ? _EmptyDeviceView(
                    onAddPressed: () => _showDeviceDialog(context),
                  )
                : Column(
                    children: [
                      if (!store.controllerConnected ||
                          store.lastCommandError != null)
                        _ControllerStatusBanner(
                          connected: store.controllerConnected,
                          message: store.lastCommandError,
                          onDismiss: store.lastCommandError == null
                              ? null
                              : store.clearCommandError,
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: devices.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 11),
                          itemBuilder: (context, index) {
                            final device = devices[index];

                            return OutputDeviceCard(
                              device: device,
                              controllerConnected: store.controllerConnected,
                              commandPending: store.isCommandPending(device.id),
                              emergencyLocked: store.emergencyLatched,
                              onStateChanged: (value) async {
                                final success = await store.setOutputState(
                                  device.id,
                                  value,
                                );
                                if (!context.mounted || success) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      store.lastCommandError ??
                                          context.l10n.text(
                                            'สั่งอุปกรณ์ไม่สำเร็จ',
                                            'Device command failed',
                                          ),
                                    ),
                                  ),
                                );
                              },
                              onEdit: () {
                                _showDeviceDialog(context, device: device);
                              },
                              onDelete: () {
                                _confirmDelete(context, device);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: devices.length >= 8
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _showDeviceDialog(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      context.l10n.text('เพิ่มอุปกรณ์', 'Add device'),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _Esp32Clock extends StatefulWidget {
  const _Esp32Clock({required this.store});

  final DeviceStore store;

  @override
  State<_Esp32Clock> createState() => _Esp32ClockState();
}

class _Esp32ClockState extends State<_Esp32Clock> {
  Timer? _timer;

  String _weekdayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'จันทร์',
      DateTime.tuesday => 'อังคาร',
      DateTime.wednesday => 'พุธ',
      DateTime.thursday => 'พฤหัสบดี',
      DateTime.friday => 'ศุกร์',
      DateTime.saturday => 'เสาร์',
      DateTime.sunday => 'อาทิตย์',
      _ => '',
    };
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = widget.store.estimatedControllerDateTime;
    final colors = Theme.of(context).colorScheme;
    final connected = widget.store.controllerConnected;
    final clockValid = widget.store.controllerClockValid;
    final hasClockValue = dateTime != null;
    final online = connected;
    final time = hasClockValue
        ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}'
        : connected
        ? context.l10n.text('RTC ไม่พร้อม', 'RTC unavailable')
        : context.l10n.text('ยังไม่เชื่อมต่อ', 'Disconnected');
    final weekday = hasClockValue ? _weekdayName(dateTime.weekday) : '';
    final date = hasClockValue
        ? '$weekday ${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}'
        : connected && !clockValid
        ? context.l10n.text(
            widget.store.controllerClockSource == 'none'
                ? 'ไม่พบ DS3231 กรุณาตรวจ SDA/SCL และไฟเลี้ยง'
                : 'DS3231 ยังไม่พร้อม กดซิงก์เวลาจากโทรศัพท์',
            'DS3231 has not supplied date and time',
          )
        : context.l10n.text(
            'รอการเชื่อมต่อคอนโทรลเลอร์',
            'Waiting for controller connection',
          );

    return Semantics(
      label: context.l10n.text('เวลาและวันที่จาก ESP32', 'ESP32 date and time'),
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: online
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              !hasClockValue
                  ? context.l10n.text('เวลาจากคอนโทรลเลอร์', 'Controller time')
                  : clockValid
                  ? context.l10n.text('เวลาจากคอนโทรลเลอร์', 'Controller time')
                  : context.l10n.text(
                      'เวลา DS3231 ยังไม่ยืนยัน',
                      'DS3231 time is unverified',
                    ),
              style: TextStyle(
                fontSize: 8,
                height: 1,
                fontWeight: FontWeight.w700,
                color: online
                    ? colors.onPrimaryContainer.withValues(alpha: 0.72)
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w900,
                color: online
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              date,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: online
                    ? colors.onPrimaryContainer.withValues(alpha: 0.78)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDeviceView extends StatelessWidget {
  final VoidCallback onAddPressed;

  const _EmptyDeviceView({required this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.electrical_services_rounded,
                size: 45,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.text('ยังไม่มีอุปกรณ์', 'No devices yet'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.text(
                'เพิ่มปั๊ม วาล์ว พัดลม ไฟ หรืออุปกรณ์อื่น\nเพื่อเริ่มควบคุมผ่าน Smart Farm Pro',
                'Add a pump, valve, fan, light, or another device\nto start controlling it with Smart Farm Pro',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                context.l10n.text('เพิ่มอุปกรณ์แรก', 'Add first device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControllerStatusBanner extends StatelessWidget {
  const _ControllerStatusBanner({
    required this.connected,
    required this.message,
    required this.onDismiss,
  });

  final bool connected;
  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isError = message != null;
    final color = isError
        ? Colors.red
        : connected
        ? Colors.green
        : Colors.orange;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.cloud_off_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ??
                  context.l10n.text(
                    'กล่องควบคุมไม่ได้เชื่อมต่อ กรุณาตรวจสอบการเชื่อมต่อก่อนใช้งาน',
                    'Controller is offline. Connect ESP32 in Settings before control.',
                  ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
              tooltip: context.l10n.text('ปิด', 'Dismiss'),
            ),
        ],
      ),
    );
  }
}
