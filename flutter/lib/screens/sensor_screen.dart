import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../controllers/smart_farm_controller.dart';
import '../models/sensor_config.dart';
import '../models/sensor_model.dart';
import '../stores/sensor_store.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_setup_dialog.dart';

class SensorScreen extends StatelessWidget {
  const SensorScreen({
    super.key,
    required this.store,
    this.controller,
  });

  final SensorStore store;
  final SmartFarmController? controller;

  void _openSetup(BuildContext context, {SensorConfig? existing}) {
    if (controller != null && !controller!.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('sensor-controller-offline-warning'),
          content: Text(context.l10n.text(
            'กล่องควบคุมออฟไลน์: ยังเพิ่มหรือแก้ไขเซ็นเซอร์ไม่ได้ กรุณาเชื่อมต่อกล่องควบคุม ในหน้าตั้งค่า',
            'Controller offline: connect the control box before adding or editing sensors.',
          )),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SensorSetupDialog(store: store, existing: existing),
    );
  }

  Future<void> _delete(BuildContext context, SensorConfig config) async {
    if (controller != null && !controller!.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text(
            'กล่องควบคุมออฟไลน์: ยังลบเซ็นเซอร์ไม่ได้ กรุณาเชื่อมต่อกล่องควบคุม ก่อน',
            'Controller offline: reconnect the control box before deleting a sensor.',
          )),
        ),
      );
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n.text('ลบเซ็นเซอร์?', 'Delete sensor?')),
        content: Text(config.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.text('ยกเลิก', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.text('ลบ', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) store.removeSensor(config.id);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          store,
          if (controller != null) controller!,
        ]),
        builder: (BuildContext context, Widget? child) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.l10n.text('เซ็นเซอร์', 'Sensors'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    context.l10n.text(
                      'เพิ่ม ลบ และกำหนด INPUT ของเซ็นเซอร์',
                      'Add, remove and map sensor inputs',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: <Widget>[
                IconButton(
                  tooltip: context.l10n.text('เพิ่มเซ็นเซอร์', 'Add sensor'),
                  onPressed: () => _openSetup(context),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
            body: store.loading && store.sensors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    children: <Widget>[
                      if (controller != null && !controller!.connected) ...<Widget>[
                        Card(
                          key: const Key('sensor-controller-offline-banner'),
                          child: ListTile(
                            leading: const Icon(Icons.wifi_off_rounded),
                            title: Text(context.l10n.text(
                              'กล่องควบคุมออฟไลน์',
                              'Controller offline',
                            )),
                            subtitle: Text(context.l10n.text(
                              'เชื่อมต่อกล่องควบคุม ก่อนเพิ่มหรือแก้ไขเซ็นเซอร์ · ข้อมูลที่เคยบันทึกยังเปิดดูได้',
                              'Connect the control box before changing sensors · existing saved information remains viewable.',
                            )),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.hub_rounded, color: colors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.l10n.text(
                                  'I²C ใช้ร่วมกันได้ • DI/AI ห้ามซ้ำกัน',
                                  'I²C can be shared • DI/AI inputs must be unique',
                                ),
                              ),
                            ),
                            Text(
                              '${store.configs.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (store.configs.isEmpty) ...<Widget>[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: <Widget>[
                                const Icon(Icons.sensors_off_rounded, size: 44),
                                const SizedBox(height: 10),
                                Text(
                                  context.l10n.text(
                                    'ยังไม่ได้เพิ่มเซ็นเซอร์',
                                    'No sensors added',
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  context.l10n.text(
                                    'กดเพิ่มเซ็นเซอร์ เลือกชนิดและช่องต่อ ระบบจะแสดงค่าเมื่อเสียบเซ็นเซอร์จริง',
                                    'Add a sensor and map its input. No reading is shown until the control box sends live data.',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (store.sensors.isEmpty) ...<Widget>[
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.info_outline_rounded),
                            title: Text(
                              context.l10n.text(
                                'ยังไม่มีข้อมูลเซ็นเซอร์จริง',
                                'No live sensor data',
                              ),
                            ),
                            subtitle: Text(
                              context.l10n.text(
                                'ตั้งค่าเซ็นเซอร์แล้ว แต่กล่องควบคุมยังไม่ได้รับข้อมูล',
                                'Sensors are configured, but the control box has not reported readings yet.',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      for (final SensorConfig config
                          in store.configs) ...<Widget>[
                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                leading: CircleAvatar(
                                  child: Icon(_iconFor(config.type)),
                                ),
                                title: Text(
                                  config.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                subtitle: Text(
                                  '${config.inputId} • ${config.driverKey}',
                                ),
                                trailing: Switch(
                                  value: config.enabled,
                                  onChanged: controller != null &&
                                          !controller!.connected
                                      ? null
                                      : (bool value) =>
                                          store.setSensorEnabled(config.id, value),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openSetup(
                                          context,
                                          existing: config,
                                        ),
                                        icon: const Icon(Icons.edit_rounded),
                                        label: Text(
                                          context.l10n.text(
                                            'แก้ไข/การต่อสาย',
                                            'Edit/Wiring',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () => _delete(context, config),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (store.sensors.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.text('ค่าปัจจุบัน', 'Current readings'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder:
                              (
                                BuildContext context,
                                BoxConstraints constraints,
                              ) {
                                final double width =
                                    (constraints.maxWidth - 12) / 2;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: store.sensors
                                      .map(
                                        (SensorModel sensor) => SizedBox(
                                          width: width,
                                          child: SensorCard(sensor: sensor),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                        ),
                      ],
                    ],
                  ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openSetup(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.text('เพิ่มเซ็นเซอร์', 'Add sensor')),
            ),
          );
        },
      ),
    );
  }

  static IconData _iconFor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return Icons.thermostat_rounded;
      case SensorType.humidity:
        return Icons.water_drop_rounded;
      case SensorType.soilMoisture:
        return Icons.grass_rounded;
      case SensorType.waterLevel:
        return Icons.waves_rounded;
      case SensorType.battery:
        return Icons.battery_charging_full_rounded;
      case SensorType.solar:
        return Icons.solar_power_rounded;
    }
  }
}
