import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/output_device.dart';
import 'package:smart_farm/widgets/output_device_card.dart';

void main() {
  Widget host({
    required bool emergencyLocked,
    required ValueChanged<bool> onChanged,
  }) {
    const device = OutputDevice(
      id: 'relay-1',
      name: 'Pump',
      type: OutputDeviceType.pump,
      channel: 1,
      isOn: false,
      enabled: true,
      mode: OutputControlMode.manual,
      requestedOn: false,
      runtimeState: 'off',
    );

    return MaterialApp(
      home: Scaffold(
        body: OutputDeviceCard(
          device: device,
          emergencyLocked: emergencyLocked,
          onStateChanged: onChanged,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
  }

  testWidgets('output switch is disabled while emergency latch is active',
      (tester) async {
    var called = false;
    await tester.pumpWidget(
      host(
        emergencyLocked: true,
        onChanged: (_) => called = true,
      ),
    );

    final control = tester.widget<Switch>(find.byType(Switch));
    expect(control.value, isFalse);
    expect(control.onChanged, isNull);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(called, isFalse);
  });

  testWidgets('output switch is enabled again after emergency release',
      (tester) async {
    bool? requested;
    await tester.pumpWidget(
      host(
        emergencyLocked: false,
        onChanged: (value) => requested = value,
      ),
    );

    final control = tester.widget<Switch>(find.byType(Switch));
    expect(control.onChanged, isNotNull);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(requested, isTrue);
  });
}
