import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/irrigation_zone_plan.dart';
import 'package:smart_farm/screens/irrigation_zones_screen.dart';
import 'package:smart_farm/services/irrigation_zone_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('first use shows one crop zone without forcing 8 relays', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: IrrigationZonesScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('irrigation-delivery')), findsOneWidget);
    expect(find.byKey(const Key('irrigation-add-zone')), findsOneWidget);
    expect(find.byKey(const Key('irrigation-pump-channel')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('irrigation-controller-apply-disabled')),
      ).onPressed,
      isNull,
    );
    final saved = await IrrigationZoneRepository().load();
    expect(saved.zones, hasLength(1));
    expect(saved.zones.single.cropId, 'water_spinach');
    expect(saved.pumpChannel, isNull);
    expect(saved.canApplyToController, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('second zone switches from direct pump to separately valved layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: IrrigationZonesScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('irrigation-add-zone')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('zone-card-zone-2')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-card-zone-2')), findsOneWidget);
    expect(find.byKey(const Key('zone-valve-zone-2')), findsOneWidget);
    final fromDisk = await IrrigationZoneRepository().load();
    expect(fromDisk.delivery, WaterDelivery.sharedPumpValves);
    expect(fromDisk.zones, hasLength(2));
    expect(fromDisk.zones.first.cropId, 'water_spinach');
    expect(fromDisk.canApplyToController, isFalse);
    expect(tester.takeException(), isNull);
  });
}
