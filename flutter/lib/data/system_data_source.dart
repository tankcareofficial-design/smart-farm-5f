import '../models/sensor_data.dart';

abstract class SystemDataSource {
  Stream<SensorData> get sensorStream;

  Future<void> connect();

  Future<void> disconnect();

  Future<bool> setOutputState({required String outputId, required bool value});
}
