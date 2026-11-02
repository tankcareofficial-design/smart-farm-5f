import '../models/farm_state.dart';
import '../models/sensor_reading.dart';

enum FarmHealthLevel { excellent, normal, warning, critical }

enum FarmReadinessState {
  ready,
  partial,
  waitingForData,
  disconnected,
  emergency,
  needsAttention,
}

class FarmHealthFactor {
  const FarmHealthFactor({
    required this.label,
    required this.status,
    required this.weight,
    required this.score,
  });

  final String label;
  final bool? status;
  final int weight;
  final int score;
}

class FarmHealthResult {
  const FarmHealthResult({
    required this.score,
    required this.level,
    required this.readiness,
    required this.confidence,
    required this.factors,
    required this.alerts,
    this.isAssessable = true,
  });

  final int score;
  final FarmHealthLevel level;
  final FarmReadinessState readiness;
  final double confidence;
  final List<FarmHealthFactor> factors;
  final List<String> alerts;
  final bool isAssessable;
}

/// R8.4 evaluates system readiness from evidence only.
/// Missing optional accessories do not reduce the score. Installed accessories
/// without usable data do reduce readiness. Crop health is intentionally out of
/// scope until crop-specific thresholds are configured.
class FarmHealthEngine {
  const FarmHealthEngine();

  FarmHealthResult evaluate(FarmState state) {
    final readings = state.sensorReadings;
    final liveReadings = readings.where(_isUsable).toList(growable: false);
    final staleReadings = readings
        .where((r) => r.state == SensorLiveState.stale)
        .length;
    final failedReadings = readings
        .where(
          (r) =>
              r.state == SensorLiveState.error ||
              r.state == SensorLiveState.unavailable,
        )
        .length;

    final installedAccessories = state.accessories
        .where((item) => item.installed)
        .toList(growable: false);
    final connectedAccessories = installedAccessories
        .where((item) => item.connected)
        .length;
    final accessoryCoverage = installedAccessories.isEmpty
        ? null
        : connectedAccessories / installedAccessories.length;

    final factors = <FarmHealthFactor>[];
    final alerts = <String>[];

    _addFactor(
      factors,
      label: 'การเชื่อมต่อกล่องควบคุม',
      weight: 30,
      value: state.connected ? 1 : 0,
      assessable: true,
    );

    final dataExpected =
        state.enabledSensors > 0 || installedAccessories.isNotEmpty;
    final sensorCoverage = state.enabledSensors > 0
        ? (liveReadings.length / state.enabledSensors).clamp(0.0, 1.0)
        : accessoryCoverage;
    _addFactor(
      factors,
      label: 'ข้อมูลจากเซ็นเซอร์จริง',
      weight: 30,
      value: sensorCoverage ?? 0,
      assessable: dataExpected,
    );

    final qualityAssessable = readings.isNotEmpty;
    final qualityPenalty = readings.isEmpty
        ? 0.0
        : ((staleReadings * 0.45 + failedReadings * 0.75) / readings.length)
              .clamp(0.0, 1.0);
    _addFactor(
      factors,
      label: 'ความสดและความถูกต้องของข้อมูล',
      weight: 15,
      value: 1 - qualityPenalty,
      assessable: qualityAssessable,
    );

    final communicationValue = state.consecutiveFailures == 0
        ? 1.0
        : (1 - state.consecutiveFailures / 5).clamp(0.0, 1.0);
    _addFactor(
      factors,
      label: 'ความเสถียรในการรับส่งข้อมูล',
      weight: 10,
      value: communicationValue,
      assessable: state.connected || state.consecutiveFailures > 0,
    );

    _addFactor(
      factors,
      label: 'ระบบควบคุม 8 ช่อง',
      weight: 10,
      value: state.relayCount == 8 && state.commandError == null ? 1 : 0,
      assessable: state.connected,
    );

    _addFactor(
      factors,
      label: 'ระบบความปลอดภัย',
      weight: 5,
      value: state.emergencyActive ? 0 : 1,
      assessable: state.connected,
    );

    if (!state.connected) {
      alerts.add('กล่องควบคุมไม่ได้เชื่อมต่อ');
    }
    if (dataExpected && liveReadings.isEmpty) {
      alerts.add('กำลังรอข้อมูลจากเซ็นเซอร์จริง');
    }
    if (staleReadings > 0) {
      alerts.add('มีข้อมูลที่ไม่ได้อัปเดต $staleReadings รายการ');
    }
    if (failedReadings > 0) {
      alerts.add('มีเซ็นเซอร์ที่ต้องตรวจสอบ $failedReadings รายการ');
    }
    if (state.relayCount != 8) {
      alerts.add('จำนวนช่องควบคุมไม่ตรงกับรุ่น 8 ช่อง');
    }
    if (state.emergencyActive) {
      alerts.add('ระบบหยุดฉุกเฉินกำลังทำงาน');
    }
    if (state.commandError != null) {
      alerts.add(state.commandError!);
    }

    final assessableFactors = factors
        .where((factor) => factor.status != null)
        .toList(growable: false);
    final assessedWeight = assessableFactors.fold<int>(
      0,
      (sum, factor) => sum + factor.weight,
    );
    final weightedScore = assessableFactors.fold<int>(
      0,
      (sum, factor) => sum + factor.score,
    );
    final score = assessedWeight == 0
        ? 0
        : ((weightedScore / assessedWeight) * 100)
              .round()
              .clamp(0, 100)
              .toInt();
    final confidence = factors.isEmpty
        ? 0.0
        : (assessedWeight /
                  factors.fold<int>(0, (sum, factor) => sum + factor.weight))
              .clamp(0.0, 1.0)
              .toDouble();

    final hasRealEvidence = liveReadings.isNotEmpty || connectedAccessories > 0;
    final isAssessable = state.connected && hasRealEvidence;
    final readiness = _readinessFor(
      state,
      score,
      dataExpected,
      hasRealEvidence,
    );
    final level = score >= 90
        ? FarmHealthLevel.excellent
        : score >= 70
        ? FarmHealthLevel.normal
        : score >= 45
        ? FarmHealthLevel.warning
        : FarmHealthLevel.critical;

    return FarmHealthResult(
      score: isAssessable ? score : 0,
      level: level,
      readiness: readiness,
      confidence: confidence,
      isAssessable: isAssessable,
      factors: List<FarmHealthFactor>.unmodifiable(factors),
      alerts: List<String>.unmodifiable(alerts),
    );
  }

  static bool _isUsable(SensorReading reading) {
    return reading.value != null &&
        reading.state == SensorLiveState.live &&
        reading.isFresh;
  }

  static void _addFactor(
    List<FarmHealthFactor> factors, {
    required String label,
    required int weight,
    required num value,
    required bool assessable,
  }) {
    final normalized = value.toDouble().clamp(0.0, 1.0);
    factors.add(
      FarmHealthFactor(
        label: label,
        status: assessable ? normalized >= 0.75 : null,
        weight: weight,
        score: assessable ? (weight * normalized).round() : 0,
      ),
    );
  }

  static FarmReadinessState _readinessFor(
    FarmState state,
    int score,
    bool dataExpected,
    bool hasRealEvidence,
  ) {
    if (state.emergencyActive) {
      return FarmReadinessState.emergency;
    }
    if (!state.connected) {
      return FarmReadinessState.disconnected;
    }
    if (dataExpected && !hasRealEvidence) {
      return FarmReadinessState.waitingForData;
    }
    if (state.commandError != null || score < 45) {
      return FarmReadinessState.needsAttention;
    }
    if (score < 80) {
      return FarmReadinessState.partial;
    }
    return FarmReadinessState.ready;
  }
}
