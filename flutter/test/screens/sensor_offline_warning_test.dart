import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/controllers/smart_farm_controller.dart';
import 'package:smart_farm/screens/sensor_screen.dart';
import 'package:smart_farm/stores/sensor_store.dart';
import 'package:smart_farm/widgets/sensor_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('disconnection during sensor edit blocks local save', (
    tester,
  ) async {
    final controller = SmartFarmController();
    final sensors = SensorStore();
    await sensors.start();
    controller.connected = true;

    await tester.pumpWidget(MaterialApp(
      home: SensorScreen(store: sensors, controller: controller),
    ));
    await tester.pump();
    await tester.tap(find.byTooltip('เพิ่มเซ็นเซอร์'));
    await tester.pumpAndSettle();
    expect(find.byType(SensorSetupDialog), findsOneWidget);

    // The user opened the form while connected, but the controller is now gone.
    controller.connected = false;
    await tester.scrollUntilVisible(
      find.byKey(const Key('sensor-config-save')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('sensor-config-save')));
    await tester.pump();
    expect(
      find.byKey(const Key('sensor-save-controller-offline-warning')),
      findsOneWidget,
    );
    expect(sensors.configs, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    sensors.dispose();
    controller.dispose();
  });

  testWidgets('offline controller prevents adding a sensor from the UI',
      (tester) async {
    final controller = SmartFarmController();
    final sensors = SensorStore();
    await sensors.start();

    await tester.pumpWidget(MaterialApp(
      home: SensorScreen(store: sensors, controller: controller),
    ));
    await tester.pump();

    expect(controller.connected, isFalse);
    expect(
      find.byKey(const Key('sensor-controller-offline-banner')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('เพิ่มเซ็นเซอร์'));
    await tester.pump();

    expect(
      find.byKey(const Key('sensor-controller-offline-warning')),
      findsOneWidget,
    );
    expect(find.byType(SensorSetupDialog), findsNothing);
    expect(sensors.configs, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    sensors.dispose();
    controller.dispose();
  });
}
