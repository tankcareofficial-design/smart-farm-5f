/// Versioned, offline-first crop guidance. No relay or controller writes are
/// performed from this model. Numeric targets require measured calibration.
enum CropGroup { leafy, herb, fruiting, custom }

class CropControlTargets {
  const CropControlTargets({
    this.temperatureMinC,
    this.temperatureMaxC,
    this.humidityMinPercent,
    this.humidityMaxPercent,
    this.calibratedSoilStartPercent,
    this.calibratedSoilStopPercent,
    this.maxPumpRuntimeSeconds,
    this.cooldownSeconds,
  });

  final double? temperatureMinC;
  final double? temperatureMaxC;
  final double? humidityMinPercent;
  final double? humidityMaxPercent;

  /// May be filled only after calibrating the installed soil sensor and media.
  final double? calibratedSoilStartPercent;
  final double? calibratedSoilStopPercent;

  /// Hardware-dependent limits, not agronomic Internet defaults.
  final int? maxPumpRuntimeSeconds;
  final int? cooldownSeconds;

  bool get isUnconfigured =>
      temperatureMinC == null &&
      temperatureMaxC == null &&
      humidityMinPercent == null &&
      humidityMaxPercent == null &&
      calibratedSoilStartPercent == null &&
      calibratedSoilStopPercent == null &&
      maxPumpRuntimeSeconds == null &&
      cooldownSeconds == null;
}

/// Evidence-based cultivation reference, NOT a device-control threshold.
/// Values represent air conditions for the source's stated setting/stage.
class CropClimateReference {
  const CropClimateReference({
    this.temperatureMinC,
    this.temperatureMaxC,
    this.sourceTitleTh = '',
    this.sourceTitleEn = '',
    this.sourceUrl = '',
    this.contextTh = '',
    this.contextEn = '',
  });

  final double? temperatureMinC;
  final double? temperatureMaxC;
  final String sourceTitleTh;
  final String sourceTitleEn;
  final String sourceUrl;
  final String contextTh;
  final String contextEn;

  bool get hasTemperatureRange =>
      temperatureMinC != null && temperatureMaxC != null;
  String sourceTitle({required bool isThai}) =>
      isThai ? sourceTitleTh : sourceTitleEn;
  String context({required bool isThai}) =>
      isThai ? contextTh : contextEn;
}

class CropProfile {
  const CropProfile({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.group,
    required this.waterNoteTh,
    required this.waterNoteEn,
    required this.lightNoteTh,
    required this.lightNoteEn,
    this.schemaVersion = 1,
    this.targets = const CropControlTargets(),
    this.referenceClimate = const CropClimateReference(),
    this.sourceReferences = const <String>[],
  });

  final int schemaVersion;
  final String id;
  final String nameTh;
  final String nameEn;
  final CropGroup group;
  final String waterNoteTh;
  final String waterNoteEn;
  final String lightNoteTh;
  final String lightNoteEn;
  final CropControlTargets targets;

  /// Source-backed starting values for an editable phone-only guide.
  /// Never copy these to an actuator without a separate validated workflow.
  final CropClimateReference referenceClimate;

  /// Empty until actual agricultural references have been reviewed.
  final List<String> sourceReferences;

  String name({required bool isThai}) => isThai ? nameTh : nameEn;
  String waterNote({required bool isThai}) =>
      isThai ? waterNoteTh : waterNoteEn;
  String lightNote({required bool isThai}) =>
      isThai ? lightNoteTh : lightNoteEn;

  /// Applying requires separate agronomic review, local sensor calibration,
  /// hardware safety limits, and a tested ESP32 command path. Never infer that
  /// a preview or a future non-null threshold authorizes an automatic relay.
  bool get canApplyToController => false;
}
