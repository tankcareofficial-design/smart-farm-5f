import 'package:flutter/material.dart';

enum OutputDeviceType { pump, valve, fan, light, fogger, custom }

enum OutputControlMode { manual, schedule, automatic }

class DeviceScheduleConfig {
  const DeviceScheduleConfig({
    this.enabled = false,
    this.hour = 6,
    this.minute = 0,
    this.endHour = 6,
    this.endMinute = 15,
    this.daysMask = 0x7F,
  });
  final bool enabled;
  final int hour;
  final int minute;
  final int endHour;
  final int endMinute;
  final int daysMask;
  DeviceScheduleConfig copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    int? endHour,
    int? endMinute,
    int? daysMask,
  }) => DeviceScheduleConfig(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    endHour: endHour ?? this.endHour,
    endMinute: endMinute ?? this.endMinute,
    daysMask: daysMask ?? this.daysMask,
  );
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'endHour': endHour,
    'endMinute': endMinute,
    'daysMask': daysMask,
  };
  factory DeviceScheduleConfig.fromJson(Map<String, Object?>? j) =>
      DeviceScheduleConfig(
        enabled: j?['enabled'] as bool? ?? false,
        hour: (j?['hour'] as num?)?.toInt() ?? 6,
        minute: (j?['minute'] as num?)?.toInt() ?? 0,
        endHour: (j?['endHour'] as num?)?.toInt() ?? 6,
        endMinute: (j?['endMinute'] as num?)?.toInt() ?? 15,
        daysMask: (j?['daysMask'] as num?)?.toInt() ?? 0x7F,
      );
  String get startLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  String get endLabel =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
}

class DeviceConditionConfig {
  const DeviceConditionConfig({
    this.enabled = false,
    this.sensorId = '',
    this.metric = '',
    this.operator = '<',
    this.value = 40,
    this.stopValue = 50,
  });
  final bool enabled;
  final String sensorId;
  final String metric;
  final String operator;
  final double value;
  final double stopValue;
  DeviceConditionConfig copyWith({
    bool? enabled,
    String? sensorId,
    String? metric,
    String? operator,
    double? value,
    double? stopValue,
  }) => DeviceConditionConfig(
    enabled: enabled ?? this.enabled,
    sensorId: sensorId ?? this.sensorId,
    metric: metric ?? this.metric,
    operator: operator ?? this.operator,
    value: value ?? this.value,
    stopValue: stopValue ?? this.stopValue,
  );
  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'sensorId': sensorId,
    'metric': metric,
    'operator': operator,
    'value': value,
    'stopValue': stopValue,
  };
  factory DeviceConditionConfig.fromJson(Map<String, Object?>? j) =>
      DeviceConditionConfig(
        enabled: j?['enabled'] as bool? ?? false,
        sensorId: j?['sensorId']?.toString() ?? '',
        metric: j?['metric']?.toString() ?? '',
        operator: j?['operator']?.toString() ?? '<',
        value: (j?['value'] as num?)?.toDouble() ?? 40,
        stopValue:
            (j?['stopValue'] as num?)?.toDouble() ??
            ((j?['value'] as num?)?.toDouble() ?? 40) + 5,
      );
}

class OutputDevice {
  const OutputDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.channel,
    required this.isOn,
    required this.enabled,
    required this.mode,
    this.requestedOn = false,
    this.runtimeState = 'off',
    this.waitingReason = '',
    this.remainingSeconds = 0,
    this.schedule = const DeviceScheduleConfig(),
    this.condition = const DeviceConditionConfig(),
  });
  final String id;
  final String name;
  final OutputDeviceType type;
  final int channel;
  final bool isOn;
  final bool enabled;
  final OutputControlMode mode;
  final bool requestedOn;
  final String runtimeState;
  final String waitingReason;
  final int remainingSeconds;
  final DeviceScheduleConfig schedule;
  final DeviceConditionConfig condition;
  OutputDevice copyWith({
    String? id,
    String? name,
    OutputDeviceType? type,
    int? channel,
    bool? isOn,
    bool? enabled,
    OutputControlMode? mode,
    bool? requestedOn,
    String? runtimeState,
    String? waitingReason,
    int? remainingSeconds,
    DeviceScheduleConfig? schedule,
    DeviceConditionConfig? condition,
  }) => OutputDevice(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    channel: channel ?? this.channel,
    isOn: isOn ?? this.isOn,
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    requestedOn: requestedOn ?? this.requestedOn,
    runtimeState: runtimeState ?? this.runtimeState,
    waitingReason: waitingReason ?? this.waitingReason,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    schedule: schedule ?? this.schedule,
    condition: condition ?? this.condition,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'channel': channel,
    'isOn': isOn,
    'enabled': enabled,
    'mode': mode.name,
    'requestedOn': requestedOn,
    'runtimeState': runtimeState,
    'waitingReason': waitingReason,
    'remainingSeconds': remainingSeconds,
    'schedule': schedule.toJson(),
    'condition': condition.toJson(),
  };
  factory OutputDevice.fromJson(Map<String, Object?> j) => OutputDevice(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? 'Device',
    type: OutputDeviceType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => OutputDeviceType.custom,
    ),
    channel: (j['channel'] as num?)?.toInt() ?? 1,
    isOn: j['isOn'] as bool? ?? false,
    enabled: j['enabled'] as bool? ?? true,
    mode: OutputControlMode.values.firstWhere(
      (e) => e.name == j['mode'],
      orElse: () => OutputControlMode.manual,
    ),
    requestedOn: j['requestedOn'] as bool? ?? false,
    runtimeState: j['runtimeState']?.toString() ?? 'off',
    waitingReason: j['waitingReason']?.toString() ?? '',
    remainingSeconds: (j['remainingSeconds'] as num?)?.toInt() ?? 0,
    schedule: DeviceScheduleConfig.fromJson(
      j['schedule'] is Map
          ? Map<String, Object?>.from(j['schedule'] as Map)
          : null,
    ),
    condition: DeviceConditionConfig.fromJson(
      j['condition'] is Map
          ? Map<String, Object?>.from(j['condition'] as Map)
          : null,
    ),
  );
  IconData get icon => switch (type) {
    OutputDeviceType.pump => Icons.water_rounded,
    OutputDeviceType.valve => Icons.water_drop_rounded,
    OutputDeviceType.fan => Icons.air_rounded,
    OutputDeviceType.light => Icons.lightbulb_rounded,
    OutputDeviceType.fogger => Icons.foggy,
    OutputDeviceType.custom => Icons.electrical_services_rounded,
  };
  String get typeName => switch (type) {
    OutputDeviceType.pump => 'ปั๊มน้ำ',
    OutputDeviceType.valve => 'วาล์ว',
    OutputDeviceType.fan => 'พัดลม',
    OutputDeviceType.light => 'ไฟ',
    OutputDeviceType.fogger => 'เครื่องพ่นหมอก',
    OutputDeviceType.custom => 'กำหนดเอง',
  };

  String scheduleDaysLabel({bool english = false}) {
    final mask = schedule.daysMask & 0x7F;
    if (mask == 0x7F) return english ? 'Every day' : 'ทุกวัน';
    if (mask == 0x1F) return english ? 'Mon–Fri' : 'จันทร์–ศุกร์';
    if (mask == 0x60) return english ? 'Sat–Sun' : 'เสาร์–อาทิตย์';
    if (mask == 0) return english ? 'No active days' : 'ยังไม่ได้กำหนดวัน';
    const th = <String>['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    const en = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = english ? en : th;
    return <String>[
      for (var i = 0; i < 7; i++)
        if ((mask & (1 << i)) != 0) labels[i],
    ].join(' • ');
  }

  bool get scheduleCrossesMidnight {
    final start = schedule.hour * 60 + schedule.minute;
    final end = schedule.endHour * 60 + schedule.endMinute;
    return schedule.enabled && end < start;
  }
  String get modeName => switch (mode) {
    OutputControlMode.manual => 'ควบคุมเอง',
    OutputControlMode.schedule => 'ตั้งเวลา',
    OutputControlMode.automatic => 'ตามเซ็นเซอร์',
  };
}
