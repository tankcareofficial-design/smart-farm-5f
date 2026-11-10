import 'crop_profile.dart';

/// User changes to an individual crop preset. This is a local preview only;
/// never use it as a command to a relay or ESP32.
class CropProfileDraft {
  const CropProfileDraft({
    required this.cropId,
    this.temperatureMinC,
    this.temperatureMaxC,
    this.humidityMinPercent,
    this.humidityMaxPercent,
    this.note = '',
  });

  final String cropId;
  final double? temperatureMinC;
  final double? temperatureMaxC;
  final double? humidityMinPercent;
  final double? humidityMaxPercent;
  final String note;

  bool isCustomized(CropProfile source) {
    if (source.id != cropId) {
      throw ArgumentError.value(cropId, 'cropId', 'Mismatched crop preset');
    }
    final baseline = source.targets;
    return temperatureMinC != baseline.temperatureMinC ||
        temperatureMaxC != baseline.temperatureMaxC ||
        humidityMinPercent != baseline.humidityMinPercent ||
        humidityMaxPercent != baseline.humidityMaxPercent ||
        note.trim().isNotEmpty;
  }

  String displayName(CropProfile source, {required bool isThai}) {
    final name = source.name(isThai: isThai);
    if (!isCustomized(source)) return name;
    return isThai ? '$name (มีการปรับแต่ง)' : '$name (Customized)';
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'cropId': cropId,
    'temperatureMinC': temperatureMinC,
    'temperatureMaxC': temperatureMaxC,
    'humidityMinPercent': humidityMinPercent,
    'humidityMaxPercent': humidityMaxPercent,
    'note': note,
  };

  factory CropProfileDraft.fromJson(Map<String, Object?> data) {
    return CropProfileDraft(
      cropId: data['cropId']?.toString() ?? '',
      temperatureMinC: (data['temperatureMinC'] as num?)?.toDouble(),
      temperatureMaxC: (data['temperatureMaxC'] as num?)?.toDouble(),
      humidityMinPercent: (data['humidityMinPercent'] as num?)?.toDouble(),
      humidityMaxPercent: (data['humidityMaxPercent'] as num?)?.toDouble(),
      note: data['note']?.toString() ?? '',
    );
  }
}
