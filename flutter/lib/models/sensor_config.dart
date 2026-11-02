import 'sensor_model.dart';

enum SensorBusType { i2c, analog, digital }

class SensorConfig {
  const SensorConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.driverKey,
    required this.inputId,
    required this.enabled,
  });

  final String id;
  final String name;
  final SensorType type;
  final String driverKey;
  final String inputId;
  final bool enabled;

  SensorConfig copyWith({
    String? name,
    SensorType? type,
    String? driverKey,
    String? inputId,
    bool? enabled,
  }) {
    return SensorConfig(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      driverKey: driverKey ?? this.driverKey,
      inputId: inputId ?? this.inputId,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'type': type.name,
    'driverKey': driverKey,
    'inputId': inputId,
    'enabled': enabled,
  };

  factory SensorConfig.fromJson(Map<String, Object?> json) {
    return SensorConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      type: SensorType.values.byName(json['type'] as String),
      driverKey: json['driverKey'] as String,
      inputId: json['inputId'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class SupportedSensorProfile {
  const SupportedSensorProfile({
    required this.driverKey,
    required this.type,
    required this.nameTh,
    required this.nameEn,
    required this.busType,
    required this.recommendedInput,
    required this.wiringTh,
    required this.wiringEn,
  });

  final String driverKey;
  final SensorType type;
  final String nameTh;
  final String nameEn;
  final SensorBusType busType;
  final String recommendedInput;
  final String wiringTh;
  final String wiringEn;
}

const List<SupportedSensorProfile>
supportedSensorProfiles = <SupportedSensorProfile>[
  SupportedSensorProfile(
    driverKey: 'sht31_temperature',
    type: SensorType.temperature,
    nameTh: 'SHT31 อุณหภูมิ',
    nameEn: 'SHT31 Temperature',
    busType: SensorBusType.i2c,
    recommendedInput: 'I2C BUS',
    wiringTh: 'VCC→3.3V, GND→GND, SDA→GPIO8, SCL→GPIO9',
    wiringEn: 'VCC→3.3V, GND→GND, SDA→GPIO8, SCL→GPIO9',
  ),
  SupportedSensorProfile(
    driverKey: 'sht31_humidity',
    type: SensorType.humidity,
    nameTh: 'SHT31 ความชื้นอากาศ',
    nameEn: 'SHT31 Air Humidity',
    busType: SensorBusType.i2c,
    recommendedInput: 'I2C BUS',
    wiringTh: 'ใช้บัสเดียวกับ SHT31 อุณหภูมิ ที่อยู่ 0x44',
    wiringEn: 'Shares the SHT31 I2C bus on GPIO8/GPIO9 at address 0x44',
  ),
  SupportedSensorProfile(
    driverKey: 'chirp_soil_i2c',
    type: SensorType.soilMoisture,
    nameTh: 'Chirp! ความชื้นดิน I²C',
    nameEn: 'Chirp! I²C Soil Moisture',
    busType: SensorBusType.i2c,
    recommendedInput: 'I2C BUS',
    wiringTh: 'VCC→3.3V, GND→GND, SDA→GPIO8, SCL→GPIO9; ค่าเริ่มต้น 0x20',
    wiringEn: 'VCC→3.3V, GND→GND, SDA→GPIO8, SCL→GPIO9; default 0x20',
  ),
  SupportedSensorProfile(
    driverKey: 'jsn_sr04t',
    type: SensorType.waterLevel,
    nameTh: 'JSN-SR04T ระดับน้ำ',
    nameEn: 'JSN-SR04T Water Level',
    busType: SensorBusType.digital,
    recommendedInput: 'DI1 + DI2',
    wiringTh: 'TRIG→DI1/GPIO32, ECHO→DI2/GPIO33 ผ่านตัวแบ่งแรงดัน 5V→3.3V',
    wiringEn: 'TRIG→DI1/GPIO32, ECHO→DI2/GPIO33 through a 5V-to-3.3V divider',
  ),
  SupportedSensorProfile(
    driverKey: 'ina226_battery',
    type: SensorType.battery,
    nameTh: 'INA226 แบตเตอรี่',
    nameEn: 'INA226 Battery Meter',
    busType: SensorBusType.i2c,
    recommendedInput: 'I2C BUS',
    wiringTh:
        'SDA→GPIO8, SCL→GPIO9, IN+/IN- อนุกรมสายบวกแบตเตอรี่; แนะนำ address 0x40',
    wiringEn:
        'SDA→GPIO8, SCL→GPIO9, IN+/IN- in series with battery positive; use 0x40',
  ),
  SupportedSensorProfile(
    driverKey: 'ina226_solar',
    type: SensorType.solar,
    nameTh: 'INA226 โซลาร์เซลล์',
    nameEn: 'INA226 Solar Meter',
    busType: SensorBusType.i2c,
    recommendedInput: 'I2C BUS',
    wiringTh:
        'SDA→GPIO8, SCL→GPIO9, IN+/IN- อนุกรมสายบวกโซลาร์; เปลี่ยน address เป็น 0x41',
    wiringEn:
        'SDA→GPIO8, SCL→GPIO9, IN+/IN- in series with solar positive; set 0x41',
  ),
];
