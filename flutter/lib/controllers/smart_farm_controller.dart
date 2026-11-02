import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/esp32_http_service.dart';
import '../models/accessory_manifest.dart';
import '../models/controller_identity.dart';
import '../models/automation_rule.dart';
import '../models/system_clock_state.dart';
import '../models/device_runtime_state.dart';
import '../models/controller_snapshot.dart';
import '../services/snapshot_cache_service.dart';

class RelayViewState {
  const RelayViewState({
    required this.channel,
    required this.name,
    required this.on,
    this.overrideActive = false,
  });

  final int channel;
  final String name;
  final bool on;
  final bool overrideActive;

  RelayViewState copyWith({String? name, bool? on, bool? overrideActive}) {
    return RelayViewState(
      channel: channel,
      name: name ?? this.name,
      on: on ?? this.on,
      overrideActive: overrideActive ?? this.overrideActive,
    );
  }
}

class ControllerLogEntry {
  const ControllerLogEntry({
    required this.id,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String message;
  final DateTime timestamp;
}

class SmartFarmController extends ChangeNotifier {
  static const int hardwareRelayCount = 8;
  SmartFarmController({
    Esp32HttpService? httpService,
    this.pollInterval = const Duration(seconds: 2),
    this.languageCode = 'th',
    String initialBaseUrl = 'http://192.168.4.1',
  }) : _http = httpService ?? Esp32HttpService() {
    _http.baseUrl = initialBaseUrl;
    status = _text(
      'ยังไม่ได้เชื่อมต่อกล่องควบคุม',
      'Control box is not connected',
    );
    _resizeRelays(hardwareRelayCount);
    relayCount = hardwareRelayCount;
  }

  final Esp32HttpService _http;
  final SnapshotCacheService _snapshotCache = SnapshotCacheService();
  final Duration pollInterval;
  final String languageCode;

  Timer? _pollTimer;
  bool _requestInProgress = false;
  bool _disposed = false;
  bool _pollingEnabled = false;
  int _connectionGeneration = 0;
  bool _clockRecoveryAttempted = false;

  bool connected = false;
  String status = '';
  String? deviceId;
  String? firmwareVersion;
  int? protocolVersion;
  int? apiVersion;
  String? connectionMode;
  String? accessPointSsid;
  String? accessPointIp;
  int? relayCount;
  int? uptimeMs;
  int? wifiClientCount;
  int? wifiRssi;
  int? freeHeap;
  int? lastResponseMs;
  int consecutiveFailures = 0;
  bool emergencyLatched = false;
  DateTime? lastUpdated;

  double? soilMoisture;
  double? temperature;
  double? humidity;

  List<AccessoryManifest> accessories = const <AccessoryManifest>[];
  ControllerIdentity identity = ControllerIdentity.empty;
  String hardwareProfile = 'plug_and_play_v1';
  int accessorySchemaVersion = 1;
  SystemClockState clock = const SystemClockState(
    available: false,
    valid: false,
    source: 'none',
  );
  DateTime? _controllerClockBaseline;
  DateTime? _controllerClockReceivedAt;
  List<AutomationRule> automationRules = const <AutomationRule>[];
  List<DeviceRuntimeState> deviceRuntime = const <DeviceRuntimeState>[];
  int snapshotRevision = 0;

  final List<RelayViewState> relays = <RelayViewState>[];
  final List<String> logs = <String>[];
  final List<ControllerLogEntry> _logEntries = <ControllerLogEntry>[];
  int _nextLogSequence = 0;

  List<ControllerLogEntry> get logEntries =>
      List<ControllerLogEntry>.unmodifiable(_logEntries);

  String get baseUrl => _http.baseUrl;
  bool get requestInProgress => _requestInProgress;
  bool get autoReconnectEnabled => _pollingEnabled;
  bool get hasDeviceData => deviceId != null || firmwareVersion != null;

  /// Global controller time shared by every screen.
  ///
  /// The date/time may still be displayed when DS3231 reports lostPower, but
  /// [clock.valid] remains false so schedule automation stays safely blocked.
  DateTime? get estimatedControllerDateTime {
    final baseline = _controllerClockBaseline;
    final receivedAt = _controllerClockReceivedAt;
    if (baseline == null || receivedAt == null) return null;
    return baseline.add(DateTime.now().difference(receivedAt));
  }

  void _applyClockPayload(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data['clock'] as Map? ?? data);
    final nextClock = SystemClockState.fromJson(payload);
    final previousClock = clock;
    clock = nextClock;
    final receivedDateTime = nextClock.dateTimeLocal;
    if (receivedDateTime != null) {
      final now = DateTime.now();
      final currentEstimate = estimatedControllerDateTime;
      final driftSeconds = currentEstimate == null
          ? null
          : receivedDateTime.difference(currentEstimate).inMilliseconds.abs() /
                1000.0;
      final clockStateChanged =
          previousClock.valid != nextClock.valid ||
          previousClock.available != nextClock.available ||
          previousClock.source != nextClock.source;
      if (currentEstimate == null ||
          clockStateChanged ||
          driftSeconds == null ||
          driftSeconds >= 2.0) {
        _controllerClockBaseline = receivedDateTime;
        _controllerClockReceivedAt = now;
      }
    } else if (!nextClock.available) {
      _controllerClockBaseline = null;
      _controllerClockReceivedAt = null;
    }
  }

  void setBaseUrl(String value) {
    if (connected || _requestInProgress) {
      return;
    }

    _connectionGeneration++;
    _http.baseUrl = value;
    status = _text(
      'พร้อมเชื่อมต่อ ${_http.baseUrl}',
      'Ready to connect to ${_http.baseUrl}',
    );
    _notify();
  }

  void resetBaseUrl() {
    setBaseUrl('http://192.168.4.1');
  }

  Future<void> connect() async {
    final cached = await _snapshotCache.load();
    if (cached != null && automationRules.isEmpty) {
      automationRules = cached.rules;
      deviceRuntime = cached.runtime;
      snapshotRevision = cached.revision;
      _notify();
    }
    if (_requestInProgress) {
      return;
    }

    final int generation = ++_connectionGeneration;
    _clockRecoveryAttempted = false;
    _pollTimer?.cancel();
    _pollingEnabled = true;
    _requestInProgress = true;
    status = _text(
      'กำลังตรวจสอบกล่องควบคุมที่ ${_http.baseUrl}...',
      'Checking control box at ${_http.baseUrl}...',
    );
    _addLog('CONNECT ${_http.baseUrl}');
    _notify();

    final stopwatch = Stopwatch()..start();
    try {
      final device = await _http.getDevice();
      if (!_isCurrent(generation)) return;
      _applyDevice(device);

      // /api/device is the reachability contract. Secondary endpoints are
      // loaded independently so one slow clock/snapshot response does not turn
      // a reachable controller into "not found".
      try {
        final state = await _http.getState();
        if (!_isCurrent(generation)) return;
        _applyState(state);
      } catch (error) {
        _addLog('CONNECT STATE DEGRADED $error');
      }

      try {
        var clockData = await _http.getClock();
        if (!_isCurrent(generation)) return;
        _applyClockPayload(clockData);
        if (clock.available && !clock.valid) {
          _clockRecoveryAttempted = true;
          _addLog('RTC invalid (${clock.quality}); syncing from phone');
          await _http.syncClock();
          if (!_isCurrent(generation)) return;
          clockData = await _http.getClock();
          if (!_isCurrent(generation)) return;
          _applyClockPayload(clockData);
        }
      } catch (error) {
        _addLog('CONNECT CLOCK DEGRADED $error');
      }

      try {
        final snapshotData = await _http.getSnapshot();
        if (!_isCurrent(generation)) return;
        final snapshot = ControllerSnapshot.fromJson(snapshotData);
        automationRules = snapshot.rules;
        deviceRuntime = snapshot.runtime;
        snapshotRevision = snapshot.revision;
        await _snapshotCache.save(snapshotData);
      } catch (error) {
        _addLog('CONNECT SNAPSHOT DEGRADED $error');
      }

      stopwatch.stop();
      lastResponseMs = stopwatch.elapsedMilliseconds;
      connected = true;
      consecutiveFailures = 0;
      lastUpdated = DateTime.now();
      status = _text(
        'เชื่อมต่อกล่องควบคุมสำเร็จ',
        'Control box connected successfully',
      );
      _addLog(
        'CONNECTED deviceId=${deviceId ?? "-"} '
        'ssid=${accessPointSsid ?? "-"} ${lastResponseMs}ms',
      );
      _startPolling();
    } catch (error) {
      if (!_isCurrent(generation)) return;
      connected = false;
      consecutiveFailures++;
      status = _text('เชื่อมต่อไม่สำเร็จ: $error', 'Connection failed: $error');
      _addLog('CONNECT ERROR $error');
      _startPolling();
    } finally {
      if (_isCurrent(generation)) {
        _requestInProgress = false;
        _notify();
      }
    }
  }

  void disconnect() {
    _connectionGeneration++;
    _pollingEnabled = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _requestInProgress = false;
    connected = false;
    consecutiveFailures = 0;
    lastResponseMs = null;
    status = _text('ตัดการเชื่อมต่อแล้ว', 'Disconnected');
    _addLog('DISCONNECTED');
    _notify();
  }

  Future<void> refreshState() async {
    if (_requestInProgress || !_pollingEnabled) {
      return;
    }

    final int generation = _connectionGeneration;
    _requestInProgress = true;
    final stopwatch = Stopwatch()..start();

    try {
      if (!connected || !hasDeviceData) {
        final device = await _http.getDevice();
        if (!_isCurrent(generation)) return;
        _applyDevice(device);
      }

      final state = await _http.getState();
      if (!_isCurrent(generation)) return;
      _applyState(state);

      var clockData = await _http.getClock();
      if (!_isCurrent(generation)) return;
      _applyClockPayload(clockData);
      if (clock.available && !clock.valid && !_clockRecoveryAttempted) {
        _clockRecoveryAttempted = true;
        _addLog('RTC recovery: syncing from phone');
        await _http.syncClock();
        if (!_isCurrent(generation)) return;
        clockData = await _http.getClock();
        if (!_isCurrent(generation)) return;
        _applyClockPayload(clockData);
      }

      final snapshotData = await _http.getSnapshot();
      if (!_isCurrent(generation)) return;
      final snapshot = ControllerSnapshot.fromJson(snapshotData);
      automationRules = snapshot.rules;
      deviceRuntime = snapshot.runtime;
      snapshotRevision = snapshot.revision;
      await _snapshotCache.save(snapshotData);

      stopwatch.stop();
      lastResponseMs = stopwatch.elapsedMilliseconds;
      connected = true;
      consecutiveFailures = 0;
      lastUpdated = DateTime.now();
      status = _text(
        'ข้อมูลจริงล่าสุด ${_formatTime(lastUpdated!)}',
        'Live data updated ${_formatTime(lastUpdated!)}',
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      lastResponseMs = null;
      consecutiveFailures++;
      // A single endpoint timeout is degradation, not proof that the Wi-Fi
      // controller disappeared. Require three consecutive failed poll cycles.
      if (consecutiveFailures >= 3) {
        connected = false;
        status = _text(
          'ขาดการเชื่อมต่อ กำลังลองใหม่ ($consecutiveFailures)',
          'Connection lost. Retrying ($consecutiveFailures)',
        );
      } else {
        status = _text(
          'สัญญาณไม่เสถียร กำลังตรวจสอบ ($consecutiveFailures/3)',
          'Connection degraded; checking ($consecutiveFailures/3)',
        );
      }
      _addLog('POLL ERROR $error');
    } finally {
      if (_isCurrent(generation)) {
        _requestInProgress = false;
        _notify();
      }
    }
  }

  Future<void> refreshNow() async {
    if (!_pollingEnabled) {
      _pollingEnabled = true;
      _startPolling();
    }
    await refreshState();
  }

  Future<void> refreshClock() async {
    if (!connected) return;
    try {
      final data = await _http.getClock();
      _applyClockPayload(data);
      _notify();
    } catch (error) {
      _addLog('CLOCK ERROR $error');
    }
  }

  Future<bool> syncClock() async {
    if (!connected) return false;
    try {
      final data = await _http.syncClock();
      _applyClockPayload(data);
      _clockRecoveryAttempted = true;
      status = clock.valid
          ? _text('ตั้งเวลา DS3231 สำเร็จ', 'DS3231 time synchronized')
          : _text('DS3231 ยังไม่ยืนยันเวลา', 'DS3231 time is still invalid');
      _addLog('CLOCK SYNC valid=${clock.valid} quality=${clock.quality}');
      _notify();
      return clock.valid;
    } catch (error) {
      status = _text('ตั้งเวลา DS3231 ไม่สำเร็จ: $error', 'RTC sync failed: $error');
      _addLog('CLOCK SYNC ERROR $error');
      _notify();
      return false;
    }
  }

  Future<void> refreshSnapshot() async {
    if (!connected) return;
    try {
      final data = await _http.getSnapshot();
      final snapshot = ControllerSnapshot.fromJson(data);
      automationRules = snapshot.rules;
      deviceRuntime = snapshot.runtime;
      snapshotRevision = snapshot.revision;
      await _snapshotCache.save(data);
      _notify();
    } catch (error) {
      _addLog('SNAPSHOT ERROR $error');
    }
  }

  Future<Map<String, dynamic>?> requestDevice(
    String deviceId,
    bool on, {
    bool force = false,
    int overrideSeconds = 300,
  }) async {
    if (!connected) return null;
    try {
      final result = await _http.requestDevice(
        deviceId: deviceId,
        on: on,
        force: force,
        overrideSeconds: overrideSeconds,
      );
      await refreshSnapshot();
      return result;
    } catch (error) {
      status = 'ส่งคำขออุปกรณ์ไม่สำเร็จ: $error';
      _notify();
      return null;
    }
  }

  Future<bool> saveDeviceProfile(Map<String, dynamic> profile) async {
    if (!connected) return false;
    try {
      await _http.saveDeviceProfile(profile);
      await refreshSnapshot();
      return true;
    } catch (error) {
      status = 'บันทึกแผนอุปกรณ์ไม่สำเร็จ: $error';
      _notify();
      return false;
    }
  }

  Future<bool> deleteDeviceProfile(String deviceId) async {
    if (!connected) return false;
    try {
      await _http.deleteDeviceProfile(deviceId);
      await refreshSnapshot();
      return true;
    } catch (error) {
      status = 'ลบอุปกรณ์ไม่สำเร็จ: $error';
      _notify();
      return false;
    }
  }

  Future<void> refreshAutomationRules() async {
    if (!connected) return;
    try {
      final data = await _http.getAutomations();
      final raw = data['rules'] as List? ?? const [];
      automationRules = raw
          .whereType<Map>()
          .map((e) => AutomationRule.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _notify();
    } catch (error) {
      _addLog('AUTOMATION LOAD ERROR $error');
    }
  }

  Future<bool> saveAutomationRule(AutomationRule rule) async {
    if (!connected) {
      status = _text(
        'ต้องเชื่อมต่อกล่องควบคุมก่อนบันทึก',
        'Connect the control box before saving',
      );
      _notify();
      return false;
    }
    try {
      await _http.saveAutomation(rule.toJson());
      await refreshAutomationRules();
      return true;
    } catch (error) {
      status = 'บันทึกเงื่อนไขไม่สำเร็จ: $error';
      _notify();
      return false;
    }
  }

  Future<bool> deleteAutomationRule(String id) async {
    if (!connected) return false;
    try {
      await _http.deleteAutomation(id);
      await refreshAutomationRules();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> testAutomationRule(String id) async {
    if (!connected || emergencyLatched) return false;
    try {
      await _http.testAutomation(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> emergencyStop() async {
    if (!connected || _requestInProgress) {
      status = connected
          ? _text(
              'ระบบกำลังรับส่งข้อมูล กรุณาลองอีกครั้ง',
              'A request is in progress. Please try again',
            )
          : _text(
              'ยังไม่ได้เชื่อมต่อกล่องควบคุม',
              'Control box is not connected',
            );
      _notify();
      return false;
    }

    final int generation = _connectionGeneration;
    _requestInProgress = true;
    status = _text(
      'กำลังปิดอุปกรณ์ทุกช่อง...',
      'Turning off every output channel...',
    );
    for (var i = 0; i < relays.length; i++) {
      relays[i] = relays[i].copyWith(on: false, overrideActive: true);
    }
    _notify();

    try {
      final response = await _http.emergencyStop();
      if (!_isCurrent(generation)) return false;
      emergencyLatched = response['emergencyLatched'] == true;
      connected = true;
      consecutiveFailures = 0;
      status = _text(
        'ปิดฉุกเฉินแล้ว ระบบอัตโนมัติถูกล็อกไม่ให้เปิดรีเลย์',
        'Emergency stop is active. Automation cannot turn relays back on.',
      );
      _addLog('POST /api/emergency-stop');
      return true;
    } catch (error) {
      if (!_isCurrent(generation)) return false;
      connected = false;
      consecutiveFailures++;
      status = _text(
        'ปิดฉุกเฉินไม่สำเร็จ: $error',
        'Emergency stop failed: $error',
      );
      _addLog('POST /api/emergency-stop ERROR $error');
      return false;
    } finally {
      if (_isCurrent(generation)) {
        _requestInProgress = false;
        _notify();
      }
    }
  }

  Future<bool> releaseEmergencyStop() async {
    if (!connected || _requestInProgress) return false;
    final int generation = _connectionGeneration;
    _requestInProgress = true;
    _notify();
    try {
      final response = await _http.releaseEmergencyStop();
      if (!_isCurrent(generation)) return false;
      emergencyLatched = response['emergencyLatched'] == true;
      status = _text('ยกเลิกล็อกฉุกเฉินแล้ว', 'Emergency lock released');
      return true;
    } catch (error) {
      if (!_isCurrent(generation)) return false;
      status = _text(
        'ยกเลิกล็อกฉุกเฉินไม่สำเร็จ: $error',
        'Unable to release emergency lock: $error',
      );
      return false;
    } finally {
      if (_isCurrent(generation)) {
        _requestInProgress = false;
        _notify();
      }
    }
  }

  Future<bool> setRelay(int channel, bool on) async {
    if (channel < 0 || channel >= relays.length) {
      status = _text(
        'ช่องรีเลย์ไม่ถูกต้อง: $channel',
        'Invalid relay channel: $channel',
      );
      _notify();
      return false;
    }

    if (!connected || _requestInProgress) {
      status = connected
          ? _text(
              'ระบบกำลังรับส่งข้อมูล กรุณาลองอีกครั้ง',
              'A request is in progress. Please try again',
            )
          : _text(
              'ยังไม่ได้เชื่อมต่อกล่องควบคุม',
              'Control box is not connected',
            );
      _notify();
      return false;
    }

    final int generation = _connectionGeneration;
    final previous = relays[channel];
    relays[channel] = previous.copyWith(on: on);
    _requestInProgress = true;
    status = _text(
      'กำลังสั่ง CH ${channel + 1}...',
      'Sending command to CH ${channel + 1}...',
    );
    _notify();

    var commandSucceeded = false;
    try {
      final response = await _http.setRelay(
        channel: channel,
        on: on,
        overrideSeconds: 300,
      );
      if (!_isCurrent(generation)) return false;

      relays[channel] = relays[channel].copyWith(
        on: response['on'] == true,
        overrideActive: response['overrideActive'] != false,
      );
      connected = true;
      consecutiveFailures = 0;
      status = _text(
        'สั่ง ${relays[channel].name} สำเร็จ',
        '${relays[channel].name} updated successfully',
      );
      commandSucceeded = true;
      _addLog('POST /api/relay CH=$channel ON=${response['on']}');
    } catch (error) {
      if (!_isCurrent(generation)) return false;
      relays[channel] = previous;
      connected = false;
      consecutiveFailures++;
      status = _text(
        'สั่งรีเลย์ไม่สำเร็จ: $error',
        'Relay command failed: $error',
      );
      _addLog('POST /api/relay ERROR $error');
    } finally {
      if (_isCurrent(generation)) {
        _requestInProgress = false;
        _notify();
      }
    }

    if (_pollingEnabled && _isCurrent(generation)) {
      await refreshState();
    }
    return commandSucceeded;
  }

  String _text(String thai, String english) {
    return languageCode == 'th' ? thai : english;
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _connectionGeneration;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    if (!_pollingEnabled) {
      return;
    }

    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(refreshState()));
  }

  void _applyDevice(Map<String, dynamic> data) {
    identity = ControllerIdentity.fromJson(data);
    accessorySchemaVersion = identity.accessorySchemaVersion;
    deviceId = _textOrNull(data['deviceId']);
    firmwareVersion = _textOrNull(data['firmwareVersion']);
    protocolVersion = _toInt(data['protocolVersion']);
    apiVersion = _toInt(data['apiVersion']);
    connectionMode = _textOrNull(data['mode']);
    accessPointSsid = _textOrNull(data['ssid']);
    accessPointIp = _textOrNull(data['ip']);
    final reportedRelayCount = _toInt(data['relayCount']);
    relayCount = hardwareRelayCount;
    if (reportedRelayCount != null &&
        reportedRelayCount != hardwareRelayCount) {
      _addLog(
        'RELAY PROFILE MISMATCH reported=$reportedRelayCount expected=$hardwareRelayCount',
      );
    }
    wifiClientCount = _toInt(data['wifiClientCount']) ?? wifiClientCount;
    wifiRssi = _toInt(data['rssi']) ?? wifiRssi;
    freeHeap = _toInt(data['freeHeap']) ?? freeHeap;
    hardwareProfile = _textOrNull(data['hardwareProfile']) ?? hardwareProfile;
    accessorySchemaVersion =
        _toInt(data['accessorySchemaVersion']) ?? accessorySchemaVersion;
    identity = ControllerIdentity(
      controllerId: deviceId ?? identity.controllerId,
      displayName: identity.displayName,
      hardwareProfile: hardwareProfile,
      relayCount: relayCount ?? hardwareRelayCount,
      firmwareVersion: firmwareVersion ?? identity.firmwareVersion,
      accessorySchemaVersion: accessorySchemaVersion,
    );
    _applyAccessories(data['accessories']);

    final count = relayCount;
    if (count != null && count >= 0) {
      _resizeRelays(count);
    }
  }

  void _applyState(Map<String, dynamic> data) {
    deviceId = _textOrNull(data['deviceId']) ?? deviceId;
    firmwareVersion = _textOrNull(data['firmwareVersion']) ?? firmwareVersion;
    protocolVersion = _toInt(data['protocolVersion']) ?? protocolVersion;
    apiVersion = _toInt(data['apiVersion']) ?? apiVersion;
    uptimeMs = _toInt(data['uptimeMs']);
    emergencyLatched = data['emergencyLatched'] == true;
    wifiClientCount = _toInt(data['wifiClientCount']);
    wifiRssi = _toInt(data['rssi']) ?? wifiRssi;
    freeHeap = _toInt(data['freeHeap']) ?? freeHeap;
    hardwareProfile = _textOrNull(data['hardwareProfile']) ?? hardwareProfile;
    accessorySchemaVersion =
        _toInt(data['accessorySchemaVersion']) ?? accessorySchemaVersion;
    identity = ControllerIdentity(
      controllerId: deviceId ?? identity.controllerId,
      displayName: identity.displayName,
      hardwareProfile: hardwareProfile,
      relayCount: relayCount ?? hardwareRelayCount,
      firmwareVersion: firmwareVersion ?? identity.firmwareVersion,
      accessorySchemaVersion: accessorySchemaVersion,
    );
    _applyAccessories(data['accessories']);

    final metrics = data['metrics'];
    if (metrics is Map) {
      soilMoisture = _toDouble(metrics['soilMoisture']);
      temperature = _toDouble(metrics['temperature']);
      humidity = _toDouble(metrics['humidity']);
    }

    _applyRelayList(data['relays']);
  }

  void _applyAccessories(dynamic raw) {
    if (raw is! List) {
      return;
    }
    accessories = raw
        .whereType<Map>()
        .map(AccessoryManifest.fromJson)
        .where((item) => item.portId.isNotEmpty)
        .toList(growable: false);
  }

  void _resizeRelays(int count) {
    if (count < relays.length) {
      relays.removeRange(count, relays.length);
      return;
    }

    while (relays.length < count) {
      final channel = relays.length;
      relays.add(
        RelayViewState(
          channel: channel,
          name: 'Relay ${channel + 1}',
          on: false,
        ),
      );
    }
  }

  void _applyRelayList(dynamic raw) {
    if (raw is! List) {
      return;
    }

    for (final item in raw) {
      if (item is! Map) {
        continue;
      }

      final channel = _toInt(item['channel']);
      if (channel == null || channel < 0) {
        continue;
      }

      if (relays.length <= channel) {
        _resizeRelays(channel + 1);
      }

      relays[channel] = relays[channel].copyWith(
        name: _textOrNull(item['name']),
        on: item['on'] == true,
        overrideActive: item['overrideActive'] == true,
      );
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now();
    final formatted = '${_formatTime(timestamp)}  $message';
    logs.insert(0, formatted);
    _logEntries.insert(
      0,
      ControllerLogEntry(
        id: '${timestamp.microsecondsSinceEpoch}-${_nextLogSequence++}',
        message: formatted,
        timestamp: timestamp,
      ),
    );
    if (logs.length > 100) {
      logs.removeRange(100, logs.length);
    }
    if (_logEntries.length > 100) {
      _logEntries.removeRange(100, _logEntries.length);
    }
  }

  void clearLogs() {
    logs.clear();
    _logEntries.clear();
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  static String _formatTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:'
        '${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }

  static String? _textOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _connectionGeneration++;
    _pollingEnabled = false;
    _pollTimer?.cancel();
    _http.close();
    super.dispose();
  }
}
