import 'irrigation_zone_plan.dart';

/// A deterministic demand/arbitration PREVIEW. No controller, GPIO or network.
class IrrigationSimulationResult {
  const IrrigationSimulationResult({
    required this.activeZoneId,
    required this.pumpWouldRun,
    required this.wantWaterZoneIds,
    required this.waitingZoneIds,
  });

  final String? activeZoneId;
  final bool pumpWouldRun;
  final Set<String> wantWaterZoneIds;
  final Set<String> waitingZoneIds;
}

class IrrigationSimulationEngine {
  const IrrigationSimulationEngine._();

  /// The 45/55% band is solely a DEMO of hysteresis. It is not a crop preset,
  /// an agronomic recommendation, or an authorized relay setpoint.
  static const double demoStartPercent = 45;
  static const double demoStopPercent = 55;

  /// Simulate one-at-a-time irrigation using separate per-zone readings.
  /// Keep a previously selected zone only while it remains below its STOP
  /// threshold, then choose the first waiting zone from the current plan.
  /// A missing/invalid reading and an emergency condition both fail closed.
  static IrrigationSimulationResult evaluate({
    required IrrigationPlan plan,
    required Map<String, double?> moistureByZone,
    String? previousActiveZoneId,
    bool emergencyStop = false,
  }) {
    if (emergencyStop ||
        plan.zones.isEmpty ||
        (plan.delivery == WaterDelivery.pumpDirect && plan.zones.length != 1)) {
      return const IrrigationSimulationResult(
        activeZoneId: null,
        pumpWouldRun: false,
        wantWaterZoneIds: <String>{},
        waitingZoneIds: <String>{},
      );
    }

    final demand = <String>{};
    for (final zone in plan.zones) {
      // The copy exists *only* in this simulation's local call stack.
      // No sensor is claimed as physically installed or calibrated.
      final demoZone = zone.copyWith(
        control: ZoneControl.soilMoisture,
        soilSensorId: 'SIMULATION_ONLY',
        soilCalibrated: true,
        moistureStartPercent: demoStartPercent,
        moistureStopPercent: demoStopPercent,
      );
      final reading = moistureByZone[zone.id];
      final preview = IrrigationPreviewEngine.assess(
        zone: demoZone,
        measuredMoisture: reading,
        sensorFresh: reading != null,
        previouslyWatering: previousActiveZoneId == zone.id,
        emergencyStop: emergencyStop,
      );
      if (preview.wouldRequestWater) demand.add(zone.id);
    }

    final active = previousActiveZoneId != null &&
            demand.contains(previousActiveZoneId)
        ? previousActiveZoneId
        : plan.zones
            .where((zone) => demand.contains(zone.id))
            .map((zone) => zone.id)
            .firstOrNull;

    return IrrigationSimulationResult(
      activeZoneId: active,
      pumpWouldRun: active != null && plan.delivery != WaterDelivery.valveOnly,
      wantWaterZoneIds: demand,
      waitingZoneIds: demand.difference(
        active == null ? <String>{} : <String>{active},
      ),
    );
  }
}
