import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/irrigation_zone_plan.dart';
import 'package:smart_farm/screens/irrigation_simulation_screen.dart';

void main() {
  const plan = IrrigationPlan(
    delivery: WaterDelivery.sharedPumpValves,
    pumpChannel: 1,
    zones: <IrrigationZone>[
      IrrigationZone(id: 'zone-1', name: 'โซนผักบุ้ง', cropId: 'water_spinach'),
      IrrigationZone(id: 'zone-2', name: 'โซนสำรอง', cropId: 'water_spinach'),
    ],
  );

  testWidgets('offline-only simulator is readable and never offers Apply',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: IrrigationSimulationScreen(plan: plan)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ห้องทดลองในโทรศัพท์'), findsOneWidget);
    expect(find.textContaining('45/55%'), findsOneWidget);
    expect(find.textContaining('ยังไม่ต้องเปิดปั๊ม'), findsOneWidget);
    expect(find.text('ใช้กับกล่องควบคุม'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a dry demo changes the mock zone status',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: IrrigationSimulationScreen(plan: plan)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('simulation-dry-zone-1')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('simulation-dry-zone-1')));
    await tester.pump();
    expect(find.textContaining('จำลอง: ให้น้ำโซนนี้'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
