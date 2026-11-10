import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/controllers/smart_farm_controller.dart';
import 'package:smart_farm/models/output_device.dart';
import 'package:smart_farm/stores/device_store.dart';

class _ProfileController extends SmartFarmController {
  _ProfileController() {
    connected = true;
  }

  bool acceptSave = true;
  bool acceptDelete = true;
  Completer<bool>? deleteGate;
  final List<Map<String, dynamic>> savedProfiles = <Map<String, dynamic>>[];
  final List<String> deleteRequests = <String>[];

  @override
  Future<bool> saveDeviceProfile(Map<String, dynamic> profile) async {
    savedProfiles.add(Map<String, dynamic>.from(profile));
    return acceptSave;
  }

  @override
  Future<bool> deleteDeviceProfile(String deviceId) async {
    deleteRequests.add(deviceId);
    if (deleteGate != null) return deleteGate!.future;
    return acceptDelete;
  }
}

OutputDevice _device({bool on = false}) => OutputDevice(
  id: 'profile-test',
  name: 'Pump',
  type: OutputDeviceType.pump,
  channel: 1,
  isOn: on,
  enabled: true,
  mode: OutputControlMode.manual,
  requestedOn: on,
);

Future<DeviceStore> _startStore(
  _ProfileController controller,
  OutputDevice device,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'output_devices_v2_live': jsonEncode(<Object?>[device.toJson()]),
  });
  final store = DeviceStore(controller: controller);
  while (!store.initialized) {
    await Future<void>.delayed(Duration.zero);
  }
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('manual device saves without crop preset or installed sensor', () async {
    final controller = _ProfileController();
    final device = _device().copyWith(
      name: 'Independent light',
      type: OutputDeviceType.light,
      mode: OutputControlMode.manual,
      schedule: const DeviceScheduleConfig(enabled: false),
      condition: const DeviceConditionConfig(enabled: false),
    );
    final store = await _startStore(controller, device);

    expect(await store.updateOutput(device), isTrue);
    final saved = controller.savedProfiles.single;
    final trigger = saved['trigger'] as Map<String, dynamic>;
    final schedule = trigger['schedule'] as Map<String, dynamic>;
    final conditions = saved['conditions'] as List<dynamic>;
    expect(saved['deviceType'], 'light');
    expect(saved['controlMode'], 'manual');
    expect(schedule['enabled'], isFalse);
    expect(conditions, isEmpty);
    expect(store.outputs.single.mode, OutputControlMode.manual);
    expect(store.outputs.single.type, OutputDeviceType.light);

    store.dispose();
    controller.dispose();
  });

  test('edit schedule saves the window before updating local device', () async {
    final controller = _ProfileController();
    final device = _device();
    final store = await _startStore(controller, device);
    final changed = device.copyWith(
      mode: OutputControlMode.schedule,
      schedule: const DeviceScheduleConfig(
        enabled: true,
        hour: 6,
        minute: 0,
        endHour: 6,
        endMinute: 20,
        daysMask: 0x1F,
      ),
    );

    expect(await store.updateOutput(changed), isTrue);
    final saved = controller.savedProfiles.single;
    final trigger = saved['trigger'] as Map<String, dynamic>;
    final schedule = trigger['schedule'] as Map<String, dynamic>;
    final actions = saved['actions'] as List<dynamic>;
    expect(saved['deviceId'], device.id);
    expect(saved['controlMode'], 'schedule');
    expect(schedule['mode'], 'window');
    expect(schedule['enabled'], isTrue);
    expect(schedule['daysOfWeek'], <int>[1, 2, 3, 4, 5]);
    expect((actions.single as Map<String, dynamic>)['durationSeconds'], 1200);
    expect(store.outputs.single.schedule.endMinute, 20);

    store.dispose();
    controller.dispose();
  });

  test('edit sensor condition saves thresholds to controller', () async {
    final controller = _ProfileController();
    final device = _device();
    final store = await _startStore(controller, device);
    final changed = device.copyWith(
      mode: OutputControlMode.automatic,
      condition: const DeviceConditionConfig(
        enabled: true,
        sensorId: 'soil-1',
        metric: 'soil_moisture',
        operator: '<',
        value: 35,
        stopValue: 55,
      ),
    );

    expect(await store.updateOutput(changed), isTrue);
    final saved = controller.savedProfiles.single;
    final conditions = saved['conditions'] as List<dynamic>;
    final condition = conditions.single as Map<String, dynamic>;
    expect(saved['controlMode'], 'automatic');
    expect(condition['sensorId'], 'soil-1');
    expect(condition['value'], 35);
    expect(condition['valueHigh'], 55);
    expect(store.outputs.single.condition.stopValue, 55);

    store.dispose();
    controller.dispose();
  });

  test('rejected edit never overwrites the locally saved profile', () async {
    final controller = _ProfileController()..acceptSave = false;
    final device = _device();
    final store = await _startStore(controller, device);
    final changed = device.copyWith(
      mode: OutputControlMode.schedule,
      schedule: const DeviceScheduleConfig(
        enabled: true,
        hour: 8,
        minute: 0,
        endHour: 8,
        endMinute: 15,
      ),
    );

    expect(await store.updateOutput(changed), isFalse);
    expect(controller.savedProfiles, hasLength(1));
    expect(store.outputs.single.mode, OutputControlMode.manual);
    expect(store.outputs.single.schedule.enabled, isFalse);

    store.dispose();
    controller.dispose();
  });

  test('delete keeps the ON device until controller acknowledges success', () async {
    final controller = _ProfileController();
    controller.relays[0] = controller.relays[0].copyWith(on: true);
    final store = await _startStore(controller, _device(on: true));
    final firstGate = Completer<bool>();
    controller.deleteGate = firstGate;

    final firstAttempt = store.removeOutput('profile-test');
    await Future<void>.delayed(Duration.zero);
    expect(controller.deleteRequests, <String>['profile-test']);
    expect(store.outputs.single.isOn, isTrue);

    firstGate.complete(false);
    expect(await firstAttempt, isFalse);
    expect(store.outputs, hasLength(1));

    final secondGate = Completer<bool>();
    controller.deleteGate = secondGate;
    final secondAttempt = store.removeOutput('profile-test');
    await Future<void>.delayed(Duration.zero);
    expect(store.outputs, hasLength(1));

    // Controller-side delete API must force the relay OFF before returning OK.
    // This fake verifies the client-side acknowledgment barrier only.
    secondGate.complete(true);
    expect(await secondAttempt, isTrue);
    expect(store.outputs, isEmpty);
    expect(controller.deleteRequests, <String>[
      'profile-test',
      'profile-test',
    ]);

    store.dispose();
    controller.dispose();
  });
}
