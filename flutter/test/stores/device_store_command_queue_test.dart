import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/controllers/smart_farm_controller.dart';
import 'package:smart_farm/models/output_device.dart';
import 'package:smart_farm/stores/device_store.dart';

class _DelayedController extends SmartFarmController {
  _DelayedController() {
    connected = true;
  }

  final List<bool> commands = <bool>[];
  final Completer<void> firstCommandGate = Completer<void>();
  void Function()? beforeFirstCommandReturns;

  @override
  Future<bool> setRelay(int channel, bool on) async {
    commands.add(on);
    if (commands.length == 1) {
      await firstCommandGate.future;
      beforeFirstCommandReturns?.call();
    }
    relays[channel] = relays[channel].copyWith(on: on);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rapid relay input keeps and sends the latest command', () async {
    final device = OutputDevice(
      id: 'manual-1',
      name: 'Manual relay',
      type: OutputDeviceType.pump,
      channel: 1,
      isOn: false,
      enabled: true,
      mode: OutputControlMode.manual,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'output_devices_v2_live': jsonEncode(<Object?>[device.toJson()]),
    });

    final controller = _DelayedController();
    final store = DeviceStore(controller: controller);
    while (!store.initialized) {
      await Future<void>.delayed(Duration.zero);
    }

    final first = store.setOutputState(device.id, true);
    await Future<void>.delayed(Duration.zero);
    final second = store.setOutputState(device.id, false);

    expect(store.outputs.single.requestedOn, isFalse);
    expect(controller.commands, <bool>[true]);

    controller.firstCommandGate.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(controller.commands, <bool>[true, false]);
    expect(store.outputs.single.isOn, isFalse);
    expect(store.outputs.single.requestedOn, isFalse);
  });

  test('command arriving as the active request completes is not lost', () async {
    final device = OutputDevice(
      id: 'manual-boundary',
      name: 'Boundary relay',
      type: OutputDeviceType.pump,
      channel: 1,
      isOn: false,
      enabled: true,
      mode: OutputControlMode.manual,
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      'output_devices_v2_live': jsonEncode(<Object?>[device.toJson()]),
    });

    final controller = _DelayedController();
    final store = DeviceStore(controller: controller);
    while (!store.initialized) {
      await Future<void>.delayed(Duration.zero);
    }

    Future<bool>? boundaryCommand;
    controller.beforeFirstCommandReturns = () {
      boundaryCommand = store.setOutputState(device.id, false);
    };

    final first = store.setOutputState(device.id, true);
    await Future<void>.delayed(Duration.zero);
    controller.firstCommandGate.complete();

    expect(await first, isTrue);
    expect(await boundaryCommand!, isTrue);
    expect(controller.commands, <bool>[true, false]);
    expect(store.outputs.single.isOn, isFalse);
  });

}
