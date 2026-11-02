import '../controllers/smart_farm_controller.dart';
import '../stores/device_store.dart';
import '../stores/sensor_store.dart';
import 'farm_event.dart';
import 'controller_identity.dart';
import 'accessory_manifest.dart';
import 'sensor_model.dart';
import 'sensor_reading.dart';

enum DashboardPhase { disconnected, connecting, live, emergency, degraded }

class FarmState {
  const FarmState({
    required this.connected,
    required this.requestInProgress,
    required this.emergencyActive,
    required this.activeDevices,
    required this.totalDevices,
    required this.enabledSensors,
    required this.totalSensors,
    required this.relayCount,
    required this.consecutiveFailures,
    required this.lastUpdated,
    required this.responseMs,
    required this.controllerStatus,
    required this.commandError,
    required this.firmwareVersion,
    required this.connectionMode,
    required this.protocolVersion,
    required this.apiVersion,
    required this.uptimeMs,
    required this.sensorReadings,
    required this.events,
    required this.accessories,
    this.identity = ControllerIdentity.empty,
    this.wifiRssi,
    this.freeHeap,
  });

  static const FarmState empty = FarmState(
    connected: false,
    requestInProgress: false,
    emergencyActive: false,
    activeDevices: 0,
    totalDevices: 0,
    enabledSensors: 0,
    totalSensors: 0,
    relayCount: 0,
    consecutiveFailures: 0,
    lastUpdated: null,
    responseMs: null,
    controllerStatus: 'disconnected',
    commandError: null,
    firmwareVersion: null,
    connectionMode: null,
    protocolVersion: null,
    apiVersion: null,
    uptimeMs: null,
    sensorReadings: <SensorReading>[],
    events: <FarmEvent>[],
    accessories: <AccessoryManifest>[],
    identity: ControllerIdentity.empty,
    wifiRssi: null,
    freeHeap: null,
  );

  factory FarmState.fromSources({
    required SmartFarmController controller,
    required DeviceStore deviceStore,
    required SensorStore sensorStore,
  }) {
    final readings = <SensorReading>[
      if (controller.temperature != null)
        SensorReading(
          id: 'temperature',
          type: SensorType.temperature,
          name: 'Temperature',
          unit: '°C',
          value: controller.temperature,
          state: controller.connected
              ? SensorLiveState.live
              : SensorLiveState.stale,
          updatedAt: controller.lastUpdated,
        ),
      if (controller.humidity != null)
        SensorReading(
          id: 'humidity',
          type: SensorType.humidity,
          name: 'Humidity',
          unit: '%',
          value: controller.humidity,
          state: controller.connected
              ? SensorLiveState.live
              : SensorLiveState.stale,
          updatedAt: controller.lastUpdated,
        ),
      if (controller.soilMoisture != null)
        SensorReading(
          id: 'soilMoisture',
          type: SensorType.soilMoisture,
          name: 'Soil moisture',
          unit: '%',
          value: controller.soilMoisture,
          state: controller.connected
              ? SensorLiveState.live
              : SensorLiveState.stale,
          updatedAt: controller.lastUpdated,
        ),
    ];

    final controllerEvents = controller.logEntries
        .take(20)
        .map((entry) {
          return FarmEvent(
            id: entry.id,
            message: entry.message,
            timestamp: entry.timestamp,
            severity: _severityForMessage(entry.message),
          );
        })
        .toList(growable: false);

    // Compatibility fallback for older code that writes directly to `logs`.
    final events = controllerEvents.isNotEmpty
        ? controllerEvents
        : controller.logs
              .take(20)
              .toList()
              .asMap()
              .entries
              .map((entry) {
                final message = entry.value;
                return FarmEvent(
                  id: 'legacy-${entry.key}-${message.hashCode}',
                  message: message,
                  timestamp:
                      controller.lastUpdated ??
                      DateTime.fromMillisecondsSinceEpoch(0),
                  severity: _severityForMessage(message),
                );
              })
              .toList(growable: false);

    return FarmState(
      connected: controller.connected,
      requestInProgress: controller.requestInProgress,
      emergencyActive: controller.emergencyLatched,
      activeDevices: deviceStore.activeOutputCount,
      totalDevices: deviceStore.outputs.length,
      enabledSensors: sensorStore.configs
          .where((sensor) => sensor.enabled)
          .length,
      totalSensors: sensorStore.configs.length,
      relayCount:
          controller.relayCount ?? SmartFarmController.hardwareRelayCount,
      consecutiveFailures: controller.consecutiveFailures,
      lastUpdated: controller.lastUpdated,
      responseMs: controller.lastResponseMs,
      controllerStatus: controller.status,
      commandError: deviceStore.lastCommandError,
      firmwareVersion: controller.firmwareVersion,
      connectionMode: controller.connectionMode,
      protocolVersion: controller.protocolVersion,
      apiVersion: controller.apiVersion,
      uptimeMs: controller.uptimeMs,
      sensorReadings: readings,
      events: events,
      accessories: controller.accessories,
      identity: controller.identity,
      wifiRssi: controller.wifiRssi,
      freeHeap: controller.freeHeap,
    );
  }

  final bool connected;
  final bool requestInProgress;
  final bool emergencyActive;
  final int activeDevices;
  final int totalDevices;
  final int enabledSensors;
  final int totalSensors;
  final int relayCount;
  final int consecutiveFailures;
  final DateTime? lastUpdated;
  final int? responseMs;
  final String controllerStatus;
  final String? commandError;
  final String? firmwareVersion;
  final String? connectionMode;
  final int? protocolVersion;
  final int? apiVersion;
  final int? uptimeMs;
  final List<SensorReading> sensorReadings;
  final List<FarmEvent> events;
  final List<AccessoryManifest> accessories;
  final ControllerIdentity identity;
  final int? wifiRssi;
  final int? freeHeap;

  DashboardPhase get phase {
    if (emergencyActive) {
      return DashboardPhase.emergency;
    }
    if (requestInProgress && !connected) {
      return DashboardPhase.connecting;
    }
    if (!connected) {
      return DashboardPhase.disconnected;
    }
    if (consecutiveFailures > 0 || commandError != null) {
      return DashboardPhase.degraded;
    }
    return DashboardPhase.live;
  }

  SensorReading? readingForType(SensorType type) {
    for (final reading in sensorReadings) {
      if (reading.type == type) {
        return reading;
      }
    }
    return null;
  }

  double? get temperature => readingForType(SensorType.temperature)?.value;
  double? get humidity => readingForType(SensorType.humidity)?.value;
  double? get soilMoisture => readingForType(SensorType.soilMoisture)?.value;

  static FarmEventSeverity _severityForMessage(String message) {
    if (message.contains('emergency-stop')) {
      return FarmEventSeverity.critical;
    }
    if (message.contains('ERROR')) {
      return FarmEventSeverity.warning;
    }
    return FarmEventSeverity.info;
  }

  FarmState copyWith({
    bool? connected,
    bool? requestInProgress,
    bool? emergencyActive,
    int? activeDevices,
    int? totalDevices,
    int? enabledSensors,
    int? totalSensors,
    int? relayCount,
    int? consecutiveFailures,
    DateTime? lastUpdated,
    int? responseMs,
    String? controllerStatus,
    String? commandError,
    String? firmwareVersion,
    String? connectionMode,
    int? protocolVersion,
    int? apiVersion,
    int? uptimeMs,
    List<SensorReading>? sensorReadings,
    List<FarmEvent>? events,
    List<AccessoryManifest>? accessories,
    ControllerIdentity? identity,
    double? temperature,
    double? humidity,
    double? soilMoisture,
    int? wifiRssi,
    int? freeHeap,
    bool clearLastUpdated = false,
    bool clearResponseMs = false,
    bool clearCommandError = false,
    bool clearFirmwareVersion = false,
    bool clearConnectionMode = false,
    bool clearProtocolVersion = false,
    bool clearApiVersion = false,
    bool clearUptimeMs = false,
    bool clearWifiRssi = false,
    bool clearFreeHeap = false,
  }) {
    var nextReadings = sensorReadings ?? this.sensorReadings;
    if (temperature != null || humidity != null || soilMoisture != null) {
      final updated = <SensorReading>[
        ...nextReadings.where(
          (reading) =>
              reading.type != SensorType.temperature &&
              reading.type != SensorType.humidity &&
              reading.type != SensorType.soilMoisture,
        ),
        if (temperature != null)
          SensorReading(
            id: 'temperature',
            type: SensorType.temperature,
            name: 'Temperature',
            unit: '°C',
            value: temperature,
            state: SensorLiveState.live,
            updatedAt: lastUpdated ?? DateTime.now(),
          ),
        if (humidity != null)
          SensorReading(
            id: 'humidity',
            type: SensorType.humidity,
            name: 'Humidity',
            unit: '%',
            value: humidity,
            state: SensorLiveState.live,
            updatedAt: lastUpdated ?? DateTime.now(),
          ),
        if (soilMoisture != null)
          SensorReading(
            id: 'soilMoisture',
            type: SensorType.soilMoisture,
            name: 'Soil moisture',
            unit: '%',
            value: soilMoisture,
            state: SensorLiveState.live,
            updatedAt: lastUpdated ?? DateTime.now(),
          ),
      ];
      nextReadings = updated;
    }

    return FarmState(
      connected: connected ?? this.connected,
      requestInProgress: requestInProgress ?? this.requestInProgress,
      emergencyActive: emergencyActive ?? this.emergencyActive,
      activeDevices: activeDevices ?? this.activeDevices,
      totalDevices: totalDevices ?? this.totalDevices,
      enabledSensors: enabledSensors ?? this.enabledSensors,
      totalSensors: totalSensors ?? this.totalSensors,
      relayCount: relayCount ?? this.relayCount,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
      responseMs: clearResponseMs ? null : responseMs ?? this.responseMs,
      controllerStatus: controllerStatus ?? this.controllerStatus,
      commandError: clearCommandError
          ? null
          : commandError ?? this.commandError,
      firmwareVersion: clearFirmwareVersion
          ? null
          : firmwareVersion ?? this.firmwareVersion,
      connectionMode: clearConnectionMode
          ? null
          : connectionMode ?? this.connectionMode,
      protocolVersion: clearProtocolVersion
          ? null
          : protocolVersion ?? this.protocolVersion,
      apiVersion: clearApiVersion ? null : apiVersion ?? this.apiVersion,
      uptimeMs: clearUptimeMs ? null : uptimeMs ?? this.uptimeMs,
      sensorReadings: List<SensorReading>.unmodifiable(nextReadings),
      events: List<FarmEvent>.unmodifiable(events ?? this.events),
      accessories: List<AccessoryManifest>.unmodifiable(
        accessories ?? this.accessories,
      ),
      identity: identity ?? this.identity,
      wifiRssi: clearWifiRssi ? null : wifiRssi ?? this.wifiRssi,
      freeHeap: clearFreeHeap ? null : freeHeap ?? this.freeHeap,
    );
  }
}
