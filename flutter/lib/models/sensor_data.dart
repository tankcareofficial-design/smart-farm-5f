class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double waterLevel;
  final double battery;
  final double solarVoltage;
  final DateTime updatedAt;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.waterLevel,
    required this.battery,
    required this.solarVoltage,
    required this.updatedAt,
  });

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    double? waterLevel,
    double? battery,
    double? solarVoltage,
    DateTime? updatedAt,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      waterLevel: waterLevel ?? this.waterLevel,
      battery: battery ?? this.battery,
      solarVoltage: solarVoltage ?? this.solarVoltage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
