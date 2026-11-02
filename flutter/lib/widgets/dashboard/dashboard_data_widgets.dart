import 'package:flutter/material.dart';

import '../../controllers/smart_farm_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/sf_colors.dart';
import '../../core/theme/sf_radius.dart';
import '../../core/theme/sf_text_styles.dart';
import '../../core/widgets/sf_card.dart';
import '../../models/farm_state.dart';
import '../../models/output_device.dart';
import '../../models/sensor_config.dart';
import '../../models/sensor_model.dart';
import '../../models/sensor_reading.dart';
import '../../stores/device_store.dart';
import '../../stores/sensor_store.dart';

class DashboardSensorGrid extends StatelessWidget {
  const DashboardSensorGrid({
    super.key,
    required this.store,
    required this.state,
    required this.onAdd,
  });

  final SensorStore store;
  final FarmState state;
  final VoidCallback onAdd;

  static const List<SensorType> _primaryTypes = <SensorType>[
    SensorType.temperature,
    SensorType.humidity,
    SensorType.soilMoisture,
    SensorType.waterLevel,
  ];

  @override
  Widget build(BuildContext context) {
    // Dashboard cards are a stable capability preview. They must remain visible
    // while SensorStore is loading and when no physical sensor is installed.
    // Loading only changes the status text; it must never replace the grid.
    final configuredTypes = store.configs.map((config) => config.type);
    final visibleTypes = <SensorType>{
      ..._primaryTypes,
      ...configuredTypes,
    }.toList(growable: false);

    final items = visibleTypes
        .map(
          (type) => _SensorCardData(
            type: type,
            config: _configForType(type),
            reading: state.readingForType(type),
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (store.loading) ...<Widget>[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            const gap = 12.0;
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width - 32;
            final width = (availableWidth - ((columns - 1) * gap)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _DashboardSensorCard(
                        data: item,
                        state: state,
                        onAdd: onAdd,
                        storeLoading: store.loading,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  SensorConfig? _configForType(SensorType type) {
    for (final config in store.configs) {
      if (config.type == type) {
        return config;
      }
    }
    return null;
  }
}

class DashboardEnergyCard extends StatelessWidget {
  const DashboardEnergyCard({super.key, required this.state});

  final FarmState state;

  @override
  Widget build(BuildContext context) {
    return SFCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _EnergyMetric(
                icon: Icons.battery_charging_full_rounded,
                title: context.l10n.text('แบตเตอรี่', 'Battery'),
                reading: state.readingForType(SensorType.battery),
                connected: state.connected,
              ),
            ),
            const VerticalDivider(width: 28),
            Expanded(
              child: _EnergyMetric(
                icon: Icons.solar_power_rounded,
                title: context.l10n.text('โซลาร์เซลล์', 'Solar'),
                reading: state.readingForType(SensorType.solar),
                connected: state.connected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardDevicePreview extends StatelessWidget {
  const DashboardDevicePreview({
    super.key,
    required this.store,
    required this.controller,
  });

  final DeviceStore store;
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    final devices = store.outputs
        .take(SmartFarmController.hardwareRelayCount)
        .toList(growable: false);
    final relayCount =
        controller.relayCount ?? SmartFarmController.hardwareRelayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _RelaySummary(
          activeCount: store.activeOutputCount,
          configuredCount: store.outputs.length,
          relayCount: relayCount,
        ),
        const SizedBox(height: 10),
        if (devices.isEmpty)
          SFCard(
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.electrical_services_rounded,
                  size: 42,
                  color: SFColors.textSecondary,
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.text(
                    'ยังไม่ได้เพิ่มอุปกรณ์ควบคุม',
                    'No control devices added',
                  ),
                  textAlign: TextAlign.center,
                  style: SFTextStyles.title,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.text(
                    'รีเลย์พร้อมใช้งาน $relayCount ช่อง',
                    '$relayCount relay channels available',
                  ),
                  textAlign: TextAlign.center,
                  style: SFTextStyles.bodySecondary,
                ),
              ],
            ),
          )
        else
          SFCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List<Widget>.generate(devices.length, (index) {
                final device = devices[index];
                return Column(
                  children: <Widget>[
                    _DeviceRow(
                      device: device,
                      store: store,
                      controller: controller,
                    ),
                    if (index != devices.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _SensorCardData {
  const _SensorCardData({
    required this.type,
    required this.config,
    required this.reading,
  });

  final SensorType type;
  final SensorConfig? config;
  final SensorReading? reading;
}

class _DashboardSensorCard extends StatelessWidget {
  const _DashboardSensorCard({
    required this.data,
    required this.state,
    required this.onAdd,
    required this.storeLoading,
  });

  final _SensorCardData data;
  final FarmState state;
  final VoidCallback onAdd;
  final bool storeLoading;

  @override
  Widget build(BuildContext context) {
    final config = data.config;
    final reading = data.reading;
    final enabled = config?.enabled ?? false;
    final hasValue = enabled && reading?.value != null;
    final presentation = _presentationFor(
      context,
      type: data.type,
      config: config,
      reading: reading,
      connected: state.connected,
      storeLoading: storeLoading,
    );

    return SFCard(
      padding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 188),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: presentation.color.withValues(alpha: .10),
                    borderRadius: SFRadius.medium,
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.color,
                    size: 27,
                  ),
                ),
                const Spacer(),
                Icon(
                  presentation.statusIcon,
                  size: 24,
                  color: presentation.statusColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              config?.name ?? presentation.defaultName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SFTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              presentation.valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasValue
                  ? SFTextStyles.headline.copyWith(color: SFColors.textPrimary)
                  : SFTextStyles.titleLarge.copyWith(
                      color: SFColors.textSecondary,
                    ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: SFRadius.pill,
              child: LinearProgressIndicator(
                value: presentation.progress,
                minHeight: 8,
                color: presentation.color,
                backgroundColor: SFColors.border,
              ),
            ),
            const SizedBox(height: 9),
            GestureDetector(
              onTap: config == null ? onAdd : null,
              child: Text(
                presentation.detailText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SFTextStyles.caption.copyWith(
                  color: presentation.statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SensorPresentation _presentationFor(
    BuildContext context, {
    required SensorType type,
    required SensorConfig? config,
    required SensorReading? reading,
    required bool connected,
    required bool storeLoading,
  }) {
    final metadata = _metadataFor(context, type);

    if (storeLoading && config == null) {
      return metadata.copyWith(
        valueText: context.l10n.text('ไม่มีข้อมูล', 'No data'),
        detailText: context.l10n.text(
          'กำลังโหลดการตั้งค่าเซ็นเซอร์',
          'Loading sensor configuration',
        ),
        progress: 0,
        statusIcon: Icons.sync_rounded,
        statusColor: SFColors.info,
      );
    }

    if (config == null) {
      return metadata.copyWith(
        valueText: context.l10n.text('ไม่มีข้อมูล', 'No data'),
        detailText: context.l10n.text(
          'ยังไม่ได้ติดตั้งเซ็นเซอร์',
          'Sensor not installed',
        ),
        progress: 0,
        statusIcon: Icons.add_circle_outline_rounded,
        statusColor: SFColors.textDisabled,
      );
    }

    if (!config.enabled) {
      return metadata.copyWith(
        valueText: context.l10n.text('ปิดใช้งาน', 'Disabled'),
        detailText: config.inputId,
        progress: 0,
        statusIcon: Icons.pause_circle_outline_rounded,
        statusColor: SFColors.textDisabled,
      );
    }

    if (!connected) {
      return metadata.copyWith(
        valueText: context.l10n.text('ไม่มีข้อมูล', 'No data'),
        detailText: context.l10n.text(
          'กล่องควบคุมไม่ได้เชื่อมต่อ',
          'Control box offline',
        ),
        progress: 0,
        statusIcon: Icons.cloud_off_rounded,
        statusColor: SFColors.textDisabled,
      );
    }

    if (reading?.value == null) {
      final isError = reading?.state == SensorLiveState.error;
      return metadata.copyWith(
        valueText: isError
            ? context.l10n.text('อ่านค่าไม่ได้', 'Read error')
            : context.l10n.text('ไม่มีข้อมูล', 'No data'),
        detailText: isError
            ? context.l10n.text(
                'ตรวจสอบการเชื่อมต่อเซ็นเซอร์',
                'Check sensor wiring',
              )
            : context.l10n.text('รอข้อมูลจริง', 'Waiting for live data'),
        progress: 0,
        statusIcon: isError
            ? Icons.error_rounded
            : Icons.hourglass_empty_rounded,
        statusColor: isError ? SFColors.danger : SFColors.warning,
      );
    }

    final value = reading!.value!;
    final stale = reading.state == SensorLiveState.stale || !reading.isFresh;
    return metadata.copyWith(
      valueText: '${_formatValue(value)} ${reading.unit}',
      detailText: stale
          ? context.l10n.text('ข้อมูลเก่า', 'Stale data')
          : context.l10n.text('ข้อมูลจากกล่องควบคุม', 'Live from control box'),
      progress: _normalized(type, value),
      statusIcon: stale ? Icons.schedule_rounded : Icons.check_circle_rounded,
      statusColor: stale ? SFColors.warning : SFColors.success,
    );
  }

  _SensorPresentation _metadataFor(BuildContext context, SensorType type) {
    return switch (type) {
      SensorType.temperature => _SensorPresentation(
        icon: Icons.thermostat_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('อุณหภูมิ', 'Temperature'),
      ),
      SensorType.humidity => _SensorPresentation(
        icon: Icons.water_drop_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('ความชื้นอากาศ', 'Air humidity'),
      ),
      SensorType.soilMoisture => _SensorPresentation(
        icon: Icons.grass_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('ความชื้นดิน', 'Soil moisture'),
      ),
      SensorType.waterLevel => _SensorPresentation(
        icon: Icons.waves_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('ระดับน้ำ', 'Water level'),
      ),
      SensorType.battery => _SensorPresentation(
        icon: Icons.battery_charging_full_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('แบตเตอรี่', 'Battery'),
      ),
      SensorType.solar => _SensorPresentation(
        icon: Icons.solar_power_rounded,
        color: SFColors.primary,
        defaultName: context.l10n.text('โซลาร์เซลล์', 'Solar'),
      ),
    };
  }

  double _normalized(SensorType type, double value) {
    final range = switch (type) {
      SensorType.temperature => const (0.0, 50.0),
      SensorType.humidity ||
      SensorType.soilMoisture ||
      SensorType.waterLevel ||
      SensorType.battery => const (0.0, 100.0),
      SensorType.solar => const (0.0, 30.0),
    };
    if (range.$2 <= range.$1) {
      return 0;
    }
    return ((value - range.$1) / (range.$2 - range.$1)).clamp(0.0, 1.0);
  }

  String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _SensorPresentation {
  const _SensorPresentation({
    required this.icon,
    required this.color,
    required this.defaultName,
    this.valueText = '',
    this.detailText = '',
    this.progress = 0,
    this.statusIcon = Icons.remove_circle_outline_rounded,
    this.statusColor = SFColors.textDisabled,
  });

  final IconData icon;
  final Color color;
  final String defaultName;
  final String valueText;
  final String detailText;
  final double progress;
  final IconData statusIcon;
  final Color statusColor;

  _SensorPresentation copyWith({
    String? valueText,
    String? detailText,
    double? progress,
    IconData? statusIcon,
    Color? statusColor,
  }) {
    return _SensorPresentation(
      icon: icon,
      color: color,
      defaultName: defaultName,
      valueText: valueText ?? this.valueText,
      detailText: detailText ?? this.detailText,
      progress: progress ?? this.progress,
      statusIcon: statusIcon ?? this.statusIcon,
      statusColor: statusColor ?? this.statusColor,
    );
  }
}

class _EnergyMetric extends StatelessWidget {
  const _EnergyMetric({
    required this.icon,
    required this.title,
    required this.reading,
    required this.connected,
  });

  final IconData icon;
  final String title;
  final SensorReading? reading;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final hasValue = reading?.value != null;
    final valueText = hasValue
        ? '${_formatValue(reading!.value!)} ${reading!.unit}'
        : context.l10n.text('ไม่มีข้อมูล', 'No data');
    final detailText = !connected
        ? context.l10n.text('กล่องควบคุมไม่ได้เชื่อมต่อ', 'Control box offline')
        : hasValue
        ? _statusText(context, reading!)
        : context.l10n.text(
            'ยังไม่ได้เสียบอุปกรณ์วัดพลังงาน',
            'Power meter not connected',
          );
    final color = hasValue ? SFColors.success : SFColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: SFTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SFTextStyles.titleLarge.copyWith(
                  color: hasValue
                      ? SFColors.textPrimary
                      : SFColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detailText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SFTextStyles.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusText(BuildContext context, SensorReading value) {
    return switch (value.state) {
      SensorLiveState.live => context.l10n.text('ข้อมูลสด', 'Live data'),
      SensorLiveState.stale => context.l10n.text('ข้อมูลเก่า', 'Stale data'),
      SensorLiveState.waiting => context.l10n.text(
        'รอข้อมูลจริง',
        'Waiting for live data',
      ),
      SensorLiveState.unavailable => context.l10n.text(
        'ไม่พบอุปกรณ์',
        'Device unavailable',
      ),
      SensorLiveState.error => context.l10n.text(
        'อ่านค่าไม่สำเร็จ',
        'Read error',
      ),
    };
  }

  String _formatValue(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _RelaySummary extends StatelessWidget {
  const _RelaySummary({
    required this.activeCount,
    required this.configuredCount,
    required this.relayCount,
  });

  final int activeCount;
  final int configuredCount;
  final int relayCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            context.l10n.text(
              '$activeCount กำลังทำงาน จาก $configuredCount อุปกรณ์',
              '$activeCount active of $configuredCount devices',
            ),
            style: SFTextStyles.bodySecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: SFColors.primary.withValues(alpha: .09),
            borderRadius: SFRadius.pill,
          ),
          child: Text(
            context.l10n.text('รีเลย์ $relayCount ช่อง', '$relayCount relays'),
            style: SFTextStyles.caption.copyWith(color: SFColors.primary),
          ),
        ),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.device,
    required this.store,
    required this.controller,
  });

  final OutputDevice device;
  final DeviceStore store;
  final SmartFarmController controller;

  @override
  Widget build(BuildContext context) {
    final pending = store.isCommandPending(device.id);
    final running = device.isOn || device.runtimeState == 'running';
    final requested = device.requestedOn || running;
    final enabled =
        controller.connected &&
        !controller.emergencyLatched &&
        device.enabled &&
        !pending;
    final colors = Theme.of(context).colorScheme;
    final stateColor = running ? colors.primary : colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: running
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: SFRadius.medium,
            ),
            child: Icon(device.icon, color: stateColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SFTextStyles.title,
                ),
                const SizedBox(height: 3),
                Text(
                  _runtimeLabel(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SFTextStyles.caption.copyWith(color: stateColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (pending)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch.adaptive(
              value: requested,
              onChanged: enabled
                  ? (value) => store.setOutputState(device.id, value)
                  : null,
            ),
        ],
      ),
    );
  }

  String _runtimeLabel(BuildContext context) {
    if (device.isOn || device.runtimeState == 'running') {
      return context.l10n.text('กำลังทำงาน', 'Running');
    }
    if (!device.requestedOn) {
      return '${context.l10n.text('ช่อง', 'Channel')} ${device.channel} • ${device.modeName}';
    }
    if (device.remainingSeconds > 0) {
      final minutes = (device.remainingSeconds / 60).ceil();
      return context.l10n.text(
        'รับคำขอแล้ว • รออีก $minutes นาที',
        'Request accepted • $minutes min remaining',
      );
    }
    if (device.waitingReason.isNotEmpty) {
      return device.waitingReason;
    }
    return device.condition.enabled
        ? context.l10n.text('รอเงื่อนไขเซ็นเซอร์', 'Waiting for sensor rule')
        : context.l10n.text('รอเวลาที่กำหนด', 'Waiting for schedule');
  }
}

class DashboardAccessoryStatusCard extends StatelessWidget {
  const DashboardAccessoryStatusCard({super.key, required this.state});

  final FarmState state;

  @override
  Widget build(BuildContext context) {
    final items = state.accessories;
    return SFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SFColors.primary.withValues(alpha: .10),
                  borderRadius: SFRadius.medium,
                ),
                child: const Icon(Icons.hub_rounded, color: SFColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.text(
                        'อุปกรณ์ที่เสียบอยู่',
                        'Connected accessories',
                      ),
                      style: SFTextStyles.title,
                    ),
                    Text(
                      context.l10n.text(
                        'ระบบตรวจสอบอัตโนมัติ ไม่ต้องตั้งค่าทางเทคนิค',
                        'Detected automatically without technical setup',
                      ),
                      style: SFTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              context.l10n.text(
                'กำลังรอข้อมูลจากกล่องควบคุม',
                'Waiting for the control box',
              ),
              style: SFTextStyles.bodySecondary,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      item.connected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: item.connected
                          ? SFColors.success
                          : SFColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item.displayName, style: SFTextStyles.body),
                    ),
                    Text(
                      item.connected
                          ? context.l10n.text('พร้อมใช้งาน', 'Ready')
                          : context.l10n.text(
                              'ยังไม่ได้เสียบ',
                              'Not connected',
                            ),
                      style: SFTextStyles.caption.copyWith(
                        color: item.connected
                            ? SFColors.success
                            : SFColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
