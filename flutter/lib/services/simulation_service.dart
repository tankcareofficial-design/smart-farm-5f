import 'dart:async';
import 'dart:math';

import '../models/sensor_data.dart';

class SimulationService {
  final _random = Random();
  Timer? _timer;

  final _controller = StreamController<SensorData>.broadcast();

  Stream<SensorData> get stream => _controller.stream;

  SensorData _current = SensorData(
    temperature: 31.8,
    humidity: 68,
    soilMoisture: 42,
    waterLevel: 76,
    battery: 92,
    solarVoltage: 13.8,
    updatedAt: DateTime.now(),
  );

  void start() {
    _controller.add(_current);

    _timer ??= Timer.periodic(
      const Duration(seconds: 2),
      (_) => _generateNextData(),
    );
  }

  void _generateNextData() {
    double vary(double value, double range, double min, double max) {
      final next = value + ((_random.nextDouble() * 2) - 1) * range;
      return next.clamp(min, max);
    }

    _current = _current.copyWith(
      temperature: vary(_current.temperature, 0.4, 20, 50),
      humidity: vary(_current.humidity, 1.2, 0, 100),
      soilMoisture: vary(_current.soilMoisture, 1.0, 0, 100),
      waterLevel: vary(_current.waterLevel, 0.4, 0, 100),
      battery: vary(_current.battery, 0.2, 0, 100),
      solarVoltage: vary(_current.solarVoltage, 0.15, 0, 24),
      updatedAt: DateTime.now(),
    );

    _controller.add(_current);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
