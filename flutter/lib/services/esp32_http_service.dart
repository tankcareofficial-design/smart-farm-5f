import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/wifi_network.dart';

class Esp32HttpException implements Exception {
  const Esp32HttpException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.path,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? path;

  @override
  String toString() {
    final code = statusCode;
    final route = path == null ? '' : ' [$path]';
    final apiCode = errorCode == null ? '' : ' ($errorCode)';
    return code == null
        ? '$message$apiCode$route'
        : 'HTTP $code: $message$apiCode$route';
  }
}

class Esp32HttpService {
  Esp32HttpService({
    String baseUrl = 'http://192.168.4.1',
    http.Client? client,
    this.timeout = const Duration(seconds: 4),
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  String _baseUrl;

  String get baseUrl => _baseUrl;

  set baseUrl(String value) {
    _baseUrl = _normalizeBaseUrl(value);
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<Map<String, dynamic>> getDevice() => _getJsonWithRetry('/api/device');

  Future<Map<String, dynamic>> getState() {
    return _getJson('/api/state');
  }

  Future<Map<String, dynamic>> getRelays() {
    return _getJson('/api/relays');
  }

  Future<List<WifiNetwork>> scanWifi() async {
    const maxPolls = 30;
    for (var poll = 0; poll < maxPolls; poll++) {
      final data = await _getJson('/api/wifi/scan');
      if (data['scanning'] == true) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        continue;
      }

      final raw = data['networks'];
      if (raw is! List) return const <WifiNetwork>[];
      return raw
          .whereType<Map>()
          .map((item) => WifiNetwork.fromJson(Map<String, dynamic>.from(item)))
          .where((network) => network.ssid.isNotEmpty)
          .toList();
    }

    throw const Esp32HttpException(
      'การสแกน Wi-Fi ใช้เวลานานเกินไป กรุณาลองใหม่',
      errorCode: 'wifi_scan_timeout',
      path: '/api/wifi/scan',
    );
  }

  Future<Map<String, dynamic>> connectWifi({
    required String ssid,
    required String password,
  }) {
    return _postJson('/api/wifi/connect', <String, dynamic>{
      'ssid': ssid,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> emergencyStop() {
    return _postJson('/api/emergency-stop', const <String, dynamic>{});
  }

  Future<Map<String, dynamic>> releaseEmergencyStop() {
    return _postJson('/api/emergency-release', const <String, dynamic>{});
  }

  Future<Map<String, dynamic>> getClock() => _getJson('/api/v3/clock');

  Future<Map<String, dynamic>> syncClock() {
    final now = DateTime.now();
    return _postJson('/api/v3/clock/sync', <String, dynamic>{
      'year': now.year,
      'month': now.month,
      'day': now.day,
      'dayOfWeek': now.weekday,
      'hour': now.hour,
      'minute': now.minute,
      'second': now.second,
      'source': 'phone_local',
    });
  }

  Future<Map<String, dynamic>> getSnapshot() => _getJson('/api/v3/snapshot');

  Future<Map<String, dynamic>> getRuntime() => _getJson('/api/v3/runtime');

  Future<Map<String, dynamic>> requestDevice({
    required String deviceId,
    required bool on,
    bool force = false,
    int overrideSeconds = 300,
  }) => _postJson('/api/v3/devices/request', <String, dynamic>{
    'deviceId': deviceId,
    'desiredState': on ? 'on' : 'off',
    'force': force,
    'overrideSeconds': overrideSeconds,
  });

  Future<Map<String, dynamic>> saveDeviceProfile(
    Map<String, dynamic> profile,
  ) => _postJson('/api/v3/devices/config', profile);

  Future<Map<String, dynamic>> deleteDeviceProfile(String deviceId) =>
      _postJson('/api/v3/devices/delete', <String, dynamic>{'deviceId': deviceId});

  Future<Map<String, dynamic>> evaluateDevice(String deviceId) => _postJson(
    '/api/v3/devices/evaluate',
    <String, dynamic>{'deviceId': deviceId},
  );

  Future<Map<String, dynamic>> getAutomations() =>
      _getJson('/api/v2/automations');

  Future<Map<String, dynamic>> saveAutomation(Map<String, dynamic> rule) =>
      _postJson('/api/v2/automations', rule);

  Future<Map<String, dynamic>> deleteAutomation(String id) =>
      _postJson('/api/v2/automations/delete', <String, dynamic>{'id': id});

  Future<Map<String, dynamic>> testAutomation(String id) =>
      _postJson('/api/v2/automations/test', <String, dynamic>{'id': id});

  Future<Map<String, dynamic>> setRelay({
    required int channel,
    required bool on,
    int overrideSeconds = 300,
  }) {
    return _postJson('/api/relay', <String, dynamic>{
      'channel': channel,
      'on': on,
      'overrideSeconds': overrideSeconds,
    });
  }


  Future<Map<String, dynamic>> _getJsonWithRetry(String path) async {
    const delays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 300),
      Duration(milliseconds: 800),
    ];
    Object? lastError;
    for (final delay in delays) {
      if (delay != Duration.zero) await Future<void>.delayed(delay);
      try {
        return await _getJson(path);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? const Esp32HttpException('ไม่พบกล่องควบคุม');
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      final response = await _client
          .get(
            _uri(path),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(timeout);

      return _decodeResponse(response, path);
    } on Esp32HttpException {
      rethrow;
    } catch (error) {
      throw Esp32HttpException('ติดต่อกล่องควบคุมไม่สำเร็จ: $error');
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      if (kDebugMode) {
        final safeBody = Map<String, dynamic>.from(body);
        if (path == '/api/wifi/connect' && safeBody.containsKey('password')) {
          safeBody['password'] = '***';
        }
        debugPrint('[ESP32 HTTP] POST $path ${jsonEncode(safeBody)}');
      }
      final response = await _client
          .post(
            _uri(path),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (kDebugMode) {
        debugPrint(
          '[ESP32 HTTP] ${response.statusCode} $path ${utf8.decode(response.bodyBytes)}',
        );
      }
      return _decodeResponse(response, path);
    } on Esp32HttpException {
      rethrow;
    } catch (error) {
      throw Esp32HttpException('ส่งคำสั่งไปกล่องควบคุมไม่สำเร็จ: $error');
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response, String path) {
    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('JSON root is not an object');
      }
      data = Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw Esp32HttpException(
        'กล่องควบคุมส่งข้อมูลที่อ่านไม่ได้: $error',
        statusCode: response.statusCode,
        path: path,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message =
          data['message']?.toString() ??
          data['error']?.toString() ??
          'คำขอไม่สำเร็จ';
      throw Esp32HttpException(
        message,
        statusCode: response.statusCode,
        errorCode: data['error']?.toString(),
        path: path,
      );
    }

    if (data['ok'] == false) {
      throw Esp32HttpException(
        data['message']?.toString() ??
            data['error']?.toString() ??
            'กล่องควบคุมตอบกลับว่าไม่สำเร็จ',
        statusCode: response.statusCode,
        errorCode: data['error']?.toString(),
        path: path,
      );
    }

    return data;
  }

  void close() {
    _client.close();
  }

  static String _normalizeBaseUrl(String value) {
    var result = value.trim();

    if (result.isEmpty) {
      result = 'http://192.168.4.1';
    }

    if (!result.startsWith('http://') && !result.startsWith('https://')) {
      result = 'http://$result';
    }

    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }
}
