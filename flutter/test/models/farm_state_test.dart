import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/models/farm_event.dart';
import 'package:smart_farm/models/farm_state.dart';
import 'package:smart_farm/models/sensor_model.dart';
import 'package:smart_farm/models/sensor_reading.dart';

void main() {
  group('FarmState compatibility contract', () {
    test('empty keeps legacy getters available', () {
      expect(FarmState.empty.temperature, isNull);
      expect(FarmState.empty.humidity, isNull);
      expect(FarmState.empty.soilMoisture, isNull);
      expect(FarmState.empty.phase, DashboardPhase.disconnected);
    });

    test('copyWith legacy sensor arguments update generic readings', () {
      final updated = FarmState.empty.copyWith(
        temperature: 28.5,
        humidity: 62,
        soilMoisture: 41,
      );

      expect(updated.temperature, 28.5);
      expect(updated.humidity, 62);
      expect(updated.soilMoisture, 41);
      expect(updated.sensorReadings, hasLength(3));
    });

    test('copyWith can explicitly clear nullable diagnostics', () {
      final populated = FarmState.empty.copyWith(
        lastUpdated: DateTime(2026),
        responseMs: 80,
        commandError: 'failed',
        firmwareVersion: 'test',
        connectionMode: 'ap',
        protocolVersion: 1,
        apiVersion: 2,
        uptimeMs: 1000,
        wifiRssi: -55,
        freeHeap: 120000,
      );

      final cleared = populated.copyWith(
        clearLastUpdated: true,
        clearResponseMs: true,
        clearCommandError: true,
        clearFirmwareVersion: true,
        clearConnectionMode: true,
        clearProtocolVersion: true,
        clearApiVersion: true,
        clearUptimeMs: true,
        clearWifiRssi: true,
        clearFreeHeap: true,
      );

      expect(cleared.lastUpdated, isNull);
      expect(cleared.responseMs, isNull);
      expect(cleared.commandError, isNull);
      expect(cleared.firmwareVersion, isNull);
      expect(cleared.connectionMode, isNull);
      expect(cleared.protocolVersion, isNull);
      expect(cleared.apiVersion, isNull);
      expect(cleared.uptimeMs, isNull);
      expect(cleared.wifiRssi, isNull);
      expect(cleared.freeHeap, isNull);
    });

    test('generic reading lookup remains type based', () {
      final reading = SensorReading(
        id: 'temp-1',
        type: SensorType.temperature,
        name: 'Temperature',
        unit: '°C',
        value: 30,
        state: SensorLiveState.live,
        updatedAt: DateTime(2026),
      );
      final state = FarmState.empty.copyWith(sensorReadings: [reading]);
      expect(state.readingForType(SensorType.temperature), same(reading));
      expect(state.temperature, 30);
    });

    test('event list is immutable after copyWith', () {
      final event = FarmEvent(
        id: 'event-1',
        message: 'CONNECTED',
        timestamp: DateTime(2026),
        severity: FarmEventSeverity.info,
      );
      final state = FarmState.empty.copyWith(events: [event]);
      expect(() => state.events.add(event), throwsUnsupportedError);
    });
  });
}
