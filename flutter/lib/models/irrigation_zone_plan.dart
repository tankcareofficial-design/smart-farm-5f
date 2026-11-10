/// Phone-only layout for future irrigation zones. Never writes ESP32 settings.
/// The user's general-purpose Manual devices remain independent.
enum WaterDelivery { pumpDirect, valveOnly, sharedPumpValves }

enum ZoneControl { manual, schedule, soilMoisture }

class IrrigationIssue {
  const IrrigationIssue(this.code, {this.zoneId});
  final String code;
  final String? zoneId;
}

class IrrigationZone {
  const IrrigationZone({
    required this.id,
    required this.name,
    required this.cropId,
    this.control = ZoneControl.manual,
    this.valveChannel,
    this.soilSensorId,
    this.soilCalibrated = false,
    this.moistureStartPercent,
    this.moistureStopPercent,
  });

  final String id;
  final String name;
  final String cropId;
  final ZoneControl control;
  /// Display-only proposal, 1-based channel number. Not a live reservation.
  final int? valveChannel;
  final String? soilSensorId;
  final bool soilCalibrated;
  final double? moistureStartPercent;
  final double? moistureStopPercent;

  IrrigationZone copyWith({
    String? name,
    String? cropId,
    ZoneControl? control,
    int? valveChannel,
    bool clearValveChannel = false,
    String? soilSensorId,
    bool clearSoilSensorId = false,
    bool? soilCalibrated,
    double? moistureStartPercent,
    double? moistureStopPercent,
  }) => IrrigationZone(
    id: id,
    name: name ?? this.name,
    cropId: cropId ?? this.cropId,
    control: control ?? this.control,
    valveChannel: clearValveChannel ? null : valveChannel ?? this.valveChannel,
    soilSensorId:
        clearSoilSensorId ? null : soilSensorId ?? this.soilSensorId,
    soilCalibrated: soilCalibrated ?? this.soilCalibrated,
    moistureStartPercent:
        moistureStartPercent ?? this.moistureStartPercent,
    moistureStopPercent: moistureStopPercent ?? this.moistureStopPercent,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'cropId': cropId,
    'control': control.name,
    'valveChannel': valveChannel,
    'soilSensorId': soilSensorId,
    'soilCalibrated': soilCalibrated,
    'moistureStartPercent': moistureStartPercent,
    'moistureStopPercent': moistureStopPercent,
  };

  factory IrrigationZone.fromJson(Map<String, Object?> data) {
    final rawMode = data['control'] as String?;
    return IrrigationZone(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      cropId: data['cropId'] as String? ?? 'custom',
      control: ZoneControl.values.firstWhere(
        (value) => value.name == rawMode,
        orElse: () => ZoneControl.manual,
      ),
      valveChannel: (data['valveChannel'] as num?)?.toInt(),
      soilSensorId: data['soilSensorId'] as String?,
      soilCalibrated: data['soilCalibrated'] == true,
      moistureStartPercent: (data['moistureStartPercent'] as num?)?.toDouble(),
      moistureStopPercent: (data['moistureStopPercent'] as num?)?.toDouble(),
    );
  }
}

class IrrigationPlan {
  const IrrigationPlan({
    required this.delivery,
    required this.zones,
    this.pumpChannel,
    this.schemaVersion = 1,
  });

  factory IrrigationPlan.firstUse({String cropId = 'water_spinach'}) =>
      IrrigationPlan(
        delivery: WaterDelivery.pumpDirect,
        zones: <IrrigationZone>[
          IrrigationZone(
            id: 'zone-1',
            name: 'โซน 1',
            cropId: cropId,
          ),
        ],
      );

  final int schemaVersion;
  final WaterDelivery delivery;
  final int? pumpChannel;
  final List<IrrigationZone> zones;

  /// Layout is always a preview, even if every field looks complete.
  bool get canApplyToController => false;

  IrrigationPlan copyWith({
    WaterDelivery? delivery,
    int? pumpChannel,
    bool clearPumpChannel = false,
    List<IrrigationZone>? zones,
  }) => IrrigationPlan(
    delivery: delivery ?? this.delivery,
    pumpChannel: clearPumpChannel ? null : pumpChannel ?? this.pumpChannel,
    zones: zones ?? this.zones,
  );

  List<IrrigationIssue> validate({
    Set<int> existingDeviceChannels = const <int>{},
  }) {
    final issues = <IrrigationIssue>[];
    if (zones.isEmpty) issues.add(const IrrigationIssue('no_zones'));
    if (zones.length > (delivery == WaterDelivery.valveOnly ? 8 : 7)) {
      issues.add(const IrrigationIssue('too_many_zones'));
    }
    if (delivery == WaterDelivery.pumpDirect && zones.length > 1) {
      issues.add(const IrrigationIssue('direct_pump_one_zone_only'));
    }
    final needsPump = delivery != WaterDelivery.valveOnly;
    final needsValve = delivery != WaterDelivery.pumpDirect;
    final allocated = <int>{};

    void checkChannel(int? ch, String? zoneId) {
      if (ch == null) {
        issues.add(IrrigationIssue('channel_unassigned', zoneId: zoneId));
        return;
      }
      if (ch < 1 || ch > 8) {
        issues.add(IrrigationIssue('channel_out_of_range', zoneId: zoneId));
        return;
      }
      if (!allocated.add(ch)) {
        issues.add(IrrigationIssue('channel_duplicate', zoneId: zoneId));
      }
      if (existingDeviceChannels.contains(ch)) {
        issues.add(IrrigationIssue('channel_reserved', zoneId: zoneId));
      }
    }

    if (needsPump) checkChannel(pumpChannel, null);
    final ids = <String>{};
    for (final zone in zones) {
      if (zone.id.isEmpty || !ids.add(zone.id)) {
        issues.add(IrrigationIssue('zone_id_duplicate', zoneId: zone.id));
      }
      if (needsValve) checkChannel(zone.valveChannel, zone.id);
      if (zone.control == ZoneControl.schedule) {
        issues.add(IrrigationIssue('schedule_not_configured', zoneId: zone.id));
      }
      if (zone.control == ZoneControl.soilMoisture) {
        if (zone.soilSensorId == null || zone.soilSensorId!.isEmpty) {
          issues.add(IrrigationIssue('soil_sensor_unassigned', zoneId: zone.id));
        }
        if (!zone.soilCalibrated) {
          issues.add(IrrigationIssue('soil_calibration_required', zoneId: zone.id));
        }
        final start = zone.moistureStartPercent;
        final stop = zone.moistureStopPercent;
        if (start == null ||
            stop == null ||
            !start.isFinite ||
            !stop.isFinite ||
            start < 0 ||
            start >= stop ||
            stop > 100) {
          issues.add(IrrigationIssue('moisture_thresholds_invalid', zoneId: zone.id));
        }
      }
    }
    return issues;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'delivery': delivery.name,
    'pumpChannel': pumpChannel,
    'zones': zones.map((zone) => zone.toJson()).toList(),
  };

  factory IrrigationPlan.fromJson(Map<String, Object?> data) {
    final rawZones = data['zones'];
    if (rawZones is! List) throw const FormatException('zones not a list');
    final parsed = rawZones.map((entry) {
      if (entry is! Map) throw const FormatException('invalid zone');
      return IrrigationZone.fromJson(Map<String, Object?>.from(entry));
    }).toList(growable: false);
    if (parsed.isEmpty || parsed.length > 8) {
      throw const FormatException('invalid zone count');
    }
    final mode = data['delivery'] as String?;
    return IrrigationPlan(
      delivery: WaterDelivery.values.firstWhere(
        (value) => value.name == mode,
        orElse: () => WaterDelivery.pumpDirect,
      ),
      pumpChannel: (data['pumpChannel'] as num?)?.toInt(),
      zones: parsed,
    );
  }
}

/// A simulation only: no protocol commands, GPIO numbers or live actions.
class IrrigationPreview {
  const IrrigationPreview({
    required this.zoneId,
    required this.wouldRequestWater,
    required this.reason,
  });
  final String zoneId;
  final bool wouldRequestWater;
  final String reason;
}

class IrrigationPreviewEngine {
  const IrrigationPreviewEngine._();

  /// Deliberately does not activate anything. Missing/stale readings block
  /// the simulated decision; active watering is passed explicitly by tests.
  static IrrigationPreview assess({
    required IrrigationZone zone,
    required double? measuredMoisture,
    bool previouslyWatering = false,
    bool sensorFresh = false,
    bool emergencyStop = false,
  }) {
    if (emergencyStop) {
      return IrrigationPreview(
        zoneId: zone.id, wouldRequestWater: false, reason: 'emergency_stop');
    }
    if (zone.control != ZoneControl.soilMoisture) {
      return IrrigationPreview(
        zoneId: zone.id, wouldRequestWater: false, reason: 'not_sensor_mode');
    }
    if (zone.soilSensorId == null ||
        zone.soilSensorId!.isEmpty ||
        !zone.soilCalibrated ||
        !sensorFresh ||
        measuredMoisture == null ||
        !measuredMoisture.isFinite ||
        measuredMoisture < 0 ||
        measuredMoisture > 100) {
      return IrrigationPreview(
        zoneId: zone.id, wouldRequestWater: false, reason: 'sensor_not_ready');
    }
    final start = zone.moistureStartPercent;
    final stop = zone.moistureStopPercent;
    if (start == null ||
        stop == null ||
        !start.isFinite ||
        !stop.isFinite ||
        start < 0 ||
        start >= stop ||
        stop > 100) {
      return IrrigationPreview(
        zoneId: zone.id, wouldRequestWater: false, reason: 'thresholds_not_ready');
    }
    final wantWater = previouslyWatering
        ? measuredMoisture < stop
        : measuredMoisture <= start;
    return IrrigationPreview(
      zoneId: zone.id,
      wouldRequestWater: wantWater,
      reason: wantWater ? 'below_target' : 'enough_moisture',
    );
  }
}
