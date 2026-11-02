import '../models/sensor_data.dart';
import '../services/simulation_service.dart';
import 'system_data_source.dart';

class SimulationDataSource implements SystemDataSource {
  SimulationDataSource({SimulationService? service})
    : _service = service ?? SimulationService();

  final SimulationService _service;

  bool _connected = false;

  @override
  Stream<SensorData> get sensorStream => _service.stream;

  @override
  Future<void> connect() async {
    if (_connected) {
      return;
    }

    _service.start();
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) {
      return;
    }

    _service.dispose();
    _connected = false;
  }

  @override
  Future<bool> setOutputState({
    required String outputId,
    required bool value,
  }) async {
    // ตอนนี้สถานะอุปกรณ์จำลองยังจัดการผ่าน DeviceStore
    // เมื่อต่อ ESP32 จริง ตรงนี้จะส่งคำสั่งและรอ ACK
    return true;
  }
}
