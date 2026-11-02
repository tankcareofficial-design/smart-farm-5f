class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    required this.relayChannel,
    required this.action,
    this.deviceId = '',
    this.priority = 300,
    this.durationSeconds = 0,
    this.maxRuntimeSeconds = 21600,
    this.cooldownSeconds = 300,
    this.lastTriggeredAt,
    this.nextRunAt,
    this.lastResult,
    this.running = false,
    this.conditionLogic = 'and',
    this.conditions = const <AutomationCondition>[],
    this.endHour,
    this.endMinute,
    this.rawMetadata = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String deviceId;
  final bool enabled;
  final int priority;
  final int hour;
  final int minute;
  final Set<int> daysOfWeek;
  final int relayChannel;
  final String action;
  final int durationSeconds;
  final int maxRuntimeSeconds;
  final int cooldownSeconds;
  final DateTime? lastTriggeredAt;
  final DateTime? nextRunAt;
  final String? lastResult;
  final bool running;
  final String conditionLogic;
  final List<AutomationCondition> conditions;
  final int? endHour;
  final int? endMinute;
  final Map<String, dynamic> rawMetadata;

  AutomationRule copyWith({bool? enabled}) => AutomationRule(
    id: id,
    name: name,
    deviceId: deviceId,
    enabled: enabled ?? this.enabled,
    priority: priority,
    hour: hour,
    minute: minute,
    daysOfWeek: daysOfWeek,
    relayChannel: relayChannel,
    action: action,
    durationSeconds: durationSeconds,
    maxRuntimeSeconds: maxRuntimeSeconds,
    cooldownSeconds: cooldownSeconds,
    lastTriggeredAt: lastTriggeredAt,
    nextRunAt: nextRunAt,
    lastResult: lastResult,
    running: running,
    conditionLogic: conditionLogic,
    conditions: conditions,
    endHour: endHour,
    endMinute: endMinute,
    rawMetadata: rawMetadata,
  );

  factory AutomationRule.fromJson(Map<String, dynamic> json) {
    final trigger = Map<String, dynamic>.from(
      json['trigger'] as Map? ?? const {},
    );
    final schedule = Map<String, dynamic>.from(
      trigger['schedule'] as Map? ?? const {},
    );
    final actions = json['actions'] as List? ?? const [];
    final action = actions.isNotEmpty
        ? Map<String, dynamic>.from(actions.first as Map)
        : <String, dynamic>{};
    final safety = Map<String, dynamic>.from(
      json['safety'] as Map? ?? const {},
    );
    return AutomationRule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'การทำงานอัตโนมัติ',
      deviceId: json['deviceId']?.toString() ?? '',
      enabled: json['enabled'] != false,
      priority: (json['priority'] as num?)?.toInt() ?? 300,
      hour: (schedule['hour'] as num?)?.toInt() ?? 6,
      minute: (schedule['minute'] as num?)?.toInt() ?? 0,
      daysOfWeek:
          ((schedule['daysOfWeek'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7])
              .map((e) => (e as num).toInt())
              .toSet(),
      relayChannel: (action['relayChannel'] as num?)?.toInt() ?? 0,
      action: action['type']?.toString() ?? 'relay_pulse',
      durationSeconds: (action['durationSeconds'] as num?)?.toInt() ?? 0,
      maxRuntimeSeconds:
          (safety['maxRuntimeSeconds'] as num?)?.toInt() ?? 21600,
      cooldownSeconds: (safety['cooldownSeconds'] as num?)?.toInt() ?? 300,
      lastTriggeredAt: DateTime.tryParse(
        json['lastTriggeredAt']?.toString() ?? '',
      ),
      nextRunAt: DateTime.tryParse(json['nextRunAt']?.toString() ?? ''),
      lastResult: json['lastResult']?.toString(),
      running: json['running'] == true,
      conditionLogic: json['conditionLogic']?.toString() ?? 'and',
      conditions: ((json['conditions'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (e) => AutomationCondition.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      endHour: (schedule['endHour'] as num?)?.toInt(),
      endMinute: (schedule['endMinute'] as num?)?.toInt(),
      rawMetadata: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deviceId': deviceId.isEmpty ? 'relay-${relayChannel + 1}' : deviceId,
    'enabled': enabled,
    'priority': priority,
    'trigger': {
      'type': 'schedule',
      'schedule': {
        'hour': hour,
        'minute': minute,
        'daysOfWeek': daysOfWeek.toList()..sort(),
        'mode': endHour == null ? 'at' : 'window',
        'endHour': endHour ?? hour,
        'endMinute': endMinute ?? minute,
      },
    },
    'conditionLogic': conditionLogic,
    'conditions': conditions.map((e) => e.toJson()).toList(),
    'actions': [
      {
        'type': action,
        'relayChannel': relayChannel,
        'durationSeconds': durationSeconds,
      },
    ],
    'safety': {
      'maxRuntimeSeconds': maxRuntimeSeconds,
      'cooldownSeconds': cooldownSeconds,
    },
  };
}

class AutomationCondition {
  const AutomationCondition({
    this.type = 'sensor',
    this.sensorId = '',
    required this.metric,
    required this.operator,
    required this.value,
    this.valueHigh,
  });
  final String type;
  final String sensorId;
  final String metric;
  final String operator;
  final double value;
  final double? valueHigh;
  factory AutomationCondition.fromJson(Map<String, dynamic> j) =>
      AutomationCondition(
        type: j['type']?.toString() ?? 'sensor',
        sensorId: j['sensorId']?.toString() ?? '',
        metric: j['metric']?.toString() ?? '',
        operator: j['operator']?.toString() ?? '<',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        valueHigh: (j['valueHigh'] as num?)?.toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'type': type,
    'sensorId': sensorId,
    'metric': metric,
    'operator': operator,
    'value': value,
    if (valueHigh != null) 'valueHigh': valueHigh,
  };
}
