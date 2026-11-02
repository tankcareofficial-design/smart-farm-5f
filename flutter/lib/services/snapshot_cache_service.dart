import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/controller_snapshot.dart';

class SnapshotCacheService {
  static const _key = 'smart_farm_r87_snapshot';
  Future<ControllerSnapshot?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return null;
    try {
      return ControllerSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> snapshot) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(snapshot));
  }
}
