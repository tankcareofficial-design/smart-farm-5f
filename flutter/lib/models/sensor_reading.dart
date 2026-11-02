import 'sensor_model.dart';

enum SensorLiveState { waiting, live, stale, unavailable, error }

class SensorReading {
  const SensorReading({
    required this.id,
    required this.type,
    required this.name,
    required this.unit,
    required this.state,
    this.value,
    this.updatedAt,
    this.message,
  });

  final String id;
  final SensorType type;
  final String name;
  final String unit;
  final double? value;
  final SensorLiveState state;
  final DateTime? updatedAt;
  final String? message;

  bool get hasValue => value != null;

  bool get isFresh {
    final timestamp = updatedAt;
    if (timestamp == null) {
      return false;
    }
    return DateTime.now().difference(timestamp) <= const Duration(seconds: 15);
  }

  SensorReading copyWith({
    String? id,
    SensorType? type,
    String? name,
    String? unit,
    double? value,
    SensorLiveState? state,
    DateTime? updatedAt,
    String? message,
  }) {
    return SensorReading(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      value: value ?? this.value,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message ?? this.message,
    );
  }
}
