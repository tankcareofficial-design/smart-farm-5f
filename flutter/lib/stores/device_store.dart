import 'dart:async';

import 'package:flutter/foundation.dart';

import '../controllers/smart_farm_controller.dart';
import '../models/output_device.dart';
import '../services/device_repository.dart';

class _DeviceCommandState {
  bool? latestDesiredState;
  bool running = false;
  Future<bool>? activeFuture;
}

class DeviceStore extends ChangeNotifier {
  factory DeviceStore({
    DeviceRepository? repository,
    SmartFarmController? controller,
  }) {
    return DeviceStore._(repository ?? DeviceRepository(), controller);
  }

  DeviceStore._(this._repository, this._controller) {
    _controller?.addListener(_syncFromController);
    unawaited(initialize());
  }

  final DeviceRepository _repository;
  final SmartFarmController? _controller;
  final List<OutputDevice> _outputs = <OutputDevice>[];
  final Set<String> _pendingDeviceIds = <String>{};
  final Map<String, _DeviceCommandState> _commandStates =
      <String, _DeviceCommandState>{};
  bool _initialized = false;
  String? _lastCommandError;
  bool _wasControllerConnected = false;
  bool _profileSyncInProgress = false;
  bool _controllerRestoreInProgress = false;

  List<OutputDevice> get outputs => List<OutputDevice>.unmodifiable(_outputs);
  bool get initialized => _initialized;
  bool get controllerConnected => _controller?.connected ?? false;
  bool get emergencyLatched => _controller?.emergencyLatched ?? false;
  String? get lastCommandError => _lastCommandError;
  bool get controllerClockValid => _controller?.clock.valid ?? false;
  String get controllerClockSource => _controller?.clock.source ?? 'none';
  DateTime? get estimatedControllerDateTime =>
      _controller?.estimatedControllerDateTime;

  int get activeOutputCount =>
      _outputs.where((OutputDevice device) => device.isOn).length;

  bool isCommandPending(String deviceId) =>
      _pendingDeviceIds.contains(deviceId);

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final List<OutputDevice>? saved = await _repository.load();
    _outputs
      ..clear()
      ..addAll(saved ?? const <OutputDevice>[]);
    _sortByChannel();
    _initialized = true;
    notifyListeners();

    if (saved == null) {
      await _persist();
    }
    _syncFromController();
  }

  bool isChannelUsed(int channel, {String? excludingDeviceId}) {
    return _outputs.any(
      (OutputDevice device) =>
          device.channel == channel && device.id != excludingDeviceId,
    );
  }

  Future<bool> addOutput(OutputDevice device) async {
    if (isChannelUsed(device.channel)) {
      throw ArgumentError('ช่องรีเลย์นี้ถูกใช้งานแล้ว');
    }
    if (!await _syncProfile(device)) return false;
    _outputs.add(device);
    _sortByChannel();
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> updateOutput(OutputDevice updatedDevice) async {
    final int index = _outputs.indexWhere(
      (OutputDevice device) => device.id == updatedDevice.id,
    );
    if (index == -1) {
      return false;
    }
    if (isChannelUsed(
      updatedDevice.channel,
      excludingDeviceId: updatedDevice.id,
    )) {
      throw ArgumentError('ช่องรีเลย์นี้ถูกใช้งานแล้ว');
    }
    if (!await _syncProfile(updatedDevice)) return false;
    _outputs[index] = updatedDevice;
    _sortByChannel();
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> setOutputState(String id, bool requestedOn) {
    final int index = _outputs.indexWhere((device) => device.id == id);
    if (index == -1 || !_outputs[index].enabled) {
      return Future<bool>.value(false);
    }
    final controller = _controller;
    if (controller == null || !controller.connected) {
      _lastCommandError = 'ยังไม่ได้เชื่อมต่อกล่องควบคุม';
      notifyListeners();
      return Future<bool>.value(false);
    }

    final state = _commandStates.putIfAbsent(id, _DeviceCommandState.new);
    state.latestDesiredState = requestedOn;
    _outputs[index] = _outputs[index].copyWith(
      requestedOn: requestedOn,
      runtimeState: requestedOn ? 'requested' : 'off',
      waitingReason: requestedOn ? 'กำลังตรวจสอบเวลาและเงื่อนไข' : '',
    );
    notifyListeners();

    if (state.running) {
      return state.activeFuture!;
    }

    state.running = true;
    final future = _drainOutputCommands(id, state);
    state.activeFuture = future;
    return future;
  }

  Future<bool> _drainOutputCommands(
    String id,
    _DeviceCommandState state,
  ) async {
    var lastResult = true;
    _pendingDeviceIds.add(id);
    notifyListeners();
    try {
      while (true) {
        final requestedOn = state.latestDesiredState;
        if (requestedOn == null) {
          state.running = false;
          state.activeFuture = null;
          _commandStates.remove(id);
          return lastResult;
        }
        state.latestDesiredState = null;
        lastResult = await _sendOutputState(id, requestedOn, state);
      }
    } finally {
      if (identical(_commandStates[id], state)) {
        state.running = false;
        state.activeFuture = null;
        _commandStates.remove(id);
      }
      _pendingDeviceIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> _sendOutputState(
    String id,
    bool requestedOn,
    _DeviceCommandState commandState,
  ) async {
    final int index = _outputs.indexWhere((device) => device.id == id);
    if (index == -1) {
      return false;
    }
    final controller = _controller;
    if (controller == null || !controller.connected) {
      return false;
    }

    final previous = _outputs[index];
    _lastCommandError = null;
    try {
      final currentDevice = previous;
      if (currentDevice.mode == OutputControlMode.manual) {
        final ok = await controller.setRelay(
          currentDevice.channel - 1,
          requestedOn,
        );
        final currentIndex = _outputs.indexWhere((device) => device.id == id);
        if (currentIndex == -1) {
          return false;
        }
        if (!ok) {
          if (commandState.latestDesiredState == null) {
            _outputs[currentIndex] = previous;
          }
          _lastCommandError = controller.status;
          return false;
        }
        _outputs[currentIndex] = _outputs[currentIndex].copyWith(
          isOn: requestedOn,
          requestedOn: commandState.latestDesiredState ?? requestedOn,
          runtimeState: requestedOn ? 'running' : 'off',
          waitingReason: '',
          remainingSeconds: 0,
        );
      } else {
        final profileReady = await _syncProfile(currentDevice);
        if (!profileReady) {
          final currentIndex = _outputs.indexWhere((device) => device.id == id);
          if (currentIndex >= 0 && commandState.latestDesiredState == null) {
            _outputs[currentIndex] = previous;
          }
          _lastCommandError ??= controller.status;
          return false;
        }
        final result = await controller.requestDevice(
          currentDevice.id,
          requestedOn,
        );
        final currentIndex = _outputs.indexWhere((device) => device.id == id);
        if (currentIndex == -1) {
          return false;
        }
        if (result == null) {
          if (commandState.latestDesiredState == null) {
            _outputs[currentIndex] = previous;
          }
          _lastCommandError = controller.status;
          return false;
        }
        final state = result['runtimeState']?.toString() ??
            (requestedOn ? 'waiting' : 'off');
        _outputs[currentIndex] = _outputs[currentIndex].copyWith(
          requestedOn: commandState.latestDesiredState ?? requestedOn,
          runtimeState: state,
          waitingReason: result['reason']?.toString() ??
              result['waitingReason']?.toString() ??
              '',
          remainingSeconds: (result['remainingSeconds'] as num?)?.toInt() ?? 0,
        );
      }
      await _persist();
      return true;
    } catch (error) {
      final currentIndex = _outputs.indexWhere((device) => device.id == id);
      if (currentIndex >= 0 && commandState.latestDesiredState == null) {
        _outputs[currentIndex] = previous;
      }
      _lastCommandError = 'ส่งคำขออุปกรณ์ไม่สำเร็จ: $error';
      await _persist();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _syncProfile(OutputDevice device) async {
    final controller = _controller;
    if (controller == null || !controller.connected) {
      return false;
    }
    final startMinutes = device.schedule.hour * 60 + device.schedule.minute;
    final endMinutes = device.schedule.endHour * 60 + device.schedule.endMinute;
    final rawDifference = endMinutes - startMinutes;
    final durationMinutes = switch (rawDifference) {
      > 0 => rawDifference,
      < 0 => rawDifference + 24 * 60,
      _ => 0,
    };
    if (device.schedule.enabled && durationMinutes == 0) {
      _lastCommandError =
          'เวลาเริ่มและเวลาสิ้นสุดต้องไม่เท่ากัน กรุณาแก้ไขแผนอุปกรณ์';
      notifyListeners();
      return false;
    }
    final conditions = <Map<String, dynamic>>[];
    if (device.condition.enabled) {
      conditions.add(<String, dynamic>{
        'type': 'sensor',
        'sensorId': device.condition.sensorId,
        'metric': device.condition.metric,
        'operator': device.condition.operator,
        'value': device.condition.value,
        'valueHigh': device.condition.stopValue,
      });
    }
    final profile = <String, dynamic>{
      'id': 'device-${device.id}',
      'deviceId': device.id,
      'name': device.name,
      'deviceType': device.type.name,
      'controlMode': device.mode.name,
      'enabled': device.enabled,
      'priority': 300,
      'conditionLogic': 'and',
      'trigger': <String, dynamic>{
        'schedule': <String, dynamic>{
          'enabled': device.schedule.enabled,
          'hour': device.schedule.hour,
          'minute': device.schedule.minute,
          'endHour': device.schedule.endHour,
          'endMinute': device.schedule.endMinute,
          'mode': device.schedule.enabled ? 'window' : 'always',
          'daysOfWeek': <int>[
            for (var day = 1; day <= 7; day++)
              if ((device.schedule.daysMask & (1 << (day - 1))) != 0) day,
          ],
        },
      },
      'conditions': conditions,
      'actions': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'relay_pulse',
          'relayChannel': device.channel - 1,
          'durationSeconds': device.schedule.enabled
              ? durationMinutes * 60
              : 120,
        },
      ],
      'safety': <String, dynamic>{
        'maxRuntimeSeconds': device.schedule.enabled
            ? durationMinutes * 60
            : 1800,
        'cooldownSeconds': 60,
      },
    };
    final ok = await controller.saveDeviceProfile(profile);
    if (!ok) {
      _lastCommandError = controller.status;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<void> _syncAllProfiles() async {
    if (_profileSyncInProgress || !_initialized) {
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.connected) {
      return;
    }
    _profileSyncInProgress = true;
    try {
      for (final device in List<OutputDevice>.from(_outputs)) {
        if (!controller.connected) {
          break;
        }
        await _syncProfile(device);
      }
    } finally {
      _profileSyncInProgress = false;
    }
  }

  Future<void> _restoreProfilesFromController() async {
    if (_controllerRestoreInProgress || !_initialized) {
      return;
    }
    final controller = _controller;
    final controllerId = controller?.deviceId;
    if (controller == null || !controller.connected || controllerId == null) {
      return;
    }
    _controllerRestoreInProgress = true;
    try {
      final savedControllerId = await _repository.loadControllerId();
      final remoteRules = controller.automationRules;
      final controllerChanged = savedControllerId != null && savedControllerId != controllerId;
      if (remoteRules.isNotEmpty && (_outputs.isEmpty || controllerChanged)) {
        final restored = remoteRules.map((rule) {
          var daysMask = 0;
          for (final day in rule.daysOfWeek) {
            if (day >= 1 && day <= 7) {
              daysMask |= 1 << (day - 1);
            }
          }
          final raw = rule.rawMetadata;
          final typeName = raw['deviceType']?.toString() ?? 'custom';
          final modeName = raw['controlMode']?.toString() ??
              (rule.conditions.isNotEmpty ? 'automatic' : 'schedule');
          final type = OutputDeviceType.values.firstWhere(
            (value) => value.name == typeName,
            orElse: () => OutputDeviceType.custom,
          );
          final mode = OutputControlMode.values.firstWhere(
            (value) => value.name == modeName,
            orElse: () => rule.conditions.isNotEmpty
                ? OutputControlMode.automatic
                : OutputControlMode.schedule,
          );
          final condition = rule.conditions.isEmpty ? null : rule.conditions.first;
          return OutputDevice(
            id: rule.deviceId.isEmpty ? rule.id.replaceFirst('device-', '') : rule.deviceId,
            name: rule.name,
            type: type,
            channel: rule.relayChannel + 1,
            isOn: rule.running,
            enabled: rule.enabled,
            mode: mode,
            schedule: DeviceScheduleConfig(
              enabled: mode == OutputControlMode.schedule,
              hour: rule.hour,
              minute: rule.minute,
              endHour: rule.endHour ?? rule.hour,
              endMinute: rule.endMinute ?? rule.minute,
              daysMask: daysMask == 0 ? 0x7F : daysMask,
            ),
            condition: DeviceConditionConfig(
              enabled: mode == OutputControlMode.automatic && condition != null,
              sensorId: condition?.sensorId ?? '',
              metric: condition?.metric ?? '',
              operator: condition?.operator ?? '<',
              value: condition?.value ?? 40,
              stopValue: condition?.valueHigh ?? ((condition?.value ?? 40) + 5),
            ),
          );
        }).toList();
        _outputs
          ..clear()
          ..addAll(restored);
        _sortByChannel();
        await _persist();
        notifyListeners();
      } else if (remoteRules.isEmpty && _outputs.isNotEmpty && !controllerChanged) {
        await _syncAllProfiles();
      }
      await _repository.saveControllerId(controllerId);
    } finally {
      _controllerRestoreInProgress = false;
    }
  }

  void clearCommandError() {
    if (_lastCommandError == null) {
      return;
    }
    _lastCommandError = null;
    notifyListeners();
  }

  void _syncFromController() {
    final controller = _controller;
    if (controller == null || !_initialized) {
      return;
    }

    final justConnected = controller.connected && !_wasControllerConnected;
    _wasControllerConnected = controller.connected;
    if (justConnected) {
      unawaited(_restoreProfilesFromController());
    }

    var changed = false;
    for (var i = 0; i < _outputs.length; i++) {
      if (_pendingDeviceIds.contains(_outputs[i].id)) continue;
      final relayIndex = _outputs[i].channel - 1;
      if (relayIndex >= 0 && relayIndex < controller.relays.length) {
        final actual = controller.relays[relayIndex].on;
        if (_outputs[i].isOn != actual) {
          _outputs[i] = _outputs[i].copyWith(isOn: actual);
          changed = true;
        }
      }
    }
    if (changed) {
      notifyListeners();
      unawaited(_persist());
    } else {
      notifyListeners();
    }
  }

  Future<bool> emergencyStopAllOutputs() async {
    final controller = _controller;
    if (controller == null || !controller.connected) {
      _lastCommandError = 'ยังไม่ได้เชื่อมต่อกล่องควบคุม';
      notifyListeners();
      return false;
    }

    _lastCommandError = null;
    for (var index = 0; index < _outputs.length; index++) {
      _outputs[index] = _outputs[index].copyWith(isOn: false);
    }
    notifyListeners();

    final success = await controller.emergencyStop();
    if (!success) {
      _lastCommandError = controller.status;
      _syncFromController();
      return false;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> releaseEmergencyStop() async {
    final controller = _controller;
    if (controller == null || !controller.connected) {
      _lastCommandError = 'ยังไม่ได้เชื่อมต่อกล่องควบคุม';
      notifyListeners();
      return false;
    }
    final success = await controller.releaseEmergencyStop();
    if (!success) {
      _lastCommandError = controller.status;
    }
    notifyListeners();
    return success;
  }

  @Deprecated('Use emergencyStopAllOutputs so the command reaches ESP32.')
  void turnOffAllOutputs() {
    unawaited(emergencyStopAllOutputs());
  }

  Future<bool> removeOutput(String id) async {
    final controller = _controller;
    if (controller == null || !controller.connected) {
      _lastCommandError = 'ยังไม่ได้เชื่อมต่อกล่องควบคุม';
      notifyListeners();
      return false;
    }
    final removed = await controller.deleteDeviceProfile(id);
    if (!removed) {
      _lastCommandError = controller.status;
      notifyListeners();
      return false;
    }
    _outputs.removeWhere((OutputDevice device) => device.id == id);
    _pendingDeviceIds.remove(id);
    await _persist();
    notifyListeners();
    return true;
  }

  void _commit() {
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> _persist() => _repository.save(_outputs);

  void _sortByChannel() {
    _outputs.sort(
      (OutputDevice a, OutputDevice b) => a.channel.compareTo(b.channel),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncFromController);
    super.dispose();
  }
}
