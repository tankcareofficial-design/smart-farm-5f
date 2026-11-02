import 'dart:async';

import 'package:flutter/material.dart';

import '../models/sensor_config.dart';
import '../models/sensor_model.dart';
import '../services/sensor_repository.dart';

/// Stores sensor configuration locally and synchronizes readings through the active data source.
/// Live sensor values are intentionally empty until the 5H sensor protocol is
/// connected to ESP32. This prevents demo values from being presented as real.
class SensorStore extends ChangeNotifier {
  SensorStore({SensorRepository? repository})
    : _repository = repository ?? SensorRepository();

  final SensorRepository _repository;
  List<SensorConfig> _configs = <SensorConfig>[];
  final List<SensorModel> _sensors = <SensorModel>[];
  bool _started = false;
  bool _loading = true;
  String? _errorMessage;

  List<SensorConfig> get configs => List<SensorConfig>.unmodifiable(_configs);
  List<SensorModel> get sensors => List<SensorModel>.unmodifiable(_sensors);
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => null;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _loading = true;
    notifyListeners();
    try {
      _configs = await _repository.load() ?? <SensorConfig>[];
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'ไม่สามารถโหลดรายการเซ็นเซอร์ได้';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool isInputUsed(String inputId, {String? excludingId}) {
    if (inputId == 'I2C BUS') return false;
    return _configs.any(
      (SensorConfig item) => item.inputId == inputId && item.id != excludingId,
    );
  }

  void addSensor(SensorConfig config) {
    if (isInputUsed(config.inputId)) {
      throw ArgumentError('INPUT นี้ถูกใช้งานแล้ว');
    }
    _configs.add(config);
    _commitConfigs();
  }

  void updateSensor(SensorConfig config) {
    final int index = _configs.indexWhere((item) => item.id == config.id);
    if (index == -1) return;
    if (isInputUsed(config.inputId, excludingId: config.id)) {
      throw ArgumentError('INPUT นี้ถูกใช้งานแล้ว');
    }
    _configs[index] = config;
    _commitConfigs();
  }

  void removeSensor(String id) {
    _configs.removeWhere((item) => item.id == id);
    _commitConfigs();
  }

  void setSensorEnabled(String id, bool enabled) {
    final int index = _configs.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _configs[index] = _configs[index].copyWith(enabled: enabled);
    _commitConfigs();
  }

  void _commitConfigs() {
    notifyListeners();
    unawaited(_repository.save(_configs));
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _configs = await _repository.load() ?? <SensorConfig>[];
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'ไม่สามารถโหลดรายการเซ็นเซอร์ได้';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
