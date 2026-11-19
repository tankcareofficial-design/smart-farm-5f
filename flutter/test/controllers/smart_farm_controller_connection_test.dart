import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/controllers/smart_farm_controller.dart';
import 'package:smart_farm/services/esp32_http_service.dart';

class _FakeHttpService extends Esp32HttpService {
  _FakeHttpService() : super(timeout: const Duration(milliseconds: 50));

  bool failDevice = false;
  bool failState = false;
  bool failClock = false;
  bool failSnapshot = false;
  bool failRelay = false;

  @override
  Future<Map<String, dynamic>> getDevice() async {
    if (failDevice) throw const Esp32HttpException('device failed');
    return <String, dynamic>{
        'ok': true,
        'deviceId': 'sf-test',
        'displayName': 'test',
        'firmwareVersion': 'test',
        'protocolVersion': 1,
        'apiVersion': 3,
        'hardwareProfile': 'smart_farm_8ch_v1',
        'accessorySchemaVersion': 2,
        'relayCount': 8,
        'mode': 'access_point_and_station',
        'ssid': 'SmartFarm-test',
        'ip': '192.168.4.1',
      };
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    if (failState) throw const Esp32HttpException('state failed');
    return <String, dynamic>{
      'ok': true,
      'deviceId': 'sf-test',
      'relayCount': 8,
      'relays': <Map<String, dynamic>>[
        for (var channel = 0; channel < 8; channel++)
          <String, dynamic>{'channel': channel, 'on': false},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> getClock() async {
    if (failClock) throw const Esp32HttpException('clock failed');
    return <String, dynamic>{
      'ok': true,
      'clock': <String, dynamic>{
        'available': true,
        'valid': true,
        'source': 'ds3231',
        'quality': 'rtc',
        'dateTimeLocal': '2026-11-07T06:00:00',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getSnapshot() async {
    if (failSnapshot) throw const Esp32HttpException('snapshot failed');
    return <String, dynamic>{
      'ok': true,
      'schemaVersion': 3,
      'revision': 1,
      'generatedAtMs': 1,
      'sourceOfTruth': 'esp32',
      'rules': <dynamic>[],
      'runtime': <dynamic>[],
    };
  }

  @override
  Future<Map<String, dynamic>> setRelay({
    required int channel,
    required bool on,
    int overrideSeconds = 300,
  }) async {
    if (failRelay) throw const Esp32HttpException('relay failed');
    return <String, dynamic>{
      'ok': true,
      'channel': channel,
      'on': on,
      'overrideActive': true,
    };
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('secondary endpoint failure does not make controller offline', () async {
    final http = _FakeHttpService()
      ..failClock = true
      ..failSnapshot = true;
    final controller = SmartFarmController(
      httpService: http,
      pollInterval: const Duration(hours: 1),
    );

    await controller.connect();

    expect(controller.connected, isTrue);
    expect(controller.consecutiveFailures, 0);
    expect(controller.clockFailures, 1);
    expect(controller.snapshotFailures, 1);
    controller.dispose();
  });

  test('state failure falls back to device reachability probe', () async {
    final http = _FakeHttpService();
    final controller = SmartFarmController(
      httpService: http,
      pollInterval: const Duration(hours: 1),
    );
    await controller.connect();
    http.failState = true;

    await controller.refreshState();

    expect(controller.connected, isTrue);
    expect(controller.consecutiveFailures, 0);
    expect(controller.stateFailures, 1);
    controller.dispose();
  });

  test('relay command failure does not declare controller offline', () async {
    final http = _FakeHttpService();
    final controller = SmartFarmController(
      httpService: http,
      pollInterval: const Duration(hours: 1),
    );
    await controller.connect();
    http.failRelay = true;

    final result = await controller.setRelay(0, true);

    expect(result, isFalse);
    expect(controller.connected, isTrue);
    expect(controller.consecutiveFailures, 0);
    controller.dispose();
  });

  test('reachability needs three failures and recovers on first success', () async {
    final http = _FakeHttpService();
    final controller = SmartFarmController(
      httpService: http,
      pollInterval: const Duration(hours: 1),
    );
    await controller.connect();
    expect(controller.connected, isTrue);

    http.failState = true;
    http.failDevice = true;
    for (var failure = 1; failure <= 2; failure++) {
      await controller.refreshState();
      expect(controller.consecutiveFailures, failure);
      expect(controller.connected, isTrue);
    }

    await controller.refreshState();
    expect(controller.consecutiveFailures, 3);
    expect(controller.connected, isFalse);

    // /api/state remains broken, but /api/device proves the link recovered.
    http.failDevice = false;
    await controller.refreshState();
    expect(controller.consecutiveFailures, 0);
    expect(controller.connected, isTrue);
    expect(controller.stateFailures, greaterThan(0));
    controller.dispose();
  });

  test('clock and snapshot polling errors keep the link online', () async {
    final http = _FakeHttpService();
    final controller = SmartFarmController(
      httpService: http,
      pollInterval: const Duration(hours: 1),
    );
    await controller.connect();
    http.failClock = true;
    http.failSnapshot = true;

    await controller.refreshState();

    expect(controller.connected, isTrue);
    expect(controller.consecutiveFailures, 0);
    expect(controller.clockFailures, 1);
    expect(controller.snapshotFailures, 1);
    controller.dispose();
  });
}
