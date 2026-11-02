import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/output_device.dart';

class DeviceRepository {
  static const String _key = 'output_devices_v2_live';
  static const String _controllerKey = 'output_devices_controller_id_v1';

  Future<List<OutputDevice>?> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map(
          (Object? item) =>
              OutputDevice.fromJson(Map<String, Object?>.from(item! as Map)),
        )
        .toList();
  }

  Future<String?> loadControllerId() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_controllerKey);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> saveControllerId(String controllerId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_controllerKey, controllerId);
  }

  Future<void> save(List<OutputDevice> devices) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String raw = jsonEncode(
      devices.map((OutputDevice device) => device.toJson()).toList(),
    );
    await preferences.setString(_key, raw);
  }
}
