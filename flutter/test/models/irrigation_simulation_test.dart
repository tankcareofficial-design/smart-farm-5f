import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/irrigation_simulation.dart';
import 'package:smart_farm/models/irrigation_zone_plan.dart';

void main() {
  const zoneA = IrrigationZone(
    id: 'z1', name: 'แปลงผักบุ้ง', cropId: 'water_spinach',
  );
  const zoneB = IrrigationZone(
    id: 'z2', name: 'โซนสาธิต', cropId: 'water_spinach',
  );
  const sharedPlan = IrrigationPlan(
    delivery: WaterDelivery.sharedPumpValves,
    pumpChannel: 1,
    zones: <IrrigationZone>[zoneA, zoneB],
  );

  test('45/55 is a DEMO band and shared pump serves one zone at a time', () {
    const moisture = <String, double?>{'z1': 30, 'z2': 30};
    final first = IrrigationSimulationEngine.evaluate(
      plan: sharedPlan, moistureByZone: moisture,
    );
    expect(first.activeZoneId, 'z1');
    expect(first.pumpWouldRun, isTrue);
    expect(first.waitingZoneIds, <String>{'z2'});

    final stillFirst = IrrigationSimulationEngine.evaluate(
      plan: sharedPlan,
      moistureByZone: <String, double?>{'z1': 50, 'z2': 25},
      previousActiveZoneId: first.activeZoneId,
    );
    expect(stillFirst.activeZoneId, 'z1');
    expect(stillFirst.waitingZoneIds, <String>{'z2'});

    final second = IrrigationSimulationEngine.evaluate(
      plan: sharedPlan,
      moistureByZone: <String, double?>{'z1': 55, 'z2': 25},
      previousActiveZoneId: first.activeZoneId,
    );
    expect(second.activeZoneId, 'z2');
    expect(second.pumpWouldRun, isTrue);
    expect(second.waitingZoneIds, isEmpty);
  });

  test('a missing or invalid zone reading never requests water', () {
    final result = IrrigationSimulationEngine.evaluate(
      plan: sharedPlan,
      moistureByZone: <String, double?>{'z1': null, 'z2': -5},
    );
    expect(result.activeZoneId, isNull);
    expect(result.pumpWouldRun, isFalse);
    expect(result.wantWaterZoneIds, isEmpty);
  });

  test('simulated emergency stop blocks all zones regardless of moisture', () {
    final result = IrrigationSimulationEngine.evaluate(
      plan: sharedPlan,
      moistureByZone: <String, double?>{'z1': 1, 'z2': 2},
      emergencyStop: true,
    );
    expect(result.activeZoneId, isNull);
    expect(result.waitingZoneIds, isEmpty);
    expect(result.pumpWouldRun, isFalse);
  });

  test('valve-only plan needs no simulated pump request', () {
    const valvePlan = IrrigationPlan(
      delivery: WaterDelivery.valveOnly,
      zones: <IrrigationZone>[zoneA],
    );
    final result = IrrigationSimulationEngine.evaluate(
      plan: valvePlan,
      moistureByZone: <String, double?>{'z1': 30},
    );
    expect(result.activeZoneId, 'z1');
    expect(result.pumpWouldRun, isFalse);
  });

  test('unvalved multi-zone direct-pump plan is rejected fail-closed', () {
    const invalidPlan = IrrigationPlan(
      delivery: WaterDelivery.pumpDirect,
      pumpChannel: 1,
      zones: <IrrigationZone>[zoneA, zoneB],
    );
    final result = IrrigationSimulationEngine.evaluate(
      plan: invalidPlan,
      moistureByZone: <String, double?>{'z1': 30, 'z2': 30},
    );
    expect(result.activeZoneId, isNull);
    expect(result.pumpWouldRun, isFalse);
  });
}
