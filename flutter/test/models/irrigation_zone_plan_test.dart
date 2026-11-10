import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_farm/models/irrigation_zone_plan.dart';
import 'package:smart_farm/services/irrigation_zone_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('first run contains only one optional water spinach zone', () {
    final plan = IrrigationPlan.firstUse();
    expect(plan.delivery, WaterDelivery.pumpDirect);
    expect(plan.zones, hasLength(1));
    expect(plan.zones.single.cropId, 'water_spinach');
    expect(plan.pumpChannel, isNull);
    expect(plan.canApplyToController, isFalse);
    expect(plan.validate().map((issue) => issue.code), contains('channel_unassigned'));
  });

  test('two zones with shared pump need valves; do not reserve 8 channels', () {
    final plan = IrrigationPlan(
      delivery: WaterDelivery.sharedPumpValves,
      pumpChannel: 1,
      zones: const <IrrigationZone>[
        IrrigationZone(id: 'z1', name: 'โซน 1', cropId: 'water_spinach', valveChannel: 2),
        IrrigationZone(id: 'z2', name: 'โซน 2', cropId: 'lettuce', valveChannel: 3),
      ],
    );
    expect(plan.validate(), isEmpty);
    expect(plan.canApplyToController, isFalse);
    expect(
      plan.validate(existingDeviceChannels: <int>{3}).map((x) => x.code),
      contains('channel_reserved'),
    );
  });

  test('direct pump cannot split zones; shared hardware cannot double book', () {
    final base = IrrigationPlan(
      delivery: WaterDelivery.sharedPumpValves,
      pumpChannel: 1,
      zones: const <IrrigationZone>[
        IrrigationZone(id: 'z1', name: 'Zone 1', cropId: 'water_spinach', valveChannel: 1),
        IrrigationZone(id: 'z2', name: 'Zone 2', cropId: 'water_spinach', valveChannel: 2),
      ],
    );
    expect(base.validate().map((x) => x.code), contains('channel_duplicate'));
    expect(
      base.copyWith(delivery: WaterDelivery.pumpDirect).validate()
          .map((x) => x.code),
      contains('direct_pump_one_zone_only'),
    );
  });

  test('valve-only zone works without buying a shared pump', () {
    final plan = IrrigationPlan(
      delivery: WaterDelivery.valveOnly,
      zones: const <IrrigationZone>[
        IrrigationZone(id: 'zone-1', name: 'โซน 1', cropId: 'chili', valveChannel: 4),
      ],
    );
    expect(plan.validate(), isEmpty);
    expect(plan.pumpChannel, isNull);
  });

  test('moisture simulation uses hysteresis; missing sensor stops safely', () {
    const zone = IrrigationZone(
      id: 'one',
      name: 'Water spinach',
      cropId: 'water_spinach',
      control: ZoneControl.soilMoisture,
      soilSensorId: 'soil-zone-1',
      soilCalibrated: true,
      moistureStartPercent: 45,
      moistureStopPercent: 55,
    );
    IrrigationPreview result(double? moisture, {
      bool running = false,
      bool fresh = true,
      bool stop = false,
    }) => IrrigationPreviewEngine.assess(
      zone: zone,
      measuredMoisture: moisture,
      previouslyWatering: running,
      sensorFresh: fresh,
      emergencyStop: stop,
    );

    expect(result(44).wouldRequestWater, isTrue);
    expect(result(50).wouldRequestWater, isFalse);
    expect(result(50, running: true).wouldRequestWater, isTrue);
    expect(result(55, running: true).wouldRequestWater, isFalse);
    expect(result(null).wouldRequestWater, isFalse);
    expect(result(35, fresh: false).wouldRequestWater, isFalse);
    expect(result(35, stop: true).wouldRequestWater, isFalse);
    expect(
      IrrigationPreviewEngine.assess(
        zone: zone.copyWith(soilCalibrated: false),
        measuredMoisture: 22,
        sensorFresh: true,
      ).wouldRequestWater,
      isFalse,
    );
  });

  test('zone drafts persist across reads without changing crop templates', () async {
    final repo = IrrigationZoneRepository();
    final original = await repo.load();
    expect(original.zones.single.cropId, 'water_spinach');
    final selected = original.copyWith(
      delivery: WaterDelivery.sharedPumpValves,
      pumpChannel: 1,
      zones: const <IrrigationZone>[
        IrrigationZone(id: 'zone-1', name: 'โซน 1', cropId: 'water_spinach', valveChannel: 2),
        IrrigationZone(id: 'zone-2', name: 'โซน 2', cropId: 'water_spinach', valveChannel: 3),
      ],
    );
    expect(await repo.save(selected), isTrue);
    final loaded = await IrrigationZoneRepository().load();
    expect(loaded.zones, hasLength(2));
    expect(loaded.zones[0].cropId, loaded.zones[1].cropId);
    expect(loaded.validate(), isEmpty);
    expect(loaded.canApplyToController, isFalse);
  });
}
