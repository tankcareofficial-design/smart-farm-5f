import 'package:flutter/foundation.dart';

import '../models/farm_state.dart';
import '../models/sensor_model.dart';
import '../models/sensor_reading.dart';

/// Compatibility controller for screens that have not yet moved to
/// [SmartFarmController]. It stores only real readings supplied by callers.
class FarmController extends ChangeNotifier {
  FarmController({
    FarmState initialState = FarmState.empty,
    bool initiallyConnected = false,
  }) : _state = initialState.copyWith(connected: initiallyConnected),
       _connected = initiallyConnected;

  FarmState _state;
  bool _connected;

  FarmState get state => _state;
  bool get connected => _connected;

  void setConnected(bool value) {
    if (_connected == value) {
      return;
    }
    _connected = value;
    _state = _state.copyWith(connected: value);
    notifyListeners();
  }

  void updateSensorReadings(List<SensorReading> readings) {
    _state = _state.copyWith(
      sensorReadings: readings,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  void updateSensorData({
    double? temperature,
    double? humidity,
    double? soilMoisture,
  }) {
    final timestamp = DateTime.now();
    final readings = <SensorReading>[
      if (temperature != null)
        SensorReading(
          id: 'temperature',
          type: SensorType.temperature,
          name: 'Temperature',
          unit: '°C',
          value: temperature,
          state: SensorLiveState.live,
          updatedAt: timestamp,
        ),
      if (humidity != null)
        SensorReading(
          id: 'humidity',
          type: SensorType.humidity,
          name: 'Humidity',
          unit: '%',
          value: humidity,
          state: SensorLiveState.live,
          updatedAt: timestamp,
        ),
      if (soilMoisture != null)
        SensorReading(
          id: 'soilMoisture',
          type: SensorType.soilMoisture,
          name: 'Soil moisture',
          unit: '%',
          value: soilMoisture,
          state: SensorLiveState.live,
          updatedAt: timestamp,
        ),
    ];
    updateSensorReadings(readings);
  }

  void clearSensorData() {
    _state = _state.copyWith(
      connected: _connected,
      sensorReadings: const <SensorReading>[],
    );
    notifyListeners();
  }
}
