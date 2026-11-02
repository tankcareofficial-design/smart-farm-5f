import 'automation_rule.dart';
import 'device_runtime_state.dart';
import 'system_health_state.dart';

class ControllerSnapshot {
  const ControllerSnapshot({
    required this.schemaVersion,
    required this.revision,
    required this.generatedAtMs,
    required this.sourceOfTruth,
    required this.rules,
    required this.runtime,
    required this.health,
    required this.raw,
  });

  final int schemaVersion;
  final int revision;
  final int generatedAtMs;
  final String sourceOfTruth;
  final List<AutomationRule> rules;
  final List<DeviceRuntimeState> runtime;
  final SystemHealthState health;
  final Map<String, dynamic> raw;

  factory ControllerSnapshot.fromJson(Map<String, dynamic> json) {
    final rules = (json['rules'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => AutomationRule.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final runtime = (json['runtime'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) =>
              DeviceRuntimeState.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    final healthJson = json['health'];

    return ControllerSnapshot(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      generatedAtMs: (json['generatedAtMs'] as num?)?.toInt() ?? 0,
      sourceOfTruth: json['sourceOfTruth']?.toString() ?? 'esp32',
      rules: rules,
      runtime: runtime,
      health: healthJson is Map
          ? SystemHealthState.fromJson(Map<String, dynamic>.from(healthJson))
          : SystemHealthState.unavailable,
      raw: json,
    );
  }
}
