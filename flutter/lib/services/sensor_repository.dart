import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_config.dart';

class SensorRepository {
  static const String _key = 'sensor_configs_v2_live';

  Future<List<SensorConfig>?> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map(
          (Object? item) =>
              SensorConfig.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList();
  }

  Future<void> save(List<SensorConfig> sensors) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(sensors.map((SensorConfig item) => item.toJson()).toList()),
    );
  }
}
