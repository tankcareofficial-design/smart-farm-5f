import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/screens/devices_screen.dart';
import 'package:smart_farm/stores/device_store.dart';
import 'package:smart_farm/stores/sensor_store.dart';
import 'package:smart_farm/widgets/output_device_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('offline controller warns even with zero devices and blocks add',
      (tester) async {
    final devices = DeviceStore();
    final sensors = SensorStore();
    await tester.pumpWidget(
      MaterialApp(
        home: DevicesScreen(store: devices, sensorStore: sensors),
      ),
    );
    await tester.pump();

    expect(devices.controllerConnected, isFalse);
    expect(find.textContaining('กล่องควบคุมออฟไลน์'), findsWidgets);
    expect(find.text('เพิ่มอุปกรณ์แรก'), findsOneWidget);

    await tester.tap(find.text('เพิ่มอุปกรณ์แรก'));
    await tester.pump();

    expect(
      find.byKey(const Key('controller-offline-action-warning')),
      findsOneWidget,
    );
    expect(find.byType(OutputDeviceDialog), findsNothing);
    expect(devices.outputs, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    devices.dispose();
    sensors.dispose();
  });
}
