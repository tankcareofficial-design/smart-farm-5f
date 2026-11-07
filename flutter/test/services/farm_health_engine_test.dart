import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/farm_state.dart';
import 'package:smart_farm/models/sensor_model.dart';
import 'package:smart_farm/models/sensor_reading.dart';
import 'package:smart_farm/services/farm_health_engine.dart';

void main() {
  const engine = FarmHealthEngine();

  test('connected farm without live sensors is not assessable', () {
    final state = FarmState.empty.copyWith(
      connected: true,
      controllerStatus: 'connected',
      enabledSensors: 1,
      relayCount: 8,
    );
    final result = engine.evaluate(state);
    expect(result.isAssessable, isFalse);
    expect(result.score, 0);
    expect(result.alerts, contains('กำลังรอข้อมูลจากเซ็นเซอร์จริง'));
  });

  test('healthy connected farm with a live sensor scores excellent', () {
    final state = FarmState.empty.copyWith(
      connected: true,
      controllerStatus: 'connected',
      enabledSensors: 1,
      relayCount: 8,
      sensorReadings: <SensorReading>[
        SensorReading(
          id: 'temperature',
          type: SensorType.temperature,
          name: 'Temperature',
          unit: '°C',
          value: 28,
          state: SensorLiveState.live,
          updatedAt: DateTime.now(),
        ),
      ],
    );
    final result = engine.evaluate(state);
    expect(result.isAssessable, isTrue);
    expect(result.score, 100);
    expect(result.level, FarmHealthLevel.excellent);
  });

  test('offline state is not presented as a valid health score', () {
    final result = engine.evaluate(FarmState.empty);
    expect(result.isAssessable, isFalse);
    expect(result.score, 0);
    expect(result.alerts, contains('กล่องควบคุมไม่ได้เชื่อมต่อ'));
  });

  test('communication penalty is capped at twenty points', () {
    final state = FarmState.empty.copyWith(
      connected: true,
      enabledSensors: 1,
      relayCount: 8,
      consecutiveFailures: 100,
      sensorReadings: <SensorReading>[
        SensorReading(
          id: 'temperature',
          type: SensorType.temperature,
          name: 'Temperature',
          unit: '°C',
          value: 28,
          state: SensorLiveState.live,
          updatedAt: DateTime.now(),
        ),
      ],
    );
    expect(engine.evaluate(state).score, 89);
  });
}
